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
BOUNDS = (-235, -185, 222, 215)

# ---------- MAP ROUND 4 (owner, 26 Nov 2026 late: "Mappet skal være mindre som du kan se på mine reference screenshots",
# "ikke træer imellem"): the owner's own old map (docs/LAB_TARGET.md R3.2, art/store/look_target/lab_ref/ ref_11-13_phone)
# at about x1.3, compact and OPEN: one open lab, no rooms, no tree belts, no gates. A walkway ring + a cross (12-14 wide,
# light tiles), every attraction's front joined to it. Trees only in the edge band outside the ring (LabOwnerMap).
K = 1.3  # the R3.2 distances x K (LabOwnerMap.S for the builders that still use R3.2 coordinates)

# (id, name, x0, z0, x1, z1, entrances, courtyard): ONE open lab (walled = false: no belts)
ROOMS = [
    ("Lab", "The Lab", -235, -185, 222, 215, [], None),
]
OPEN_ROOMS = {"Lab"}

# ---------- PLAZAS ----------
PLAZAS = [
    ("SpawnPlaza",  "rect",     0, -140, 90, 50),   # raised 4: the spawn, the 4 leaderboards (screens face SOUTH), stair at its south edge
    ("TowerSquare", "circle",   0,   40, 34, 0),    # the round light plaza round the tower, benches on its edge (ref_13)
]

# ---------- ROADS = the main walkways (polylines, width) ----------
ROADS = [
    ("Spine",  14, [(0, -115), (0, 6)]),               # the spawn stair -> the tower square (the view: plaza -> tower)
    ("SpineS", 14, [(0, 74), (0, 120)]),                 # the tower square -> the south cross
    ("CrossN", 14, [(-150, -80), (150, -80)]),
    ("CrossS", 14, [(-150, 120), (150, 120)]),
    ("RingW",  14, [(-150, -80), (-150, 120)]),          # the ring (the motorbike and the cyclist ride it)
    ("RingE",  14, [(150, -80), (150, 120)]),
    ("TowerW", 12, [(-34, 40), (-150, 40)]),             # the tower square's side walkways to the ring
    ("TowerE", 12, [(34, 40), (150, 40)]),
]
RAILWAY = [(-222, -175), (-222, 205), (210, 205)]       # along the west edge, bending east along the south edge (ref_6/ref_12)

