# RAGDOLL_10 "v4 FIXES" (the owner rejected v3: "helt ude og skide"). A SOFT, CHUNKY TOY crash-test dummy:
#   - ONE smooth merged mesh (Skin + Subsurf + smoothing): no separate objects at all;
#   - the joint rings are a shallow GROOVE in the surface (the skin is pinched at the joint) with a flush dark band painted
#     into it: never a donut stuck on;
#   - BIG round toy hands (a 0.6 wide palm, 4 thick sausage fingers, a thick thumb, round tips);
#   - rounded BOOT feet (a round toe, a heel, a thick sole band), about 1.4 long, with a groove ring at the ankle;
#   - a round belly and chest, softly tapering limbs, the arms hanging clear of the body;
#   - the chest plate is a soft lighter oval painted INTO the chest; the black-and-yellow quarter-circle MARKINGS are crisp
#     vector shapes drawn into a 2048 colour map by mannequin_v4_markings.py (each marking area has its own flat UV square
#     in the right column of the texture, so a circle is never stretched or smeared).
# Pass 1 (this script, Blender): the mesh, rig, weights, UVs, the base colour + AO bake, the FBX; it writes
# mannequin_v4_marks.json (the UV squares). Then mannequin_v4_markings.py (Pillow) draws the markings; then
# render_mannequin_v4.py (Blender) makes the review renders.
import bpy, bmesh, json, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))


def B(x, y, z=0.0):
    return Vector((x, -z, y))


GREY = (0.40, 0.40, 0.41, 1.0)
PLATE = (0.60, 0.60, 0.61, 1.0)
BAND = (0.13, 0.13, 0.14, 1.0)
SOLE = (0.10, 0.10, 0.11, 1.0)

V, E = {}, []


def v(n, x, y, z, rx, ry=None):
    V[n] = (B(x, y, z), rx, ry if ry is not None else rx)


def e(a, b):
    E.append((a, b))


# torso: round and soft (a slightly bigger belly and chest)
v("pelvis", 0, -0.1, 0, 0.9, 0.58)
v("waist", 0, 0.3, 0, 0.86, 0.56)
v("belly", 0, 0.7, -0.03, 0.96, 0.62)
v("chest", 0, 1.08, -0.04, 1.02, 0.6)
v("upchest", 0, 1.38, 0, 0.98, 0.52)
v("neckbase", 0, 1.7, 0, 0.36, 0.34)
v("neckg", 0, 1.84, 0, 0.29, 0.29)  # the neck groove
v("neck", 0, 2.0, 0, 0.32, 0.32)
SH = (1.28, 1.4)
EL = (1.42, 0.8, -0.04)
WR = (1.5, 0.08, -0.14)
for side, s in (("L", -1), ("R", 1)):
    v("clav" + side, 0.82 * s, 1.46, 0, 0.36, 0.34)
    v("shoulder" + side, SH[0] * s, SH[1], 0, 0.37, 0.37)
    v("shg" + side, 1.31 * s, 1.24, -0.01, 0.31, 0.31)  # the shoulder groove (just below the ball)
    v("uarm" + side, 1.36 * s, 1.06, -0.02, 0.33, 0.33)
    v("elg" + side, EL[0] * s, EL[1], EL[2], 0.25, 0.25)  # the elbow groove
    v("farm" + side, 1.46 * s, 0.44, -0.09, 0.29, 0.28)
    v("wrg" + side, WR[0] * s, WR[1] + 0.06, WR[2], 0.2, 0.2)  # the wrist groove
    X, Z0 = WR[0] * s, WR[2]
    # a BIG round toy hand: the palm (0.6 wide), 4 thick sausage fingers, a thick thumb in front
    v("palm" + side, X, -0.22, Z0, 0.27, 0.36)
    v("knuck" + side, X, -0.44, Z0, 0.25, 0.35)
    for i, (z, ln) in enumerate(((-0.25, 0.85), (-0.085, 0.95), (0.085, 0.9), (0.25, 0.75))):
        y = -0.44
        prev = "knuck" + side
        for k, seg in enumerate((0.15, 0.12, 0.1)):
            y -= seg * ln
            n = "f%d%d%s" % (i, k, side)
            v(n, X - s * 0.01 * k, y, Z0 + z, 0.125 - 0.006 * k)
            if k == 0:
                v("fb%d%s" % (i, side), X, -0.46, Z0 + z, 0.13)
                e(prev, "fb%d%s" % (i, side))
                prev = "fb%d%s" % (i, side)
            e(prev, n)
            prev = n
    v("thumb0" + side, X - s * 0.12, -0.16, Z0 - 0.32, 0.15)
    v("thumb1" + side, X - s * 0.16, -0.3, Z0 - 0.44, 0.14)
    v("thumb2" + side, X - s * 0.18, -0.42, Z0 - 0.5, 0.13)
    # the leg: hip groove, thigh, knee groove, calf, ankle groove, the boot
    LX = 0.5 * s
    v("hipg" + side, LX, -0.42, 0, 0.42, 0.42)
    v("thigh" + side, LX, -0.68, 0, 0.45, 0.45)
    v("kng" + side, LX, -1.022, -0.02, 0.34, 0.35)
    v("calf" + side, LX, -1.34, 0.02, 0.36, 0.37)
    v("ang" + side, LX, -1.78, 0, 0.25, 0.25)
    v("boot" + side, LX, -1.98, -0.05, 0.32, 0.3)
    v("heel" + side, LX, -2.05, 0.32, 0.27, 0.22)
    v("toe" + side, LX, -2.03, -0.62, 0.3, 0.22)
    for a, b in (("clav", "shoulder"), ("shoulder", "shg"), ("shg", "uarm"), ("uarm", "elg"), ("elg", "farm"), ("farm", "wrg"),
                 ("wrg", "palm"), ("palm", "knuck"), ("palm", "thumb0"), ("thumb0", "thumb1"), ("thumb1", "thumb2"),
                 ("hipg", "thigh"), ("thigh", "kng"), ("kng", "calf"), ("calf", "ang"), ("ang", "boot"), ("boot", "heel"), ("boot", "toe")):
        e(a + side, b + side)
    e("upchest", "clav" + side)
    e("pelvis", "hipg" + side)
