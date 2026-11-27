# RAGDOLL_10 "v6 FIXES" (smaller neck, nothing overlaps, no bands) on top of "v5 FIXES" (the owner rejected v4: "nej"). build_mannequin_v6.py = this header + v4's rig, UV, bake and
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
ell("upchest", (0, 1.42, 0.02), (0.9, 0.3, 0.62), 0.35)
cone("neck", (0, 1.58, 0), (0, 1.84, 0), 0.3, 0.28, 0.12)  # v6: a short, thinner neck
# the arms (hanging clear of the body), the shoulder ball blending into the torso
ell("shoulder", (1.17, 1.37, 0), (0.42, 0.4, 0.42), 0.32)
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
cone("th0", T0, T1, 0.095, 0.088, 0.09)  # v6: a softer blend into the palm (no spike)
cone("th1", T1, T2, 0.088, 0.082, 0.02)
v("thumb0R", *T0)
v("thumb1R", *T1)
v("thumb2R", *T2)
# the legs and the round boots
cone("thigh", (LX, -0.3, 0), (LX, -1.05, 0), 0.47, 0.43, 0.24)
cone("shin", (LX, -1.05, 0), (LX, -1.76, 0.01), 0.41, 0.33, 0.06)
cone("ankle", (LX, -1.76, 0.01), (LX, -1.92, 0), 0.31, 0.3, 0.06)
ell("boot", (LX, -2.0, -0.2), (0.36, 0.25, 0.66), 0.12)
ell("heel", (LX, -1.99, 0.17), (0.32, 0.25, 0.3), 0.12)

bpy.ops.wm.read_factory_settings(use_empty=True)
spec = {"name": "MannequinV6", "parts": parts}
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
bmesh.ops.dissolve_degenerate(bm, dist=0.004, edges=bm.edges[:])  # v6: no slivers
bmesh.ops.triangulate(bm, faces=bm.faces[:])
lcr._relax_project(bm, field, 4, keep_seam=False)

# ---- the bands: two plane cuts at every joint, so each band is a clean edge loop ------------------------------------
def nodeR(n):
    return R(V[n][0])


BANDS = []  # v6: the owner removed every dark joint band; the body is one clean light grey
HW = 0.06


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
# v6: no loose specks: keep only the one big connected body
seen, comps = set(), []
for f0 in bm.faces:
    if f0 in seen:
        continue
    comp, stack = [], [f0]
    seen.add(f0)
    while stack:
        f_ = stack.pop()
        comp.append(f_)
        for e_ in f_.edges:
            for g_ in e_.link_faces:
                if g_ not in seen:
                    seen.add(g_)
                    stack.append(g_)
    comps.append(comp)
comps.sort(key=len, reverse=True)
print("V6 shells", [len(c_) for c_ in comps[:6]])
for c_ in comps[1:]:
    bmesh.ops.delete(bm, geom=c_, context="FACES")
