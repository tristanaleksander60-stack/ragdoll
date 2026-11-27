# RAGDOLL_10 "THE LOOK 10/10": the v3 body, a CHUNKY TOY CRASH-TEST DUMMY (owner 27 Nov: "Gør dem tykkere, så der er mere
# at skyde på og giv dem lidt mere liv"). Run headless:
#   "C:\Program Files\Blender Foundation\Blender 5.3\blender.exe" -b --factory-startup --python art/models/mannequin/build_mannequin_v3.py
# Like v2 (Skin modifier on an edge skeleton, R15 bone names, arms down), but:
#   - thick, toy-like proportions (chest 2.0 x 1.0, waist 1.6, hips 1.8, upper arm 0.66, forearm 0.56, thigh 0.85,
#     calf 0.66, big hands with chunky fingers, boot-like feet with a sole), the arms hanging free of the body;
#   - Hybrid III style JOINT RINGS (neck, shoulders, elbows, wrists, hips, knees, ankles), each 100 % on its joint's bone;
#   - a rounded CHEST PLATE with bolts;
#   - the black-and-yellow quarter-circle MARKINGS on the chest plate and the outsides of the knees and the upper arms,
#     painted as vertex colours and baked with ambient occlusion into one 1024 px colour map (mannequin_v3_color.png);
#   - one smart-UV map, at most 4 bone influences a vertex, about 12k triangles.
# No head: the dummy keeps its own Head part with the living faces (R2).
# Output: mannequin_v3.fbx, mannequin_v3_color.png, .blend, stats json, review renders (review_v3/).
# Coordinates in Roblox studs (X right, Y up, Z back; front -Z), turned into Blender Z-up by (x, y, z) -> (x, -z, y).
import bpy, bmesh, json, math, os, sys
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = r"C:\Users\tristan\LihFolk-Vault-V2\skills\roblox-blender-modeling\scripts"
sys.path.append(SKILL)
try:
    import lihfolk_bpy as lf
except Exception:
    lf = None


def B(x, y, z=0.0):
    return Vector((x, -z, y))


GREY = (0.37, 0.37, 0.38, 1.0)       # toy plastic (163, 162, 165 sRGB)
RING = (0.13, 0.13, 0.14, 1.0)       # the joint rings: dark rubber
PLATE = (0.46, 0.46, 0.47, 1.0)      # the chest plate a shade lighter
YELLOW = (0.95, 0.72, 0.02, 1.0)
BLACK = (0.02, 0.02, 0.02, 1.0)
BOLT = (0.22, 0.22, 0.23, 1.0)

V = {}
E = []


def v(name, x, y, z, rx, ry=None):
    V[name] = (B(x, y, z), rx, ry if ry is not None else rx)


def e(a, b):
    E.append((a, b))