for a, b in (("pelvis", "waist"), ("waist", "belly"), ("belly", "chest"), ("chest", "upchest"), ("upchest", "neckbase"), ("neckbase", "neckg"), ("neckg", "neck")):
    e(a, b)

# ---- the body ---------------------------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
names = list(V.keys())
idx = {n: i for i, n in enumerate(names)}
me = bpy.data.meshes.new("MannequinBody")
me.from_pydata([V[n][0] for n in names], [(idx[a], idx[b]) for a, b in E], [])
me.update()
body = bpy.data.objects.new("MannequinBody", me)
bpy.context.scene.collection.objects.link(body)
sk = body.modifiers.new("Skin", "SKIN")
sk.use_smooth_shade = True
sk.branch_smoothing = 1.0
sv = me.skin_vertices[0].data
for n in names:
    sv[idx[n]].radius = (V[n][1], V[n][2])
sv[idx["pelvis"]].use_root = True
sub = body.modifiers.new("Sub", "SUBSURF")
sub.levels = 2
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.modifier_apply(modifier="Skin")
bpy.ops.object.modifier_apply(modifier="Sub")
sm = body.modifiers.new("Smooth", "SMOOTH")
sm.factor = 0.7
sm.iterations = 8
bpy.ops.object.modifier_apply(modifier="Smooth")
tris = sum(len(p.vertices) - 2 for p in me.polygons)
if tris > 19000:
    d = body.modifiers.new("Dec", "DECIMATE")
    d.ratio = 19000 / tris
    bpy.ops.object.modifier_apply(modifier="Dec")
bpy.ops.object.shade_smooth()
wn = body.modifiers.new("WN", "WEIGHTED_NORMAL")
wn.keep_sharp = False
bpy.ops.object.modifier_apply(modifier="WN")

# ---- colours: grey, the plate oval, flush dark bands in the grooves, the boot soles --------------------------------
def R(p):  # Blender -> Roblox coords
    return Vector((p.x, p.z, -p.y))


rings = []  # (centre (Roblox), axis (Roblox, unit), half width, radius)
def ring(at, axis, r):
    rings.append((Vector(at), Vector(axis).normalized(), 0.075, r))


def node(n):
    return R(V[n][0])


def ringAt(at, a, b, r, t=None):
    # the band lies across the limb exactly as the skin's own loops do: its axis is the limb's edge direction; t moves it
    # along a..b onto a straight stretch of the limb (away from a branch, where the loops are not even)
    centre = node(at) if t is None else node(a).lerp(node(b), t)
    rings.append((centre, (node(b) - node(a)).normalized(), 0.07, r))