# v6: no flipped or sliver faces: every face must face the way the shape's surface does; a face that faces in is
# dissolved and the hole filled, then the normals recomputed outward
bm.normal_update()
cent = np.array([f.calc_center_median()[:] for f in bm.faces])
grad = field.grad(cent)
bad = [f for f, g in zip(bm.faces, grad) if Vector(g).normalized().dot(f.normal) < 0.45 or f.calc_area() < 1e-6]
print("V6 bad faces", len(bad))
if bad:
    bmesh.ops.delete(bm, geom=bad, context="FACES")
    edges = [e for e in bm.edges if e.is_boundary]
    bmesh.ops.holes_fill(bm, edges=edges, sides=0)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    rest = [e for e in bm.edges if e.is_boundary]
    if rest:  # a flat sliver hole: weld its corners into one point
        vs_ = list({v_ for e in rest for v_ in e.verts})
        bmesh.ops.pointmerge(bm, verts=vs_, merge_co=sum((v_.co for v_ in vs_), Vector()) / len(vs_))
        bmesh.ops.dissolve_degenerate(bm, dist=1e-5, edges=bm.edges[:])
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    print("V6 boundary edges left", sum(1 for e in bm.edges if e.is_boundary))
    for e in [e for e in bm.edges if e.is_boundary]:
        print("V6 edge", [tuple(round(c, 3) for c in R(v_.co)) for v_ in e.verts], len(e.link_faces))
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
# ---- the rig (R15 names, the same layout as v3) --------------------------------------------------------------------
arm = bpy.data.armatures.new("MannequinRig")
rig = bpy.data.objects.new("MannequinRig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.edit_bones


def bone(n, h, t, parent=None, deform=True):
    b = eb.new(n)
    b.head, b.tail, b.use_deform = B(*h), B(*t), deform
    if parent:
        b.parent = eb[parent]


bone("HumanoidRootPart", (0, -0.6, 0), (0, -0.1, 0), deform=False)
bone("LowerTorso", (0, -0.2, 0), (0, 0.2, 0), "HumanoidRootPart")
bone("UpperTorso", (0, 0.2, 0), (0, 1.8, 0), "LowerTorso")
bone("Head", (0, 1.8, 0), (0, 2.9, 0), "UpperTorso")
for side, s, P in (("L", -1, "Left"), ("R", 1, "Right")):
    bone(P + "UpperArm", (SH[0] * s, SH[1], 0), (EL[0] * s, EL[1], EL[2]), "UpperTorso")
    bone(P + "LowerArm", (EL[0] * s, EL[1], EL[2]), (WR[0] * s, WR[1], WR[2]), P + "UpperArm")
    bone(P + "Hand", (WR[0] * s, WR[1], WR[2]), (WR[0] * s, -0.42, WR[2]), P + "LowerArm")
    for i, fname in enumerate(("Index", "Middle", "Ring", "Pinky")):
        prev = P + "Hand"
        for k in range(3):
            a = V["fb%d%s" % (i, side)][0] if k == 0 else V["f%d%d%s" % (i, k - 1, side)][0]
            b = V["f%d%d%s" % (i, k, side)][0]
            bb = eb.new("%s%s%d" % (P, fname, k + 1))
            bb.head, bb.tail, bb.parent = a, b, eb[prev]
            prev = bb.name
    prev = P + "Hand"
    for k, (a, b) in enumerate((("palm", "thumb0"), ("thumb0", "thumb1"), ("thumb1", "thumb2"))):
        if k == 0:
            continue
        bb = eb.new("%sThumb%d" % (P, k))
        bb.head, bb.tail, bb.parent = V[a + side][0], V[b + side][0], eb[prev]
        prev = bb.name
    LX = 0.55 * s
    bone(P + "UpperLeg", (LX, -0.2, 0), (LX, -1.022, 0), "LowerTorso")
    bone(P + "LowerLeg", (LX, -1.022, 0), (LX, -1.82, 0), P + "UpperLeg")
    bone(P + "Foot", (LX, -1.82, 0), (LX, -2.03, -0.62), P + "LowerLeg")
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(lock_active=False)
bpy.ops.object.mode_set(mode="OBJECT")

# ---- UVs: smart project into the left 3/4, each marking area its own flat square in the right column ---------------
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004)
bpy.ops.object.mode_set(mode="OBJECT")
bm = bmesh.new()
bm.from_mesh(me)
uvl = bm.loops.layers.uv.active
for f in bm.faces:
    for l in f.loops:
        uv = l[uvl].uv
        uv.x = uv.x * 0.75
# the markings: (name, centre (Roblox), outward normal (Roblox), circle radius)
MARKS = [("chest", (0, 1.1, -0.8), (0, 0, -1), 0.3)]
for s, sname in ((-1, "L"), (1, "R")):
    MARKS.append(("knee" + sname, (1.0 * s, -0.7, 0), (s, 0, 0), 0.17))  # v6: on the thigh, away from the joints
    MARKS.append(("arm" + sname, (1.8 * s, 0.96, 0), (s, 0, 0), 0.17))
