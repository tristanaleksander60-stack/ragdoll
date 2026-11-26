#!/usr/bin/env python3
"""Lab master plan (owner, 26 Nov 2026: "Det her map er 1/10, sørg for det bliver 10/10").

ONE source for the big owner map's layout. It writes:
  - ReplicatedStorage/ReplicatedStorage/Shared/OwnerMapPlan.luau (the data LabOwnerMap builds from)
  - art/store/lab10/masterplan.png (the top-view drawing for the owner and for checking)
and it lints the plan (things inside their rooms, no overlaps, nothing on roads, every room reachable).

Lab space: studs, x east, z south (north = -z). Map: x -505..445, z -386..434 (LabOwnerMap CENTER (-30,24), 950 x 820).
Run: python3 tools/masterplan.py
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOUNDS = (-505, -386, 445, 434)

# ---------- ROOMS: walled by tree belts, entered only through their openings ----------
# (id, name, x0, z0, x1, z1, entrances [(x, z)] on the room edge, courtyard (x, z))
ROOMS = [
    ("AnimalCove",  "Animal Cove",   -455, -360, -150, -170, [(-305, -170), (-150, -325)], (-305, -212)),
    ("SplashZone",  "Splash Zone",     90, -360,  395, -170, [(245, -170), (90, -325)],    (245, -212)),
    ("CrashYard",   "Crash Yard",    -455, -130, -150,   20, [(-305, -130), (-305, 20)],  (-290, -30)),
    ("CarPark",     "Car Park",      -455,   60, -150,  240, [(-305, 60), (-305, 240)],   (-305, 105)),
    ("MachineHall", "Machine Hall",    90, -130,  395,   20, [(245, -130), (245, 20)],    (245, -20)),
    ("FunFair",     "Fun Fair",        90,   60,  395,  240, [(245, 60), (245, 240)],     (245, 100)),
    ("LaunchField", "Launch Field",  -455,  280, -150,  400, [(-200, 280)],               (-200, 318)),
    ("DangerZone",  "Danger Zone",     90,  280,  395,  400, [(245, 280)],                (245, 318)),
    ("PicnicPark",  "Picnic Park",   -130,  150,   70,  400, [],                          None),
    ("GardensN",    "Spawn Gardens", -130, -270,   70, -170, [],                          None),
    ("LawnsMid",    "Lawns",         -130, -130,   70,  -60, [],                          None),
]
OPEN_ROOMS = {"PicnicPark", "GardensN", "LawnsMid"}  # framed by hedges, not tree belts (the roads cross them)

# ---------- PLAZAS ----------
PLAZAS = [
    # (id, kind, x, z, a, b)  kind "rect": a=w, b=d ; kind "circle": a=radius
    ("SpawnPlaza",  "rect",   -30, -325, 150, 90),   # raised 4 studs: spawn, 4 leaderboards, MAPS board
    ("Fountain",    "circle", -30, -150, 30, 0),
    ("TowerSquare", "circle", -30,   40, 100, 0),
    ("SouthCross",  "circle", -30,  260, 22, 0),
    ("Station",     "rect",   -30,  405, 90, 16),    # train platform at the railway
]

# ---------- ROADS (polylines, width) ----------
ROADS = [
    ("Boulevard",   36, [(-30, -280), (-30, -60)]),            # plaza stair -> tower square, through the fountain
    ("NorthCross",  26, [(-472, -150), (412, -150)]),
    ("RoadW",       26, [(-130, 40), (-472, 40)]),
    ("RoadE",       26, [(70, 40), (412, 40)]),
    ("RoadS",       26, [(-30, 140), (-30, 397)]),
    ("SouthCross",  26, [(-472, 260), (412, 260)]),
    ("AvenueW",     16, [(-472, -150), (-472, 260)]),          # the outer loop (the cyclist rides it)
    ("AvenueE",     16, [(412, -150), (412, 260)]),
    ("PlazaWest",   12, [(-105, -325), (-150, -325)]),         # plaza side exits into Animal Cove / Splash Zone
    ("PlazaEast",   12, [(45, -325), (90, -325)]),
    # spurs into every room entrance (from the nearest road to the room edge)
    ("SpurCoveS",     18, [(-305, -150), (-305, -170)]),
    ("SpurSplashS",   18, [(245, -150), (245, -170)]),
    ("SpurCrashN",    18, [(-305, -150), (-305, -130)]),
    ("SpurCrashS",    18, [(-305, 40), (-305, 20)]),
    ("SpurParkN",     18, [(-305, 40), (-305, 60)]),
    ("SpurParkS",     18, [(-305, 260), (-305, 240)]),
    ("SpurHallN",     18, [(245, -150), (245, -130)]),
    ("SpurHallS",     18, [(245, 40), (245, 20)]),
    ("SpurFairN",     18, [(245, 40), (245, 60)]),
    ("SpurFairS",     18, [(245, 260), (245, 240)]),
    ("SpurLaunch",    18, [(-200, 260), (-200, 280)]),
    ("SpurDanger",    18, [(245, 260), (245, 280)]),
]

# ---------- ITEMS: every attraction, with its footprint (keep this floor free for it) ----------
# (id, room, x, z, w, d, face, what)   face = the side its front looks to (N/S/E/W)
ITEMS = [
    # Spawn plaza
    ("Spawn",          "SpawnPlaza", -30, -300, 16, 16, "S", "spawn point, facing down the boulevard to the tower"),
    ("Leaderboards",   "SpawnPlaza", -30, -360, 110, 6, "S", "the 4 leaderboards in a row (top 20, scrolling); their SCREENS face SOUTH toward the spawn and the stair (readable from the spawn)"),
    ("MapsBoard",      "SpawnPlaza",  25, -320, 6, 22, "W", "the MAPS board"),
    # Animal Cove
    ("CaveBear",       "AnimalCove", -385, -300, 90, 70, "S", "the rock cave with the bear and its stone-ringed yard"),
    ("Aquarium",       "AnimalCove", -230, -300, 70, 40, "S", "the glass aquarium with the shark (NOT near the spawn)"),
    ("CrocPond",       "AnimalCove", -400, -212, 60, 40, "E", "the fenced crocodile pond + the speaker wall on its west side"),
    ("TRexPen",        "AnimalCove", -220, -222, 100, 46, "W", "the walled T-rex pen with its big wooden gate"),
    # Splash Zone
    ("BigPool",        "SplashZone",  175, -300, 80, 50, "S", "the open pool (the whale)"),
    ("LoungePool",     "SplashZone",  330, -300, 50, 34, "S", "the small pool with sun loungers"),
    ("SpiderPen",      "SplashZone",  330, -220, 52, 40, "W", "the fenced dirt pen with the spider web"),
    ("SnackKiosk",     "SplashZone",  160, -215, 24, 18, "E", "snack kiosk + 2 portable toilets"),
    # Crash Yard
    ("CarBays",        "CrashYard",  -370,  -95, 72, 28, "S", "painted bays: tank, monster truck, blue car"),
    ("BrickWall",      "CrashYard",  -432,  -50, 8, 100, "E", "the long red brick crash wall (barrels at its ends, the old sedan beside it)"),
    ("LaunchPads",     "CrashYard",  -330,  -28, 14, 50, "W", "3 launch pads aimed at the brick wall"),
    ("BoxingRing",     "CrashYard",  -215,  -85, 32, 32, "S", "the boxing ring on its pad"),
    ("WreckingBall",   "CrashYard",  -215,  -25, 28, 28, "W", "the wrecking ball gantry"),
    # Car Park
    ("CarPark",        "CarPark",    -380,  130, 92, 46, "S", "the car park with 6+ parked cars in bays"),
    ("Garage",         "CarPark",    -410,  200, 50, 36, "E", "the garage, doors facing the room; a rail spur runs from the west railway into its back"),
    ("TrainingYard",   "CarPark",    -220,  165, 70, 50, "W", "tyres, hurdles, a climbing wall"),
    ("BikeRack",       "CarPark",    -235,   95, 30, 14, "S", "bike rack (the cyclist's bicycle) + later the wheelchairs"),
    # Machine Hall (under a big open-sided steel shed roof that blocks the view from outside)
    ("GiantFan",       "MachineHall", 150,  -85, 44, 32, "E", "the giant fan"),
    ("TeslaCoil",      "MachineHall", 215,  -95, 26, 26, "S", "the Tesla coil on its white pad"),
    ("GyroCage",       "MachineHall", 335,  -90, 44, 22, "S", "the gyro cage with its red button in front"),
    ("Press",          "MachineHall", 150,  -30, 28, 28, "E", "the press (compressor)"),
    ("StretchMachine", "MachineHall", 245,  -48, 22, 30, "S", "the stretch machine"),
    ("Washer",         "MachineHall", 335,  -30, 28, 26, "W", "the washing machine, door facing the courtyard path"),
    # Fun Fair
    ("Sandcastle",     "FunFair",     150,  135, 28, 28, "E", "the sandcastle tower with crates and a picket fence"),
    ("Playground",     "FunFair",     245,  150, 44, 40, "S", "slide and swings where ragdolls play"),
    ("Archery",        "FunFair",     345,  120, 34, 22, "W", "the archery target + the slingshot facing it"),
    ("Sandbox",        "FunFair",     150,  205, 32, 30, "N", "the yellow sandbox"),
    ("Seesaw",         "FunFair",     215,  215, 26, 8,  "N", "the wooden seesaw"),
    ("Mole",           "FunFair",     280,  208, 22, 22, "N", "the mole"),
    ("SandCircle",     "FunFair",     350,  195, 50, 50, "N", "the big round sand circle"),
    # Launch Field
    ("Cannon",         "LaunchField", -235, 335, 20, 26, "W", "the cannon, firing WEST over the landing field (load: put the ragdoll fully inside)"),
    ("LandingField",   "LaunchField", -350, 340, 170, 76, "E", "the landing field with distance boards 50/100/150"),
    ("Rocket",         "LaunchField", -185, 358, 30, 30, "W", "the rocket on its round pad + steel gantry"),
    # Danger Zone
    ("LavaStrip",      "DangerZone",  180, 365, 140, 22, "N", "the lava strip with the sunken stone trench beside it, low fence"),
    ("Shredder",       "DangerZone",  330, 318, 42, 26, "W", "the shredder pit (railing, lever box, red button)"),
    ("Sweeper",        "DangerZone",  335, 360, 40, 40, "W", "the round sweeper pad with its turning beam"),
    # Tower Square
    ("Tower",          "TowerSquare", -30,   40, 56, 56, "N", "the 5-floor steel stair tower, 95 high (the landmark seen from everywhere)"),
    ("SlideRunout",    "TowerSquare", -95,   75, 20, 30, "SW", "where the green slide ends (the slide runs from the tower top down to here)"),
    ("Grandstand",     "TowerSquare",  30,   -5, 44, 16, "SW", "the grandstand facing the tower"),
    ("Trampoline",     "TowerSquare",  30,   90, 26, 26, "N", "the raised trampoline"),
    # Picnic Park
    ("PicnicGrill",    "PicnicPark",  -90,  200, 50, 34, "E", "picnic tables + grill"),
    ("DogYard",        "PicnicPark",   30,  200, 34, 34, "W", "the doghouse in a small fenced yard"),
    ("Gazebo",         "PicnicPark",   30,  335, 30, 30, "W", "a gazebo in a flower garden"),
    ("DuckPond",       "PicnicPark",  -90,  335, 46, 34, "E", "a small pond with ducks"),
    # Edge
    ("Hangar",         "Edge",       -440, -372, 60, 20, "S", "the train hangar at the north end of the west railway"),
    ("WaterTower",     "Edge",        425, -372, 16, 16, "S", "the water tower"),
    ("ControlTower",   "Edge",        425,  425, 16, 16, "N", "the control tower"),
]

BELT = 18          # tree belt width inside a walled room's edge
GAP = 26           # opening width at an entrance
ITEM_MARGIN = 6    # free floor between two items

# ---------- geometry helpers ----------
def rect_of(x, z, w, d):
    return (x - w / 2, z - d / 2, x + w / 2, z + d / 2)

def overlap(a, b, m=0):
    return not (a[2] + m <= b[0] or b[2] + m <= a[0] or a[3] + m <= b[1] or b[3] + m <= a[1])

def road_rects():
    out = []
    for rid, w, pts in ROADS:
        for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
            out.append((rid, (min(x0, x1) - (w / 2 if x0 == x1 else 0), min(z0, z1) - (w / 2 if z0 == z1 else 0),
                              max(x0, x1) + (w / 2 if x0 == x1 else 0), max(z0, z1) + (w / 2 if z0 == z1 else 0))))
    return out

def room(rid):
    for r in ROOMS:
        if r[0] == rid:
            return r
    return None

def plaza(pid):
    for p in PLAZAS:
        if p[0] == pid:
            return p
    return None

def lint():
    problems = []
    roads = road_rects()
    rects = {}
    for it in ITEMS:
        iid, rid, x, z, w, d = it[:6]
        r = rect_of(x, z, w, d)
        rects[iid] = r
        b = BOUNDS
        if not (b[0] <= r[0] and r[2] <= b[2] and b[1] <= r[1] and r[3] <= b[3]):
            problems.append(f"{iid}: outside the map")
        rm = room(rid)
        if rm:
            inset = 0 if rid in OPEN_ROOMS else BELT
            inner = (rm[2] + inset, rm[3] + inset, rm[4] - inset, rm[5] - inset)
            if not (inner[0] <= r[0] and r[2] <= inner[2] and inner[1] <= r[1] and r[3] <= inner[3]):
                problems.append(f"{iid}: not inside {rid}'s inner area (behind its tree belt)")
        pz = plaza(rid)
        if pz:
            if pz[1] == "rect":
                pr = rect_of(pz[2], pz[3], pz[4], pz[5])
                if not (pr[0] <= r[0] and r[2] <= pr[2] and pr[1] <= r[1] and r[3] <= pr[3]):
                    problems.append(f"{iid}: not on {rid}")
            else:
                far = max(math.hypot(cx - pz[2], cz - pz[3]) for cx in (r[0], r[2]) for cz in (r[1], r[3]))
                if far > pz[4] + 1:
                    problems.append(f"{iid}: sticks out of {rid}")
        for road_id, rr in roads:
            if rid in ("SpawnPlaza", "TowerSquare"):
                continue
            if overlap(r, rr, 2):
                problems.append(f"{iid}: on the road {road_id}")
    ids = list(rects)
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            if overlap(rects[ids[i]], rects[ids[j]], ITEM_MARGIN):
                problems.append(f"{ids[i]} and {ids[j]} overlap (need {ITEM_MARGIN} free)")
    # the tower square things must not sit on the 4 roads entering it, nor on the tower
    # every walled room has an entrance on a road or plaza path
    road_pts = set()
    for _, _, pts in ROADS:
        for p in pts:
            road_pts.add(p)
    for r in ROOMS:
        if r[0] in OPEN_ROOMS:
            continue
        if not r[6]:
            problems.append(f"{r[0]}: no entrance")
        for e in r[6]:
            if e not in road_pts:
                problems.append(f"{r[0]}: entrance {e} has no road reaching it")
    return problems

# ---------- inner paths: every attraction is reached by a path from its room's courtyard ----------
INNER_W = 16

def front_point(x, z, w, d, face):
    f = face[0]
    o = INNER_W / 2 + 3 + ROUTE_MARGIN  # (the branch ends at a landing pad here; the builder fits the landing to the thing's built front edge)
    if f == "N":
        return (x, z - d / 2 - o)
    if f == "S":
        return (x, z + d / 2 + o)
    if f == "E":
        return (x + w / 2 + o, z)
    return (x - w / 2 - o, z)

def seg_rect(a, b, w):
    (x0, z0), (x1, z1) = a, b
    if z0 == z1:
        return (min(x0, x1), z0 - w / 2, max(x0, x1), z0 + w / 2)
    return (x0 - w / 2, min(z0, z1), x0 + w / 2, max(z0, z1))

import heapq

CELL = 5

ROUTE_MARGIN = 2  # extra studs round every attraction for routing (the built model may be a bit bigger than its plan box)

def grid_path(a, b, avoid, bounds, network=None):
    """A few-turn path from a to b (or, when network is given, to the nearest cell of that network: a T-junction)
    on a CELL grid. It keeps INNER_W/2 + 2 + ROUTE_MARGIN clear of every rect in avoid and stays inside bounds.
    Cells already in the network are cheap, so paths share trunks instead of running side by side.
    Returns (corner points, cells) or (None, None)."""
    x0, z0, x1, z1 = bounds
    half = INNER_W / 2 + 2
    keep = half + ROUTE_MARGIN
    def snap(p):
        return (round((p[0] - x0) / CELL), round((p[1] - z0) / CELL))
    nx, nz = int((x1 - x0) / CELL) + 1, int((z1 - z0) / CELL) + 1
    def free(i, j):
        x, z = x0 + i * CELL, z0 + j * CELL
        if not (x0 + half <= x <= x1 - half and z0 + half <= z <= z1 - half):
            return False
        for r in avoid:
            if r[0] - keep < x < r[2] + keep and r[1] - keep < z < r[3] + keep:
                return False
        return True
    net = network or set()
    sa = snap(a)
    sb = snap(b) if b is not None else None
    start = (sa[0], sa[1], -1)
    dist = {start: 0}
    pq = [(0, start)]
    prev = {}
    dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    goal = None
    while pq:
        d, (i, j, k) = heapq.heappop(pq)
        if (i, j) == sb or ((i, j) in net and (i, j) != sa):
            goal = (i, j, k)
            break
        if d > dist.get((i, j, k), 1e18):
            continue
        for kk, (di, dj) in enumerate(dirs):
            ni, nj = i + di, j + dj
            if not (0 <= ni < nx and 0 <= nj < nz):
                continue
            endpoint = (ni, nj) == sa or (ni, nj) == sb or (ni, nj) in net
            if not endpoint and not free(ni, nj):
                continue
            step = 0.3 if (ni, nj) in net else 1
            nd = d + step + (6 if (k != -1 and kk != k) else 0)
            st = (ni, nj, kk)
            if nd < dist.get(st, 1e18):
                dist[st] = nd
                prev[st] = (i, j, k)
                heapq.heappush(pq, (nd, st))
    if not goal:
        return None, None
    cells = []
    st = goal
    while True:
        cells.append((st[0], st[1]))
        if st == start:
            break
        st = prev[st]
    cells.reverse()
    pts = [(x0 + i * CELL, z0 + j * CELL) for i, j in cells]
    pts[0] = a
    if b is not None and cells[-1] == sb:
        pts[-1] = b
    out = [pts[0]]
    for k in range(1, len(pts) - 1):
        p0, p1, p2 = out[-1], pts[k], pts[k + 1]
        if (p0[0] == p1[0] == p2[0]) or (p0[1] == p1[1] == p2[1]):
            continue
        out.append(p1)
    out.append(pts[-1])
    fixed = [out[0]]
    for q in out[1:]:
        pr = fixed[-1]
        if pr[0] != q[0] and pr[1] != q[1]:
            fixed.append((q[0], pr[1]))
        fixed.append(q)
    # drop zero-length legs
    clean = [fixed[0]]
    for q in fixed[1:]:
        if q != clean[-1]:
            clean.append(q)
    return clean, set(cells)

INNER = []  # (room, target, points)
INNER_PROBLEMS = []

def build_inner():
    """Per room ONE connected path network (a tree): the entrances join the courtyard, then every attraction's
    branch joins the nearest point of the network already built (a T-junction), so trunks are shared and nothing
    runs side by side. Each attraction's branch ends at its front landing."""
    INNER.clear(); INNER_PROBLEMS.clear()
    for rid, name, x0, z0, x1, z1, ents, court in ROOMS:
        if rid in OPEN_ROOMS or not court:
            continue
        items = [it for it in ITEMS if it[1] == rid]
        rects = {it[0]: rect_of(it[2], it[3], it[4], it[5]) for it in items}
        inner = (x0 + BELT, z0 + BELT, x1 - BELT, z1 - BELT)
        network = set()
        # the courtyard is the root of the tree
        cx0, cz0 = inner[0], inner[1]
        network.add((round((court[0] - cx0) / CELL), round((court[1] - cz0) / CELL)))
        for e in ents:
            ex, ez = e
            if ez == z0:
                ei = (ex, z0 + BELT + 12)
            elif ez == z1:
                ei = (ex, z1 - BELT - 12)
            elif ex == x0:
                ei = (x0 + BELT + 12, ez)
            else:
                ei = (x1 - BELT - 12, ez)
            pts, cells = grid_path(ei, court, list(rects.values()), inner, network)
            if pts:
                INNER.append((rid, "entrance", [e] + pts))
                network |= cells
            else:
                INNER_PROBLEMS.append(f"{rid}: no clear path from entrance {e} to the courtyard")
        # nearest attractions first, so the far ones branch off the near ones' paths
        items.sort(key=lambda it: math.hypot(it[2] - court[0], it[3] - court[1]))
        for it in items:
            iid, _, x, z, w, d, face = it[:7]
            fp = front_point(x, z, w, d, face)
            others = [r for k, r in rects.items() if k != iid]
            pts, cells = grid_path(fp, None, others, inner, network)
            if pts:
                INNER.append((rid, iid, list(reversed(pts))))  # from the network out to the attraction
                network |= cells
            else:
                INNER_PROBLEMS.append(f"{rid}: no clear path from the network to {iid}'s front ({face})")

