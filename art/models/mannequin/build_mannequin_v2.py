# S2: the smooth skinned mannequin body (docs/BODY_V2.md 4c). Run headless:
#   "C:\Program Files\Blender Foundation\Blender 5.3\blender.exe" -b --factory-startup --python art/models/mannequin/build_mannequin.py
# Builds ONE connected body (no head: the dummy keeps its own Head part with today's faces) from an edge skeleton with
# Blender's Skin modifier + Subdivision, on the exact R15 rest pose of our dummy (joint positions read in Studio,
# 27 Nov 2026), with real hands (palm, 4 fingers of 3 segments, a thumb of 2) and feet with heel and toes.
# An armature with bones named after the R15 parts (plus finger bones) skins it with automatic weights.
# Output: art/models/mannequin/mannequin.fbx (+ .blend, stats json, review renders).
#
# Coordinates: written in Roblox studs (X right, Y up, Z back; the front is -Z) and turned into Blender's Z-up
# space with a proper rotation (x, y, z) -> (x, -z, y), so left and right are never mirrored.
import bpy, bmesh, json, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = r"C:\Users\tristan\LihFolk-Vault-V2\skills\roblox-blender-modeling\scripts"
sys.path.append(SKILL)
try:
    import lihfolk_bpy as lf
except Exception:
    lf = None


def B(x, y, z=0.0):
    return Vector((x, -z, y))


# ---- the edge skeleton: (name, roblox position, skin radius x, skin radius y) --------------------------------
V = {}
E = []


def v(name, x, y, z, rx, ry=None):
    V[name] = (B(x, y, z), rx, ry if ry is not None else rx)


def e(a, b):
    E.append((a, b))


# F89 v2: a SLIM crash-test mannequin (not a bodybuilder): shoulders about 1.6x the head width, a defined waist,
# tapering limbs, the arms DOWN at the sides (about 5 degrees out, the elbows bent about 10 degrees, palms to the thighs).
# The legs keep the dummy's hip and knee positions (the physics skeleton); the arms are narrower than the physics arm
# parts, so SmoothBody V2 drives the bones forward-kinematically (rotations from the parts, lengths from this mesh).
v("pelvis", 0, -0.08, 0, 0.56, 0.36)
v("hipL", -0.36, -0.24, 0, 0.3, 0.32)
v("hipR", 0.36, -0.24, 0, 0.3, 0.32)
v("waist", 0, 0.32, 0, 0.47, 0.3)
v("belly", 0, 0.72, 0, 0.53, 0.32)
v("chest", 0, 1.08, -0.02, 0.6, 0.35)
v("upchest", 0, 1.36, 0, 0.6, 0.32)
v("neckbase", 0, 1.68, 0, 0.2, 0.19)
v("neck", 0, 2.0, 0, 0.17, 0.17)
SH = (0.7, 1.44)       # the shoulder ball
EL = (0.83, 0.84, -0.04)   # the elbow
WR = (0.9, 0.1, -0.17)     # the wrist (the forearm bent forward about 10 degrees)
for side, s in (("L", -1), ("R", 1)):
    v("clav" + side, 0.42 * s, 1.46, 0, 0.2, 0.2)
    v("shoulder" + side, SH[0] * s, SH[1], 0, 0.215, 0.215)
    v("uarm" + side, 0.77 * s, 1.14, -0.02, 0.2, 0.2)
    v("elbow" + side, EL[0] * s, EL[1], EL[2], 0.16, 0.16)
    v("farm" + side, 0.865 * s, 0.5, -0.1, 0.165, 0.16)
    v("wrist" + side, WR[0] * s, WR[1], WR[2], 0.13, 0.12)
    X = WR[0] * s
    Z0 = WR[2]
    # hand: the palm faces the thigh, the thumb in front (-Z)
    v("palm" + side, X, -0.08, Z0, 0.09, 0.2)
    v("knuck" + side, X, -0.26, Z0, 0.085, 0.2)
    for i, (z, ln) in enumerate(((-0.15, 1.0), (-0.05, 1.08), (0.05, 1.0), (0.15, 0.8))):
        y = -0.28
        prev = "knuck" + side
        for k, seg in enumerate((0.16, 0.12, 0.095)):
            y -= seg * ln
            n = "f%d%d%s" % (i, k, side)
            v(n, X - s * 0.012 * k, y, Z0 + z, 0.046 - 0.005 * k, 0.046 - 0.005 * k)
            if k == 0:
                v("fb%d%s" % (i, side), X, -0.28, Z0 + z, 0.05, 0.05)
                e(prev, "fb%d%s" % (i, side))
                prev = "fb%d%s" % (i, side)
            e(prev, n)
            prev = n
    v("thumb0" + side, X - s * 0.05, -0.06, Z0 - 0.17, 0.06, 0.06)
    v("thumb1" + side, X - s * 0.08, -0.18, Z0 - 0.25, 0.05, 0.05)
    v("thumb2" + side, X - s * 0.1, -0.28, Z0 - 0.29, 0.042, 0.042)
    # leg (the dummy's hip, knee and ankle)
    LX = 0.475 * s
    v("thigh" + side, LX, -0.6, 0, 0.29, 0.3)
    v("knee" + side, LX, -1.022, -0.02, 0.2, 0.21)
    v("calf" + side, LX, -1.36, 0.03, 0.21, 0.22)
    v("ankle" + side, LX, -1.9, 0, 0.13, 0.13)
    v("heel" + side, LX, -2.04, 0.16, 0.15, 0.13)
    v("toe" + side, LX, -2.08, -0.38, 0.17, 0.11)
    for a, b in (("clav", "shoulder"), ("shoulder", "uarm"), ("uarm", "elbow"), ("elbow", "farm"), ("farm", "wrist"),
                 ("wrist", "palm"), ("palm", "knuck"), ("palm", "thumb0"), ("thumb0", "thumb1"), ("thumb1", "thumb2"),
                 ("hip", "thigh"), ("thigh", "knee"), ("knee", "calf"), ("calf", "ankle"), ("ankle", "heel"), ("ankle", "toe")):
        e(a + side, b + side)
    e("upchest", "clav" + side)
    e("pelvis", "hip" + side)