squares = []
for k, (name, c, n, r) in enumerate(MARKS):
    c, n = Vector(c), Vector(n).normalized()
    up = Vector((0, 1, 0)) if abs(n.y) < 0.9 else Vector((0, 0, 1))
    u = up.cross(n).normalized()
    w = n.cross(u).normalized()
    Rr = r * (2.6 if name == "chest" else 2.3)
    u0, v0, size = 0.77, 1 - (k + 1) * 0.195, 0.18
    squares.append({"name": name, "u0": u0, "v0": v0, "size": size, "circle": r / (2 * Rr), "plate": [0.74 / (2 * Rr), 0.5 / (2 * Rr)] if name == "chest" else None})
    for f in bm.faces:
        fc = R(f.calc_center_median())
        fn = Vector((f.normal.x, f.normal.z, -f.normal.y))
        d = fc - c
        if d.length < Rr * (1.3 if name == "chest" else 0.95) and fn.dot(n) > (0.3 if name == "chest" else 0.0):
            # v6: only faces that lie WHOLLY inside the square (no clamping, so no folded or stretched UVs at the edge)
            ab = []
            for l in f.loops:
                p = R(l.vert.co) - c
                ab.append((p.dot(u) / (2 * Rr) + 0.5, p.dot(w) / (2 * Rr) + 0.5))
            if all(0.02 < x_ < 0.98 and 0.02 < y_ < 0.98 for x_, y_ in ab):
                for l, (a, b2) in zip(f.loops, ab):
                    l[uvl].uv = (u0 + a * size, v0 + b2 * size)
# the bands and soles: every face collapsed onto ONE solid dark texel square (no bake, no UV seam bleed), so each band
# is exactly its mesh loop with a straight clean edge
def face_kind(p):
    for (bc, ax, hw, lim, s_) in BANDS:
        al, rr = radial(p, bc, ax)
        if abs(al) < hw and rr < lim:
            return "band"
    return "sole" if p.y < -2.1 else None


for f in bm.faces:
    kind = face_kind(R(f.calc_center_median()))
    if kind:
        uvpt = (0.985, 0.012) if kind == "band" else (0.985, 0.04)
        for l in f.loops:
            l[uvl].uv = uvpt
bm.to_mesh(me)
bm.free()

# ---- the bake (vertex colour x a subtle AO), 2048 --------------------------------------------------------------------
img = bpy.data.images.new("mannequin_v6_color", 2048, 2048)
img.generated_color = (0.40, 0.40, 0.41, 1.0)  # v6: seams and gaps read as the body grey, never black specks
mat = bpy.data.materials.new("Bake")
mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
o = nt.nodes.new("ShaderNodeOutputMaterial")
em = nt.nodes.new("ShaderNodeEmission")
vc = nt.nodes.new("ShaderNodeVertexColor")
vc.layer_name = "Col"
ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
ao.inputs["Distance"].default_value = 0.25
mx = nt.nodes.new("ShaderNodeMix")
mx.data_type = "RGBA"
mx.blend_type = "MULTIPLY"
mx.inputs["Factor"].default_value = 0.35
nt.links.new(vc.outputs["Color"], mx.inputs["A"])
nt.links.new(ao.outputs["AO"], mx.inputs["B"])
nt.links.new(mx.outputs["Result"], em.inputs["Color"])
nt.links.new(em.outputs["Emission"], o.inputs["Surface"])
tx = nt.nodes.new("ShaderNodeTexImage")
tx.image = img
nt.nodes.active = tx
me.materials.clear()
me.materials.append(mat)
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 96
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.bake(type="EMIT", margin=24)
img.filepath_raw = os.path.join(HERE, "mannequin_v6_base.png")
img.file_format = "PNG"
img.save()
json.dump({"squares": squares, "size": 2048}, open(os.path.join(HERE, "mannequin_v6_marks.json"), "w"), indent=1)
plain = bpy.data.materials.new("DummyV6")
me.materials.clear()
me.materials.append(plain)
tris = sum(len(p.vertices) - 2 for p in me.polygons)
out = os.path.join(HERE, "mannequin_v6.fbx")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
                         add_leaf_bones=False, bake_anim=False, use_mesh_modifiers=True, object_types={"ARMATURE", "MESH"})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "mannequin_v6.blend"))
dims = body.dimensions
json.dump({"tris": tris, "bones": len(arm.bones), "size_studs": [round(dims.x, 2), round(dims.z, 2), round(dims.y, 2)]},
          open(os.path.join(HERE, "mannequin_v6_stats.json"), "w"), indent=1)
print("V4", tris, len(arm.bones))