# ---- the chunky skeleton (studs) ----------------------------------------------------------------------------
v("pelvis", 0, -0.08, 0, 0.88, 0.5)
v("hipL", -0.48, -0.26, 0, 0.44, 0.44)
v("hipR", 0.48, -0.26, 0, 0.44, 0.44)
v("waist", 0, 0.32, 0, 0.8, 0.46)
v("belly", 0, 0.72, 0, 0.88, 0.5)
v("chest", 0, 1.08, -0.02, 1.0, 0.52)
v("upchest", 0, 1.36, 0, 0.98, 0.48)
v("neckbase", 0, 1.68, 0, 0.3, 0.28)
v("neck", 0, 2.0, 0, 0.26, 0.26)
SH = (1.24, 1.42)               # the shoulder ball: far enough out that the thick arm hangs free of the chest
EL = (1.36, 0.82, -0.04)        # the elbow
WR = (1.42, 0.06, -0.17)        # the wrist (forearm bent forward about 10 degrees)
for side, s in (("L", -1), ("R", 1)):
    v("clav" + side, 0.78 * s, 1.48, 0, 0.32, 0.3)
    v("shoulder" + side, SH[0] * s, SH[1], 0, 0.36, 0.36)
    v("uarm" + side, 1.3 * s, 1.12, -0.02, 0.33, 0.33)
    v("elbow" + side, EL[0] * s, EL[1], EL[2], 0.28, 0.28)
    v("farm" + side, 1.39 * s, 0.46, -0.1, 0.28, 0.27)
    v("wrist" + side, WR[0] * s, WR[1], WR[2], 0.22, 0.2)
    X = WR[0] * s
    Z0 = WR[2]
    # a big friendly hand: the palm faces the thigh, chunky fingers, the thumb in front (-Z)
    v("palm" + side, X, -0.14, Z0, 0.15, 0.3)
    v("knuck" + side, X, -0.36, Z0, 0.14, 0.3)
    for i, (z, ln) in enumerate(((-0.22, 1.0), (-0.075, 1.08), (0.075, 1.0), (0.22, 0.82))):
        y = -0.38
        prev = "knuck" + side
        for k, seg in enumerate((0.19, 0.14, 0.11)):
            y -= seg * ln
            n = "f%d%d%s" % (i, k, side)
            v(n, X - s * 0.015 * k, y, Z0 + z, 0.072 - 0.006 * k, 0.072 - 0.006 * k)
            if k == 0:
                v("fb%d%s" % (i, side), X, -0.38, Z0 + z, 0.078, 0.078)
                e(prev, "fb%d%s" % (i, side))
                prev = "fb%d%s" % (i, side)
            e(prev, n)
            prev = n
    v("thumb0" + side, X - s * 0.08, -0.1, Z0 - 0.24, 0.09, 0.09)
    v("thumb1" + side, X - s * 0.12, -0.24, Z0 - 0.34, 0.075, 0.075)
    v("thumb2" + side, X - s * 0.14, -0.36, Z0 - 0.4, 0.065, 0.065)
    LX = 0.5 * s
    v("thigh" + side, LX, -0.6, 0, 0.43, 0.43)
    v("knee" + side, LX, -1.022, -0.02, 0.34, 0.35)
    v("calf" + side, LX, -1.36, 0.03, 0.34, 0.35)
    v("ankle" + side, LX, -1.86, 0, 0.24, 0.24)
    v("heel" + side, LX, -2.02, 0.2, 0.25, 0.2)
    v("toe" + side, LX, -2.04, -0.5, 0.27, 0.17)
    for a, b in (("clav", "shoulder"), ("shoulder", "uarm"), ("uarm", "elbow"), ("elbow", "farm"), ("farm", "wrist"),
                 ("wrist", "palm"), ("palm", "knuck"), ("palm", "thumb0"), ("thumb0", "thumb1"), ("thumb1", "thumb2"),
                 ("hip", "thigh"), ("thigh", "knee"), ("knee", "calf"), ("calf", "ankle"), ("ankle", "heel"), ("ankle", "toe")):
        e(a + side, b + side)
    e("upchest", "clav" + side)
    e("pelvis", "hip" + side)
for a, b in (("pelvis", "waist"), ("waist", "belly"), ("belly", "chest"), ("chest", "upchest"), ("upchest", "neckbase"), ("neckbase", "neck")):
    e(a, b)

# ---- scene: the body -------------------------------------------------------------------------------------------
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
skin.branch_smoothing = 0.7
sv = me.skin_vertices[0].data
for n in names:
    _, rx, ry = V[n]
    sv[index[n]].radius = (rx, ry)
sv[index["pelvis"]].use_root = True
sub = body.modifiers.new("Subsurf", "SUBSURF")
sub.levels = 2
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.modifier_apply(modifier="Skin")
bpy.ops.object.modifier_apply(modifier="Subsurf")
sm = body.modifiers.new("Smooth", "SMOOTH")
sm.factor = 0.55
sm.iterations = 5
bpy.ops.object.modifier_apply(modifier="Smooth")
tris = sum(len(p.vertices) - 2 for p in me.polygons)
if tris > 6500:
    dec = body.modifiers.new("Decimate", "DECIMATE")
    dec.ratio = 6500 / tris
    bpy.ops.object.modifier_apply(modifier="Decimate")
bpy.ops.object.shade_smooth()

# ---- the parts that go on it: rings, the chest plate, bolts ---------------------------------------------------
extras = []  # (object, bone it follows 100 %, colour)


def ring(name, at, axis, major, minor, bone_name):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=22, minor_segments=6,
                                     location=B(*at))
    o = bpy.context.active_object
    o.name = name
    up = Vector((0, 0, 1))
    ax = B(*axis).normalized() if B(*axis).length > 0 else up
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = up.rotation_difference(ax)
    extras.append((o, bone_name, RING))
    return o