# ---------- outputs ----------
def lua_str(s):
    return '"' + s.replace('"', '\\"') + '"'

def write_luau():
    L = []
    L.append("--!strict")
    L.append("-- OwnerMapPlan: GENERATED by tools/masterplan.py (do not edit by hand; edit the script and run it).")
    L.append("-- The big owner map's master plan (owner, 26 Nov 2026: \"Det her map er 1/10, sørg for det bliver 10/10\";")
    L.append("-- docs/MAP_MASTERPLAN.md). Lab space studs: x east, z south (north = -z). LabOwnerMap builds from it.")
    L.append("-- Rooms are walled by tree belts (BELT wide, inside the room edge) with openings (GAP wide) at the entrances,")
    L.append("-- so you never see everything at once. Items: keep the footprint w x d free for the thing; face = its front.")
    L.append("")
    L.append("local Plan = {}")
    L.append(f"Plan.BELT = {BELT}")
    L.append(f"Plan.GAP = {GAP}")
    L.append("Plan.ROOMS = {")
    for rid, name, x0, z0, x1, z1, ents, court in ROOMS:
        e = ", ".join(f"Vector2.new({x}, {z})" for x, z in ents)
        c = f"Vector2.new({court[0]}, {court[1]})" if court else "nil"
        walled = "false" if rid in OPEN_ROOMS else "true"
        L.append(f"\t{rid} = {{ name = {lua_str(name)}, min = Vector2.new({x0}, {z0}), max = Vector2.new({x1}, {z1}), walled = {walled}, entrances = {{ {e} }}, courtyard = {c} }},")
    L.append("}")
    L.append("Plan.PLAZAS = {")
    for pid, kind, x, z, a, b in PLAZAS:
        if kind == "rect":
            L.append(f"\t{pid} = {{ kind = \"rect\", at = Vector2.new({x}, {z}), size = Vector2.new({a}, {b}) }},")
        else:
            L.append(f"\t{pid} = {{ kind = \"circle\", at = Vector2.new({x}, {z}), radius = {a} }},")
    L.append("}")
    L.append("Plan.ROADS = {")
    for rid, w, pts in ROADS:
        p = ", ".join(f"Vector2.new({x}, {z})" for x, z in pts)
        L.append(f"\t{{ id = {lua_str(rid)}, width = {w}, points = {{ {p} }} }},")
    L.append("}")
    L.append("-- Inner paths (INNER_W wide): entrance -> courtyard -> the FRONT of every attraction. Each ends exactly at the thing.")
    L.append(f"Plan.INNER_W = {INNER_W}")
    L.append("Plan.INNER = {")
    for rid, target, pts in INNER:
        p = ", ".join(f"Vector2.new({x:g}, {z:g})" for x, z in pts)
        L.append(f"\t{{ zone = {lua_str(rid)}, to = {lua_str(target)}, points = {{ {p} }} }},")
    L.append("}")
    L.append("Plan.ITEMS = {")
    for iid, rid, x, z, w, d, face, what in ITEMS:
        L.append(f"\t{iid} = {{ zone = {lua_str(rid)}, at = Vector2.new({x}, {z}), size = Vector2.new({w}, {d}), face = {lua_str(face)}, what = {lua_str(what)} }},")
    L.append("}")
    L.append("")
    L.append("return Plan")
    path = os.path.join(ROOT, "ReplicatedStorage/ReplicatedStorage/Shared/OwnerMapPlan.luau")
    with open(path, "w") as f:
        f.write("\n".join(L) + "\n")
    return path

