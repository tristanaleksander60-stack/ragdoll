# RAGDOLL_10 "v5 FIXES" (the owner rejected v4: "nej"). build_mannequin_v5.py = this header + v4's rig, UV, bake and
# export (make_v5.py stitches them). What is new against v4:
#   - the body is ONE signed-distance shape (the LihFolk creature tool's Field: round cones and ellipsoids, smooth
#     union), meshed by surface nets + a voxel remesh + a symmetric decimate + relax/project: CHUNKY and ROUND
#     everywhere (the torso 1.6 deep, thighs 0.94, shins 0.8, upper arms 0.75, forearms 0.7);
#   - the hands: 4 SEPARATE thick fingers, fanned and gently curled (a relaxed half-open hand), a short thick thumb on
#     the inner front of the palm pointing down along the index finger (no hook);
#   - the bands: the mesh is CUT by two planes at every joint (bmesh bisect), so each band is a whole edge loop with a
#     straight clean edge, coloured per face; one band per joint, the same width everywhere; no stripes;
#   - the boot sole is cut the same way.
import bpy, bmesh, json, math, os, sys
import numpy as np
from mathutils import Vector

sys.path.append("C:/Users/tristan/LihFolk-Vault-V2/skills/roblox-blender-modeling/scripts")
import lihfolk_creature as lcr

HERE = os.path.dirname(os.path.abspath(__file__))


def B(x, y, z=0.0):
    return Vector((x, -z, y))


def R(p):  # Blender -> Roblox coords
    return Vector((p.x, p.z, -p.y))


GREY = (0.40, 0.40, 0.41, 1.0)
BAND = (0.11, 0.11, 0.12, 1.0)
SOLE = (0.09, 0.09, 0.10, 1.0)

V = {}  # the rig's nodes: name -> (Blender position, r, r)


def v(n, x, y, z, r=0.1):
    V[n] = (B(x, y, z), r, r)


SH = (1.33, 1.34)
EL = (1.53, 0.7, -0.03)
WR = (1.64, 0.12, -0.08)
LX = 0.55
parts = []


def cone(name, a, b, ra, rb, k=0.12):
    parts.append({"name": name, "type": "cone", "a": list(B(*a)), "b": list(B(*b)), "r": [ra, rb], "k": k})


def ell(name, c, r, k=0.2):
    parts.append({"name": name, "type": "ellipsoid", "c": list(B(*c)), "r": [r[0], r[2], r[1]], "k": k})


# the torso: round and deep (1.6 at the chest and the belly), a round back
ell("pelvis", (0, -0.2, 0), (0.88, 0.5, 0.74))
ell("belly", (0, 0.42, -0.05), (0.94, 0.62, 0.82), 0.3)
ell("chest", (0, 1.03, 0), (0.97, 0.6, 0.8), 0.3)
ell("upchest", (0, 1.42, 0.02), (0.9, 0.3, 0.62), 0.25)
cone("neck", (0, 1.55, 0), (0, 2.08, 0), 0.36, 0.32, 0.15)
# the arms (hanging clear of the body), the shoulder ball blending into the torso
ell("shoulder", (1.17, 1.37, 0), (0.42, 0.4, 0.42), 0.2)
cone("uarm", (SH[0], SH[1], 0), EL, 0.375, 0.35, 0.08)
cone("farm", EL, WR, 0.35, 0.3, 0.06)
# the hand (right side; the field mirrors it): a thick palm facing the body, 4 separate fingers, a short thumb in front
HX = WR[0] + 0.02
ell("palm", (HX, -0.15, -0.06), (0.17, 0.26, 0.36), 0.08)
v("palmR", HX, -0.15, -0.06)
v("knuckR", HX, -0.36, -0.06)
FING = (("Index", -0.3, 0.95, -7), ("Middle", -0.12, 1.0, -2.5), ("Ring", 0.06, 0.95, 2.5), ("Pinky", 0.22, 0.8, 7))
for i, (fname, z0, ln, fan) in enumerate(FING):
    p = Vector((HX - 0.02, -0.33, z0))
    v("fb%dR" % i, p.x, p.y, p.z)
    curl = 0.0
    f = math.radians(fan)
    for k, (seg, cr) in enumerate(((0.17, 14), (0.14, 22), (0.12, 26))):
        curl += math.radians(cr)
        d = Vector((-math.sin(curl) * math.cos(f), -math.cos(curl) * math.cos(f), math.sin(f)))
        q = p + d * seg * ln
        r0, r1 = 0.074 - 0.003 * k, 0.071 - 0.003 * k
        cone("f%d%d" % (i, k), tuple(p), tuple(q), r0, r1, 0.02 if k else 0.05)
        v("f%d%dR" % (i, k), q.x, q.y, q.z)
        p = q
# the thumb: short and thick, on the inner front of the palm, pointing down along the index finger
T0, T1, T2 = (HX - 0.06, -0.02, -0.43), (HX - 0.08, -0.22, -0.54), (HX - 0.1, -0.37, -0.55)
cone("th0", T0, T1, 0.095, 0.088, 0.04)
cone("th1", T1, T2, 0.088, 0.082, 0.02)
v("thumb0R", *T0)
v("thumb1R", *T1)
v("thumb2R", *T2)
# the legs and the round boots
cone("thigh", (LX, -0.3, 0), (LX, -1.05, 0), 0.47, 0.43, 0.15)
cone("shin", (LX, -1.05, 0), (LX, -1.76, 0.01), 0.41, 0.33, 0.06)
cone("ankle", (LX, -1.76, 0.01), (LX, -1.92, 0), 0.31, 0.3, 0.06)
ell("boot", (LX, -2.0, -0.2), (0.36, 0.25, 0.66), 0.12)
ell("heel", (LX, -1.99, 0.17), (0.32, 0.25, 0.3), 0.12)