# ---------- ITEMS: every attraction, its footprint (keep it free), its front ----------
# (id, zone, x, z, w, d, face, what)
ITEMS = [
    # the spawn plaza (raised)
    ("Spawn",          "SpawnPlaza",    0, -132, 12, 12, "S", "spawn point, facing down the spine to the tower"),
    ("Leaderboards",   "SpawnPlaza",    0, -158, 70, 5,  "S", "the 4 leaderboards in a row in front of a low wooden fence; screens face SOUTH (ref_1)"),
    # north row (R3.2: cave, aquarium, plaza, pool, pen)
    ("CaveBear",       "Lab",        -160, -140, 50, 40, "S", "the rock dome cave with a dark arched opening, the bear and its dirt yard (F79)"),
    ("Aquarium",       "Lab",         -82, -140, 44, 30, "S", "the raised concrete glass tank with the shark, a feeding platform (F78)"),
    ("BigPool",        "Lab",          84, -140, 46, 30, "E", "the open pool (the whale)"),
    ("SpiderPen",      "Lab",         164, -140, 40, 34, "S", "the fenced dirt pen with the spider web"),
    ("EntranceVehicles","Lab",         46, -101, 60, 22, "W", "F76: the herringbone vehicle row by the spine below the spawn stair (free bicycle + paid vehicles)"),
    # west, beyond the ring, by the railway
    ("CrocPond",       "Lab",        -190,  -40, 40, 34, "E", "the dug-in crocodile pond with muddy banks + the speaker wall (F78)"),
    ("TRexPen",        "Lab",        -190,   25, 40, 50, "E", "the walled T-rex pen with its wooden gate"),
    ("Hangar",         "Lab",        -192,   95, 30, 24, "E", "the grey train garage with brown doors on the rail"),
    # west block (R3.2: car bays, boxing ring, brick wall, rocket)
    ("CarBays",        "Lab",        -110,  -52, 44, 18, "S", "painted bays: tank, monster truck, blue car (ref_11/12)"),
    ("BoxingRing",     "Lab",         -45,  -50, 24, 24, "S", "the boxing ring on its stage, steps, 2 benches (ref_11-13)"),
    ("BrickWall",      "Lab",        -135,    5, 6, 40,  "E", "the red brick crash wall, red barrel groups at its ends"),
    ("LaunchPads",     "Lab",         -98,   10, 10, 34, "W", "3 launch pads aimed at the brick wall"),
    ("WreckingBall",   "Lab",         -52,    8, 22, 22, "W", "the wrecking ball gantry"),
    ("Rocket",         "Lab",         -60,   72, 18, 18, "E", "the rocket on its pad + grey lattice gantry, by the tower (ref_13)"),
    ("SlideRunout",    "Lab",         -30,   92, 14, 18, "S", "where the tower slide ends"),
    ("DogYard",        "Lab",        -110,   88, 18, 18, "E", "the doghouse in a small fenced yard"),
    # the tower square
    ("Tower",          "TowerSquare",   0,   40, 26, 26, "S", "the 5-floor steel lattice tower, 50-55 high, stairs + slide (the landmark)"),
    # east block (R3.2: sandcastle, fan, target, plank, ring machine, trampoline)
    ("Sandcastle",     "Lab",          26,  -52, 18, 18, "S", "the beige sandcastle tower with stacked crates and a low wooden fence (ref_11)"),
    ("GiantFan",       "Lab",          66,  -52, 30, 22, "S", "the giant fan in its dark-green frame (ref_11)"),
    ("Press",          "Lab",         112,  -52, 22, 22, "S", "the press on its dark-green gantry"),
    ("TeslaCoil",      "Lab",          58,   -8, 18, 18, "S", "the Tesla coil on its pad"),
    ("StretchMachine", "Lab",         100,   -8, 16, 22, "S", "the STRETCHER (F74)"),
    ("Grandstand",     "Lab",          52,   72, 30, 12, "N", "the brown wooden grandstand facing the tower square (ref_11)"),
    ("GyroCage",       "Lab",         104,   72, 30, 18, "N", "the gyro cage with its red button"),
    ("Trampoline",     "Lab",          50,  100, 18, 14, "S", "the raised trampoline"),
    ("Washer",         "Lab",         104,  100, 20, 14, "S", "the washing machine, door facing the walkway"),
    ("Archery",        "Lab",         128,   10, 22, 16, "W", "the archery target + the slingshot"),
    # east, beyond the ring
    ("SandCircle",     "Lab",         192,  -48, 34, 34, "W", "the big round sand circle"),
    ("LavaStrip",      "Lab",         190,   30, 14, 80, "W", "the lava strip in its stone trench with a dark fence (the east edge, ref_7/ref_8)"),
    ("Sandbox",        "Lab",         192,  100, 26, 22, "W", "the yellow sandbox"),
    # south (R3.2: sweeper, shredder; + the cannon field, the car park, the small fun spots)
    ("Sweeper",        "Lab",           0,  165, 30, 30, "N", "the round sweeper pad with its turning beam"),
    ("Shredder",       "Lab",         -75,  157, 28, 18, "N", "the shredder pit (railing, lever, red button)"),
    ("Cannon",         "Lab",        -125,  165, 14, 18, "N", "the cannon, firing WEST over the landing field"),
    ("LandingField",   "Lab",        -175,  170, 60, 44, "N", "the landing field with distance boards"),
    ("CarPark",        "Lab",          75,  158, 40, 24, "N", "the car park with 4 parked cars in bays"),
    ("BikeRack",       "Lab",         122,  145, 20, 8,  "N", "the bicycle rack (pedal bikes only) + the motorbike's bay beside it (F75)"),
    ("Garage",         "Lab",         175,  165, 30, 26, "N", "the car garage"),
    ("LoungePool",     "Lab",         122,  185, 30, 22, "N", "the small pool with sun loungers"),
    ("Playground",     "Lab",         -30, -186 + 0, 0, 0, "S", "PLACEHOLDER"),
]
ITEMS = [it for it in ITEMS if it[0] != "Playground"]
ITEMS += [
    ("Playground",     "Lab",          40,  195, 26, 18, "N", "slide and swings where ragdolls play"),
    ("Seesaw",         "Lab",         -35,  200, 16, 8,  "N", "the wooden seesaw"),
    ("Mole",           "Lab",         -25,  -22, 12, 12, "E", "the mole"),
    ("RagdollBowling", "Lab",         -58, -103, 46, 12, "E", "THE HOOK by the spawn (owner: replace the chicken): a short bowling lane, 10 giant pins at the west end, a scoreboard; TRY rolls a ragdoll down it (F88)"),
    ("PicnicGrill",    "Lab",         -195, -95, 22, 14, "E", "picnic tables + grill"),
    ("BikeStand2",     "Lab",          40,   20, 10, 6,  "W", "a second FREE bicycle stand by the tower square (FTUE fix 7)"),
    ("ChickenCoop",    "Lab",         -30, 160, 16, 14, "W", "the chicken's coop and little fenced run (moved away from the spawn, F88)"),
    ("DuckPond",       "Lab",         -75,  200, 22, 12, "N", "the small duck pond"),
    ("TrainingYard",   "Lab",        -100,  -98, 1, 1,  "S", "PLACEHOLDER"),
]
ITEMS = [it for it in ITEMS if it[0] != "TrainingYard"]