def bolt(name, at, bone_name, r=0.05):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=10, ring_count=6, location=B(*at))
    o = bpy.context.active_object
    o.name = name
    o.scale = (1, 1, 0.6)
    extras.append((o, bone_name, BOLT))
    return o


ring("RingNeck", (0, 1.86, 0), (0, 1, 0), 0.3, 0.07, "UpperTorso")
for side, s, P in (("L", -1, "Left"), ("R", 1, "Right")):
    ring("RingShoulder" + side, (1.03 * s, 1.43, 0), (1, 0, 0), 0.34, 0.08, P + "UpperArm")
    ring("RingElbow" + side, (EL[0] * s, EL[1], EL[2]), (0.08 * s, 1, 0), 0.29, 0.07, P + "LowerArm")
    ring("RingWrist" + side, (WR[0] * s, WR[1] + 0.06, WR[2]), (0.05 * s, 1, 0), 0.22, 0.055, P + "Hand")
    ring("RingHip" + side, (0.5 * s, -0.46, 0), (0, 1, 0), 0.45, 0.075, P + "UpperLeg")
    ring("RingKnee" + side, (0.5 * s, -1.022, -0.02), (0, 1, 0), 0.36, 0.08, P + "LowerLeg")
    ring("RingAnkle" + side, (0.5 * s, -1.8, 0), (0, 1, 0), 0.25, 0.06, P + "Foot")
    # the boot sole
    bpy.ops.mesh.primitive_cube_add(size=1, location=B(0.5 * s, -2.1, -0.14))
    sole = bpy.context.active_object
    sole.name = "Sole" + side
    sole.scale = (0.52, 0.9, 0.1)
    bev = sole.modifiers.new("Bevel", "BEVEL")
    bev.width = 0.05
    bev.segments = 2
    extras.append((sole, P + "Foot", RING))

# the chest plate: a flattened rounded slab on the front of the chest
bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=64, ring_count=32, location=B(0, 1.1, -0.5))
plate = bpy.context.active_object
plate.name = "ChestPlate"
plate.scale = (0.8, 0.2, 0.52)   # (x wide, Blender y = depth, z = height)
extras.append((plate, "UpperTorso", PLATE))
for k, (bx, by) in enumerate(((-0.56, 1.36), (0.56, 1.36), (-0.56, 0.84), (0.56, 0.84))):
    bolt("PlateBolt%d" % k, (bx, by, -0.66), "UpperTorso")

bpy.ops.object.select_all(action="DESELECT")
for o, _, _ in extras:
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o, _, _ in extras:
    for m in list(o.modifiers):
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.shade_smooth()

# ---- vertex colours: grey body, then the markings ------------------------------------------------------------
def paint(obj, base, marks=()):
    m = obj.data
    if not m.color_attributes:
        m.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
    col = m.color_attributes["Col"]
    mw = obj.matrix_world
    for poly in m.polygons:
        for li in poly.loop_indices:
            vi = m.loops[li].vertex_index
            p = mw @ m.vertices[vi].co
            c = base
            for (cx, cy, cz, r, facing) in marks:
                # Roblox coords of p
                rx, ry, rz = p.x, p.z, -p.y
                d = Vector((rx - cx, ry - cy, rz - cz))
                if d.length < r and m.vertices[vi].normal.dot(B(*facing).normalized()) > 0.2:
                    # a quarter-circle target: the plane across the facing direction split in four
                    fx = Vector(B(*facing)).normalized()
                    upv = Vector((0, 0, 1))
                    right = fx.cross(upv)
                    if right.length < 1e-3:
                        right = Vector((1, 0, 0))
                    right.normalize()
                    pd = B(rx - cx, ry - cy, rz - cz)
                    a = pd.dot(right)
                    b = pd.dot(upv)
                    if d.length > r * 0.86:
                        c = BLACK
                    else:
                        c = YELLOW if (a >= 0) == (b >= 0) else BLACK
            col.data[li].color = c


KNEE_MARK = 0.3
markings_body = []
for s in (-1, 1):
    markings_body.append((0.5 * s + 0.3 * s, -1.0, 0.0, KNEE_MARK, (s, 0, 0)))      # the outside of each knee
    markings_body.append((1.3 * s + 0.33 * s, 1.12, -0.02, 0.26, (s, 0, 0)))          # the outside of each upper arm