for a, b in (("pelvis", "waist"), ("waist", "belly"), ("belly", "chest"), ("chest", "upchest"), ("upchest", "neckbase"), ("neckbase", "neck")):
    e(a, b)

# ---- scene ---------------------------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
if lf:
    lf.setup_scene()

names = list(V.keys())
index = {n: i for i, n in enumerate(names)}
me = bpy.data.meshes.new("MannequinBody")
me.from_pydata([V[n][0] for n in names], [(index[a], index[b]) for a, b in E], [])
me.update()
body = bpy.data.objects.new("MannequinBody", me)
bpy.context.scene.collection.objects.link(body)
skin = body.modifiers.new("Skin", "SKIN")
skin.use_smooth_shade = True
skin.branch_smoothing = 0.6
sv = me.skin_vertices[0].data
for n in names:
    _, rx, ry = V[n]
    # (the skin radius is in the vertex's local x/y; the torso depth runs along Blender Y)
    sv[index[n]].radius = (rx, ry)
sv[index["pelvis"]].use_root = True
sub = body.modifiers.new("Subsurf", "SUBSURF")
sub.levels = 2
sub.render_levels = 2
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.modifier_apply(modifier="Skin")
bpy.ops.object.modifier_apply(modifier="Subsurf")
sm = body.modifiers.new("Smooth", "SMOOTH")  # (F89: no lumps at the shoulders and elbows)
sm.factor = 0.6
sm.iterations = 6
bpy.ops.object.modifier_apply(modifier="Smooth")
tris = sum(len(p.vertices) - 2 for p in me.polygons)
if tris > 14000:
    dec = body.modifiers.new("Decimate", "DECIMATE")
    dec.ratio = 12000 / tris
    bpy.ops.object.modifier_apply(modifier="Decimate")
bpy.ops.object.shade_smooth()
mat = bpy.data.materials.new("DummyGrey")
mat.diffuse_color = (0.37, 0.37, 0.38, 1)  # grey plastic (163, 162, 165 sRGB)
me.materials.append(mat)

# ---- armature: R15 bone names at our dummy's joints ------------------------------------------------------------
arm_data = bpy.data.armatures.new("MannequinRig")
rig = bpy.data.objects.new("MannequinRig", arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_data.edit_bones


def bone(name, head, tail, parent=None, deform=True):
    b = eb.new(name)
    b.head = B(*head)
    b.tail = B(*tail)
    b.use_deform = deform
    if parent:
        b.parent = eb[parent]
    return b


bone("HumanoidRootPart", (0, -0.6, 0), (0, -0.1, 0), deform=False)
bone("LowerTorso", (0, -0.2, 0), (0, 0.2, 0), "HumanoidRootPart")
bone("UpperTorso", (0, 0.2, 0), (0, 1.8, 0), "LowerTorso")
bone("Head", (0, 1.8, 0), (0, 2.9, 0), "UpperTorso")
for side, s, P in (("L", -1, "Left"), ("R", 1, "Right")):
    bone(P + "UpperArm", (SH[0] * s, SH[1], 0), (EL[0] * s, EL[1], EL[2]), "UpperTorso")
    bone(P + "LowerArm", (EL[0] * s, EL[1], EL[2]), (WR[0] * s, WR[1], WR[2]), P + "UpperArm")
    bone(P + "Hand", (WR[0] * s, WR[1], WR[2]), (WR[0] * s, -0.26, WR[2]), P + "LowerArm")
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
    LX = 0.475 * s
    bone(P + "UpperLeg", (LX, -0.2, 0), (LX, -1.022, 0), "LowerTorso")
    bone(P + "LowerLeg", (LX, -1.022, 0), (LX, -1.9, 0), P + "UpperLeg")
    bone(P + "Foot", (LX, -1.9, 0), (LX, -2.08, -0.42), P + "LowerLeg")
bpy.ops.object.mode_set(mode="OBJECT")

bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")

# at most 4 influences per vertex, normalised (Roblox limit)
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(lock_active=False)
bpy.ops.object.mode_set(mode="OBJECT")

unweighted = sum(1 for vt in body.data.vertices if not vt.groups)
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
dims = body.dimensions

out = os.path.join(HERE, "mannequin_v2.fbx")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                         axis_forward="Z", axis_up="Y", add_leaf_bones=False, bake_anim=False,
                         use_mesh_modifiers=True, object_types={"ARMATURE", "MESH"})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "mannequin_v2.blend"))
stats = {"tris": tris, "bones": len(arm_data.bones), "unweighted_vertices": unweighted,
         "size_studs": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)], "fbx": out}
with open(os.path.join(HERE, "mannequin_v2_stats.json"), "w") as f:
    json.dump(stats, f, indent=1)
print("MANNEQUIN", json.dumps(stats))
if lf:
    try:
        lf.render_review(body, os.path.join(HERE, "review_v2"), size=512)
    except Exception as ex:
        print("render_review failed:", ex)