BELT = 0           # (round 4: no tree belts)
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
INNER_W = 12

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

def road_cells():
    cells = set()
    x0, z0 = BOUNDS[0], BOUNDS[1]
    for _, w, pts in ROADS:
        for (ax, az), (bx, bz) in zip(pts, pts[1:]):
            n = int(max(abs(bx - ax), abs(bz - az)) / CELL) + 1
            for k in range(n + 1):
                x = ax + (bx - ax) * k / n
                z = az + (bz - az) * k / n
                cells.add((round((x - x0) / CELL), round((z - z0) / CELL)))
    for pid, kind, x, z, a, b in PLAZAS:
        if kind == "circle":
            for ang in range(0, 360, 10):
                px, pz = x + a * math.cos(math.radians(ang)), z + a * math.sin(math.radians(ang))
                cells.add((round((px - x0) / CELL), round((pz - z0) / CELL)))
    return cells

def build_inner():
    """Round 4: ONE open lab. The walkway ring, cross and spine are the network; every attraction's branch joins the
    nearest point of it (a T-junction), nearest attractions first, so short branches share trunks."""
    INNER.clear(); INNER_PROBLEMS.clear()
    network = road_cells()
    items = [it for it in ITEMS if it[1] == "Lab"]
    rects = {it[0]: rect_of(it[2], it[3], it[4], it[5]) for it in ITEMS}
    roadr = [r for _, r in road_rects()]
    def near_road(it):
        fx, fz = front_point(it[2], it[3], it[4], it[5], it[6])
        best = 1e9
        for r in roadr:
            dx = max(r[0] - fx, 0, fx - r[2]); dz = max(r[1] - fz, 0, fz - r[3])
            best = min(best, math.hypot(dx, dz))
        return best
    items.sort(key=near_road)
    for it in items:
        iid, _, x, z, w, d, face = it[:7]
        fp = front_point(x, z, w, d, face)
        others = [r for k, r in rects.items() if k != iid]
        pts, cells = grid_path(fp, None, others, BOUNDS, network)
        if pts:
            INNER.append(("Lab", iid, list(reversed(pts))))
            network |= cells
        else:
            INNER_PROBLEMS.append(f"no clear path from the walkways to {iid}'s front ({face})")

# ---------- outputs ----------
def lua_str(s):
    return '"' + s.replace('"', '\\"') + '"'

def write_luau():
    L = []
    L.append("--!strict")
    L.append("-- OwnerMapPlan: GENERATED by tools/masterplan.py (do not edit by hand; edit the script and run it).")
    L.append("-- The big owner map's master plan (owner, 26 Nov 2026: \"Det her map er 1/10, sørg for det bliver 10/10\";")
    L.append("-- docs/MAP_MASTERPLAN.md). Lab space studs: x east, z south (north = -z). LabOwnerMap builds from it.")
    L.append("-- MAP ROUND 4 (owner 26 Nov late: smaller, like the references; no trees between attractions): ONE open lab,")
    L.append("-- no rooms, belts or gates. R3.2 x K. Items: keep the footprint w x d free for the thing; face = its front.")
    L.append("")
    L.append("local Plan = {}")
    L.append(f"Plan.BELT = {BELT}")
    L.append(f"Plan.K = {K} -- the R3.2 distances x K (LabOwnerMap.S)")
    L.append(f"Plan.BOUNDS = {{ min = Vector2.new({BOUNDS[0]}, {BOUNDS[1]}), max = Vector2.new({BOUNDS[2]}, {BOUNDS[3]}) }}")
    L.append("Plan.RAILWAY = { " + ", ".join(f"Vector2.new({x}, {z})" for x, z in RAILWAY) + " }")
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
    SC = 4  # px per stud (round 4: ~1830 x 1600)
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
    for a, b in zip(RAILWAY, RAILWAY[1:]):
        dr.line([P(*a), P(*b)], fill=(90, 80, 70), width=8)
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
    dr.line([P(0, -132), P(0, 40)], fill=(60, 140, 255), width=3)
    dr.text((10, H + 15), "LAB MASTER PLAN (tools/masterplan.py)  north up  |  orange = attractions  round 4: one open lab, trees only outside the ring  grey = roads/plazas  blue = spawn + its view to the tower",
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