def draw_png():
    SC = 2  # px per stud... image ~1900 x 1640
    bx0, bz0, bx1, bz1 = BOUNDS
    W, H = int((bx1 - bx0) * SC), int((bz1 - bz0) * SC)
    img = Image.new("RGB", (W, H + 60), (118, 168, 84))
    dr = ImageDraw.Draw(img)
    def P(x, z):
        return ((x - bx0) * SC, (z - bz0) * SC)
    def R(r, **kw):
        dr.rectangle([P(r[0], r[1]), P(r[2], r[3])], **kw)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
        small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
    except Exception:
        font = small = ImageFont.load_default()
    # railway (U: west, south, east)
    for pts in ([(-490, -360), (-490, 420)], [(-490, 420), (430, 420)], [(430, 420), (430, -360)]):
        dr.line([P(*pts[0]), P(*pts[1])], fill=(90, 80, 70), width=8)
    # rooms + tree belts
    for rid, name, x0, z0, x1, z1, ents, court in ROOMS:
        if rid in OPEN_ROOMS:
            R((x0, z0, x1, z1), outline=(70, 110, 50), width=3)
        else:
            R((x0, z0, x1, z1), fill=(128, 176, 92))
            # belts
            belt = (40, 100, 45)
            for side in ("N", "S", "W", "E"):
                if side == "N":
                    seg = (x0, z0, x1, z0 + BELT)
                elif side == "S":
                    seg = (x0, z1 - BELT, x1, z1)
                elif side == "W":
                    seg = (x0, z0, x0 + BELT, z1)
                else:
                    seg = (x1 - BELT, z0, x1, z1)
                R(seg, fill=belt)
            for ex, ez in ents:  # openings
                R((ex - GAP / 2 if ez in (z0, z1) else ex - BELT - 1, ez - BELT - 1 if ex in (x0, x1) else ez - BELT - 1,
                   ex + GAP / 2 if ez in (z0, z1) else ex + BELT + 1, ez + BELT + 1), fill=(128, 176, 92))
            if court:
                R(rect_of(court[0], court[1], 30, 22), fill=(205, 205, 198))
        tx, tz = P(x0 + 6, z0 + 4)
        dr.text((tx + 2, tz - 2), name, fill=(255, 255, 255), font=font, stroke_width=3, stroke_fill=(30, 50, 20))
    # roads
    for rid, w, pts in ROADS:
        for a, b in zip(pts, pts[1:]):
            dr.line([P(*a), P(*b)], fill=(212, 212, 206), width=int(w * SC))
    # plazas
    for pid, kind, x, z, a, b in PLAZAS:
        if kind == "rect":
            R(rect_of(x, z, a, b), fill=(196, 196, 192), outline=(128, 128, 132), width=4)
        else:
            dr.ellipse([P(x - a, z - a), P(x + a, z + a)], fill=(205, 205, 198), outline=(150, 150, 150), width=3)
    # inner paths
    for rid, target, pts in INNER:
        for a, b in zip(pts, pts[1:]):
            dr.line([P(*a), P(*b)], fill=(225, 222, 210), width=int(INNER_W * SC))
    # items
    for iid, rid, x, z, w, d, face, what in ITEMS:
        col = (255, 140, 60)
        if rid == "Edge":
            col = (150, 150, 160)
        if iid in ("Spawn",):
            col = (60, 140, 255)
        R(rect_of(x, z, w, d), fill=col, outline=(40, 30, 20), width=2)
        px, pz = P(x, z)
        dr.text((px - 4 * len(iid), pz - 8), iid, fill=(20, 20, 20), font=small)
    # sightline from spawn
    dr.line([P(-30, -300), P(-30, 40)], fill=(60, 140, 255), width=3)
    dr.text((10, H + 15), "LAB MASTER PLAN (tools/masterplan.py)  north up  |  orange = attractions  dark green = tree belts (walls of the rooms)  grey = roads/plazas  blue = spawn + its view to the tower",
            fill=(255, 255, 255), font=small)
    out = os.path.join(ROOT, "art/store/lab10/masterplan.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    return out

if __name__ == "__main__":
    build_inner()
    probs = lint() + INNER_PROBLEMS
    for p in probs:
        print("LINT:", p)
    print(write_luau())
    print(draw_png())
    sys.exit(1 if probs else 0)