bpy.ops.wm.read_factory_settings(use_empty=True)
spec = {"name": "MannequinV5", "parts": parts}
field = lcr.Field(spec)
GRID = 0.02
verts, faces = lcr.surface_nets(field, GRID)
body = lcr._mesh_obj("MannequinBody", verts, faces)
bpy.context.view_layer.objects.active = body
body.select_set(True)
rm = body.modifiers.new("vx", "REMESH")
rm.mode = "VOXEL"
rm.voxel_size = GRID * 0.9
bpy.ops.object.modifier_apply(modifier="vx")
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
dm = body.modifiers.new("dec", "DECIMATE")
dm.ratio = 14200 / max(tris, 1)
dm.use_symmetry = True
dm.symmetry_axis = "X"
bpy.ops.object.modifier_apply(modifier="dec")
me = body.data
bm = bmesh.new()
bm.from_mesh(me)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
lcr._relax_project(bm, field, 2, keep_seam=False)

# ---- the bands: two plane cuts at every joint, so each band is a clean edge loop ------------------------------------
def nodeR(n):
    return R(V[n][0])


BANDS = []  # (centre (Roblox), axis (Roblox), half width, radial limit, side x sign or 0)
HW = 0.06
BANDS.append((Vector((0, 1.8, 0)), Vector((0, 1, 0)), HW, 0.5, 0))
for s in (-1, 1):
    sh, el, wr = Vector((SH[0] * s, SH[1], 0)), Vector((EL[0] * s, EL[1], EL[2])), Vector((WR[0] * s, WR[1], WR[2]))
    BANDS.append((sh.lerp(el, 0.32), (el - sh).normalized(), HW, 0.46, s))
    BANDS.append((el, ((el - sh).normalized() + (wr - el).normalized()).normalized(), HW, 0.45, s))
    BANDS.append((el.lerp(wr, 0.9), (wr - el).normalized(), HW, 0.4, s))
    BANDS.append((Vector((LX * s, -0.66, 0)), Vector((0, 1, 0)), HW, 0.56, s))
    BANDS.append((Vector((LX * s, -1.05, 0)), Vector((0, 1, 0)), HW, 0.5, s))
    BANDS.append((Vector((LX * s, -1.64, 0.01)), Vector((0, 1, 0)), HW, 0.4, s))


def radial(p, c, ax):
    d = p - c
    al = d.dot(ax)
    if abs(c.x) > 1.0 and p.x * (1 if c.x > 0 else -1) < abs(c.x) - 0.4:
        return al, 99.0  # an arm band never reaches the torso
    if 0.2 < abs(c.x) < 1.0 and p.x * (1 if c.x > 0 else -1) < 0.0:
        return al, 99.0  # a leg band never reaches the other leg
    return al, (d - ax * al).length


def near(fv, c, ax, lim, slab):
    for vv in fv:
        al, rr = radial(R(vv.co), c, ax)
        if abs(al) < slab and rr < lim:
            return True
    return False


for (c, ax, hw, lim, s) in BANDS:
    for off in (-hw, hw):
        fs = [f for f in bm.faces if near(f.verts, c, ax, lim, hw + 0.5)]
        es = list({e for f in fs for e in f.edges})
        vs = list({x for f in fs for x in f.verts})
        pc = c + ax * off
        bmesh.ops.bisect_plane(bm, geom=vs + es + fs, plane_co=B(pc.x, pc.y, pc.z), plane_no=B(ax.x, ax.y, ax.z) - B(0, 0, 0), dist=1e-5)
# the boot sole: one cut at y = -2.1 (the soles only)
fs = [f for f in bm.faces if R(f.calc_center_median()).y < -1.95]
es = list({e for f in fs for e in f.edges})
vs = list({x for f in fs for x in f.verts})
bmesh.ops.bisect_plane(bm, geom=vs + es + fs, plane_co=B(0, -2.1, 0), plane_no=B(0, 1, 0) - B(0, 0, 0), dist=1e-5)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bm.to_mesh(me)
bm.free()
bpy.ops.object.shade_smooth()
wn = body.modifiers.new("WN", "WEIGHTED_NORMAL")
wn.keep_sharp = False
bpy.ops.object.modifier_apply(modifier="WN")

# ---- colours, per face (the cuts give straight edges) ----------------------------------------------------------------
col = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
for poly in me.polygons:
    p = R(poly.center)
    c = GREY
    for (bc, ax, hw, lim, s) in BANDS:
        al, rr = radial(p, bc, ax)
        if abs(al) < hw and rr < lim:
            c = BAND
    if p.y < -2.1:
        c = SOLE
    for li in poly.loop_indices:
        col.data[li].color = c

# the left side's rig nodes are the right side's mirror
for n in [k for k in V if k.endswith("R")]:
    pB, r1, r2 = V[n]
    V[n[:-1] + "L"] = (Vector((-pB.x, pB.y, pB.z)), r1, r2)