paint(body, GREY, markings_body)
for o, bn, c in extras:
    if o.name == "ChestPlate":
        paint(o, c, [(0, 1.1, -0.7, 0.34, (0, 0, -1))])
    else:
        paint(o, c)

# ---- join into one mesh, remembering which vertices are rings/plates (they follow one bone 100 %) ------------
for o, bn, _ in extras:
    vg = o.vertex_groups.new(name="RIGID_" + bn)
    vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
bpy.ops.object.select_all(action="DESELECT")
for o, _, _ in extras:
    o.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
me = body.data

# ---- armature (R15 names, the same layout as v2 but at v3's shoulders/elbows/wrists) --------------------------
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
    bone(P + "Hand", (WR[0] * s, WR[1], WR[2]), (WR[0] * s, -0.36, WR[2]), P + "LowerArm")
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
    bone(P + "LowerLeg", (LX, -1.022, 0), (LX, -1.86, 0), P + "UpperLeg")
    bone(P + "Foot", (LX, -1.86, 0), (LX, -2.04, -0.52), P + "LowerLeg")
bpy.ops.object.mode_set(mode="OBJECT")

bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")

# the rigid parts: 100 % on their bone (the rings never smear across a joint)
rigid = [g for g in body.vertex_groups if g.name.startswith("RIGID_")]
for g in rigid:
    bn = g.name[len("RIGID_"):]
    target = body.vertex_groups.get(bn) or body.vertex_groups.new(name=bn)
    for vt in body.data.vertices:
        inside = any(gg.group == g.index for gg in vt.groups)
        if inside:
            for gg in list(vt.groups):
                grp = body.vertex_groups[gg.group]
                if grp.name != bn and not grp.name.startswith("RIGID_"):
                    grp.remove([vt.index])
            target.add([vt.index], 1.0, "REPLACE")
for g in rigid:
    body.vertex_groups.remove(g)

bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(lock_active=False)
bpy.ops.object.mode_set(mode="OBJECT")

# ---- UVs and the colour bake (vertex colours x ambient occlusion) ---------------------------------------------
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.006)
bpy.ops.object.mode_set(mode="OBJECT")

img = bpy.data.images.new("mannequin_v3_color", 1024, 1024)
mat = bpy.data.materials.new("DummyV3")
mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
outn = nt.nodes.new("ShaderNodeOutputMaterial")
emit = nt.nodes.new("ShaderNodeEmission")
colattr = nt.nodes.new("ShaderNodeVertexColor")
colattr.layer_name = "Col"
ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
ao.inputs["Distance"].default_value = 0.35
mix = nt.nodes.new("ShaderNodeMix")
mix.data_type = "RGBA"
mix.blend_type = "MULTIPLY"
mix.inputs["Factor"].default_value = 0.55
nt.links.new(colattr.outputs["Color"], mix.inputs["A"])
nt.links.new(ao.outputs["AO"], mix.inputs["B"])
nt.links.new(mix.outputs["Result"], emit.inputs["Color"])
nt.links.new(emit.outputs["Emission"], outn.inputs["Surface"])
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = img
nt.nodes.active = tex
body.data.materials.clear()
body.data.materials.append(mat)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.device = "CPU"
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
baked = True
try:
    bpy.ops.object.bake(type="EMIT", margin=6)
    img.filepath_raw = os.path.join(HERE, "mannequin_v3_color.png")
    img.file_format = "PNG"
    img.save()
except Exception as ex:
    baked = False
    print("bake failed:", ex)

# a plain material for the export (Roblox gets the colour map as a SurfaceAppearance)
mat2 = bpy.data.materials.new("DummyV3Plastic")
mat2.diffuse_color = GREY
body.data.materials.clear()
body.data.materials.append(mat2)

unweighted = sum(1 for vt in body.data.vertices if not vt.groups)
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
dims = body.dimensions
out = os.path.join(HERE, "mannequin_v3.fbx")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                         axis_forward="Z", axis_up="Y", add_leaf_bones=False, bake_anim=False,
                         use_mesh_modifiers=True, object_types={"ARMATURE", "MESH"}, colors_type="SRGB")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "mannequin_v3.blend"))
stats = {"tris": tris, "bones": len(arm_data.bones), "unweighted_vertices": unweighted, "baked": baked,
         "size_studs": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)], "fbx": out}