ringAt("neckg", "neckbase", "neck", 0.42)
for sd in ("L", "R"):
    ringAt("shg" + sd, "shg" + sd, "uarm" + sd, 0.42, 0.55)
    ringAt("elg" + sd, "uarm" + sd, "farm" + sd, 0.36)
    ringAt("wrg" + sd, "farm" + sd, "palm" + sd, 0.3)
    ringAt("hipg" + sd, "hipg" + sd, "thigh" + sd, 0.5, 0.75)
    ringAt("kng" + sd, "thigh" + sd, "calf" + sd, 0.46)
    ringAt("ang" + sd, "calf" + sd, "ang" + sd, 0.34, 0.72)
col = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
def colour_at(p):
    c = GREY  # (the chest plate is drawn crisp into the texture with the chest marking)
    for (ct, ax, hw, rr) in rings:
        d = p - ct
        along = d.dot(ax)
        perp = (d - ax * along).length
        if abs(along) < hw and perp < rr:
            return BAND
    if p.y < -2.12:
        return SOLE
    return c
for poly in me.polygons:
    fc = colour_at(R(poly.center))  # one colour a face: crisp band edges, no smears
    for li in poly.loop_indices:
        col.data[li].color = fc

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
    LX = 0.5 * s
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
MARKS = [("chest", (0, 1.12, -0.62), (0, 0, -1), 0.3)]
for s, sname in ((-1, "L"), (1, "R")):
    MARKS.append(("knee" + sname, (0.5 * s + 0.34 * s, -1.02, -0.02), (s, 0, 0), 0.24))
    MARKS.append(("arm" + sname, (1.36 * s + 0.31 * s, 1.0, -0.02), (s, 0, 0), 0.2))
squares = []
for k, (name, c, n, r) in enumerate(MARKS):
    c, n = Vector(c), Vector(n).normalized()
    up = Vector((0, 1, 0)) if abs(n.y) < 0.9 else Vector((0, 0, 1))
    u = up.cross(n).normalized()
    w = n.cross(u).normalized()
    Rr = r * (2.6 if name == "chest" else 1.45)
    u0, v0, size = 0.77, 1 - (k + 1) * 0.195, 0.18
    squares.append({"name": name, "u0": u0, "v0": v0, "size": size, "circle": r / (2 * Rr), "plate": [0.74 / (2 * Rr), 0.5 / (2 * Rr)] if name == "chest" else None})
    for f in bm.faces:
        fc = R(f.calc_center_median())
        fn = Vector((f.normal.x, f.normal.z, -f.normal.y))
        d = fc - c
        if d.length < Rr * 1.05 and fn.dot(n) > (0.15 if name == "chest" else 0.35):
            for l in f.loops:
                p = R(l.vert.co) - c
                a, b2 = p.dot(u) / (2 * Rr) + 0.5, p.dot(w) / (2 * Rr) + 0.5
                l[uvl].uv = (u0 + max(0, min(1, a)) * size, v0 + max(0, min(1, b2)) * size)
bm.to_mesh(me)
bm.free()

# ---- the bake (vertex colour x a subtle AO), 2048 --------------------------------------------------------------------
img = bpy.data.images.new("mannequin_v4_color", 2048, 2048)
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
sc.cycles.samples = 32
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.bake(type="EMIT", margin=8)
img.filepath_raw = os.path.join(HERE, "mannequin_v4_base.png")
img.file_format = "PNG"
img.save()
json.dump({"squares": squares, "size": 2048}, open(os.path.join(HERE, "mannequin_v4_marks.json"), "w"), indent=1)
plain = bpy.data.materials.new("DummyV4")
me.materials.clear()
me.materials.append(plain)
tris = sum(len(p.vertices) - 2 for p in me.polygons)
out = os.path.join(HERE, "mannequin_v4.fbx")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
                         add_leaf_bones=False, bake_anim=False, use_mesh_modifiers=True, object_types={"ARMATURE", "MESH"})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "mannequin_v4.blend"))
dims = body.dimensions
json.dump({"tris": tris, "bones": len(arm.bones), "size_studs": [round(dims.x, 2), round(dims.z, 2), round(dims.y, 2)]},
          open(os.path.join(HERE, "mannequin_v4_stats.json"), "w"), indent=1)
print("V4", tris, len(arm.bones))