with open(os.path.join(HERE, "mannequin_v3_stats.json"), "w") as f:
    json.dump(stats, f, indent=1)
print("MANNEQUIN", json.dumps(stats))

# ---- review renders with the baked colours ---------------------------------------------------------------------
try:
    rmat = bpy.data.materials.new("Review")
    rmat.use_nodes = True
    rn = rmat.node_tree
    bsdf = rn.nodes.get("Principled BSDF")
    t2 = rn.nodes.new("ShaderNodeTexImage")
    t2.image = img
    rn.links.new(t2.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.5
    body.data.materials.clear()
    body.data.materials.append(rmat)
    rdir = os.path.join(HERE, "review_v3")
    os.makedirs(rdir, exist_ok=True)
    world = bpy.data.worlds.new("W")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.8, 0.82, 0.85, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    bpy.ops.object.light_add(type="SUN", location=(3, -4, 6))
    bpy.context.active_object.data.energy = 3
    cam_data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.cycles.samples = 24
    for nm, ang in (("front", 0), ("three_quarter", 35), ("side", 90), ("back", 180)):
        a = math.radians(ang + 180)  # (the front is Blender +Y)
        cam.location = Vector((9 * math.sin(a), -9 * math.cos(a), 0.0))
        d = Vector((0, 0, -0.1)) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cam_data.lens = 50
        scene.render.filepath = os.path.join(rdir, nm + ".png")
        bpy.ops.render.render(write_still=True)
except Exception as ex:
    print("review failed:", ex)

# ---- the gate renders: knocked down, and next to a player-sized figure ------------------------------------------
try:
    rdir = os.path.join(HERE, "review_v3")
    # next to the player: a plain R15-sized stand-in (about 5.2 studs, blocky) one body-width to the side
    bpy.ops.mesh.primitive_cube_add(size=1, location=B(3.2, -0.3, 0))
    ref = bpy.context.active_object
    ref.name = "PlayerSizeRef"
    ref.scale = (2.0, 1.0, 5.2)
    refm = bpy.data.materials.new("Ref")
    refm.diffuse_color = (0.15, 0.35, 0.8, 1)
    ref.data.materials.append(refm)
    a = math.radians(200)
    cam.location = Vector((11 * math.sin(a) + 1.6, -11 * math.cos(a), 0.2))
    d = Vector((1.6, 0, -0.2)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(rdir, "next_to_player.png")
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(ref)
    # knocked down: lying on its back, limbs splayed (posed on the armature)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    pb = rig.pose.bones
    def turn(name, x=0, y=0, z=0):
        b = pb.get(name)
        if b:
            b.rotation_mode = "XYZ"
            b.rotation_euler = (math.radians(x), math.radians(y), math.radians(z))
    turn("LeftUpperArm", 0, 0, 0)
    for nm in ("LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "RightLowerLeg", "LeftLowerArm"):
        b = pb.get(nm)
        if b:
            b.rotation_mode = "XYZ"
    # (bone-local axes, found from posed_front.png: X swings a limb out to the side for these down-pointing bones)
    pb["LeftUpperArm"].rotation_euler = (0, 0, math.radians(65))
    pb["RightUpperArm"].rotation_euler = (0, 0, math.radians(-75))
    pb["LeftLowerArm"].rotation_euler = (math.radians(-25), 0, 0)
    pb["LeftUpperLeg"].rotation_euler = (0, 0, math.radians(18))
    pb["RightUpperLeg"].rotation_euler = (0, 0, math.radians(-22))
    pb["RightLowerLeg"].rotation_euler = (math.radians(40), 0, 0)
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.rotation_euler = (math.radians(90), 0, math.radians(20))
    rig.location = (0, 0, -1.6)
    cam.location = Vector((0.5, 1.0, 9))
    d = Vector((0, 0, -1.6)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(rdir, "knocked_down.png")
    bpy.ops.render.render(write_still=True)
    # the same pose standing, seen from the front: do the rings and the plate stay on their joints?
    rig.rotation_euler = (0, 0, 0)
    rig.location = (0, 0, 0)
    cam.location = Vector((0, 9, 0))
    d = Vector((0, 0, -0.1)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(rdir, "posed_front.png")
    bpy.ops.render.render(write_still=True)
except Exception as ex:
    print("gate renders failed:", ex)
