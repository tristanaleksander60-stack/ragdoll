# A0 / row 13 (owner's answer 27 Nov: "Blender is installed, so A0 builds a RIGGED German Shepherd in Blender with real leg,
# tail, ear and jaw animation"). Run headless:
#   "C:\Program Files\Blender Foundation\Blender 5.3\blender.exe" -b --factory-startup --python art/models/dog/build_shepherd.py
# One smooth body from an edge skeleton (Skin + Subsurf, like the mannequin), tan with the black saddle, a black muzzle and
# dark ears painted as vertex colours and baked with AO into one colour map; a rig of named bones the game animates in code
# (Spine, Chest, Neck, Head, Jaw, EarL/R, FrontUpper/Lower/Paw L/R, RearUpper/Lower/Paw L/R, Tail1-3), at most 4
# influences a vertex. Output: shepherd.fbx, shepherd_color.png, .blend, stats json, review renders (review/).
# Roblox coordinates (X right, Y up, Z back; the nose points to -Z), turned to Blender by (x, y, z) -> (x, -z, y).
import bpy, json, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))


def B(x, y, z=0.0):
    return Vector((x, -z, y))


TAN = (0.62, 0.40, 0.18, 1.0)
DARK = (0.06, 0.05, 0.05, 1.0)
CREAM = (0.80, 0.62, 0.36, 1.0)

V, E = {}, []


def v(n, x, y, z, rx, ry=None):
    V[n] = (B(x, y, z), rx, ry if ry is not None else rx)


def e(a, b):
    E.append((a, b))


# body (sturdy: a deep chest, a strong neck, a big head; legs shorter than the body is long)
v("hips", 0, 1.95, 1.25, 0.6, 0.65)
v("belly", 0, 1.85, 0.05, 0.58, 0.62)
v("chest", 0, 1.9, -1.1, 0.72, 0.85)
v("withers", 0, 2.25, -1.5, 0.55, 0.58)
v("neck", 0, 2.75, -1.95, 0.42, 0.44)
v("head", 0, 3.15, -2.3, 0.5, 0.5)
v("snout", 0, 2.95, -2.95, 0.25, 0.26)
v("nose", 0, 2.93, -3.25, 0.14, 0.14)
v("jaw", 0, 2.72, -2.85, 0.17, 0.14)
for a, b in (("hips", "belly"), ("belly", "chest"), ("chest", "withers"), ("withers", "neck"), ("neck", "head"), ("head", "snout"), ("snout", "nose"), ("head", "jaw")):
    e(a, b)
for side, s in (("L", -1), ("R", 1)):
    v("ear0" + side, 0.28 * s, 3.6, -2.2, 0.17, 0.1)
    v("ear1" + side, 0.36 * s, 4.1, -2.12, 0.05, 0.04)
    e("head", "ear0" + side)
    e("ear0" + side, "ear1" + side)
    # front leg
    v("fs" + side, 0.42 * s, 1.65, -1.25, 0.3)
    v("fe" + side, 0.44 * s, 1.0, -1.2, 0.21)
    v("fw" + side, 0.44 * s, 0.4, -1.25, 0.15)
    v("fp" + side, 0.44 * s, 0.13, -1.45, 0.18, 0.11)
    for a, b in (("chest", "fs"), ("fs", "fe"), ("fe", "fw"), ("fw", "fp")):
        e(a if a == "chest" else a + side, b + side)
    # rear leg: the shepherd's angled hind leg (the stifle forward, the hock back)
    v("rh" + side, 0.42 * s, 1.7, 1.2, 0.36)
    v("rk" + side, 0.44 * s, 1.1, 1.05, 0.25)
    v("rk2" + side, 0.44 * s, 0.55, 1.75, 0.16)
    v("rp" + side, 0.44 * s, 0.13, 1.6, 0.18, 0.11)
    for a, b in (("hips", "rh"), ("rh", "rk"), ("rk", "rk2"), ("rk2", "rp")):
        e(a if a == "hips" else a + side, b + side)
v("t1", 0, 2.1, 1.85, 0.17)
v("t2", 0, 1.75, 2.5, 0.15)
v("t3", 0, 1.3, 2.95, 0.09)
for a, b in (("hips", "t1"), ("t1", "t2"), ("t2", "t3")):
    e(a, b)

bpy.ops.wm.read_factory_settings(use_empty=True)
names = list(V.keys())
idx = {n: i for i, n in enumerate(names)}
me = bpy.data.meshes.new("Shepherd")
me.from_pydata([V[n][0] for n in names], [(idx[a], idx[b]) for a, b in E], [])
me.update()
body = bpy.data.objects.new("Shepherd", me)
bpy.context.scene.collection.objects.link(body)
sk = body.modifiers.new("Skin", "SKIN")
sk.use_smooth_shade = True
sk.branch_smoothing = 0.8
sv = me.skin_vertices[0].data
for n in names:
    sv[idx[n]].radius = (V[n][1], V[n][2])
sv[idx["belly"]].use_root = True
sub = body.modifiers.new("Sub", "SUBSURF")
sub.levels = 2
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.modifier_apply(modifier="Skin")
bpy.ops.object.modifier_apply(modifier="Sub")
sm = body.modifiers.new("Smooth", "SMOOTH")
sm.factor = 0.5
sm.iterations = 4
bpy.ops.object.modifier_apply(modifier="Smooth")
tris = sum(len(p.vertices) - 2 for p in me.polygons)
if tris > 9500:
    d = body.modifiers.new("Dec", "DECIMATE")
    d.ratio = 9500 / tris
    bpy.ops.object.modifier_apply(modifier="Dec")
bpy.ops.object.shade_smooth()

# colours: tan, the black saddle over the back, a black muzzle, dark ears, a lighter chest and legs' inside
col = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
for poly in me.polygons:
    for li in poly.loop_indices:
        p = me.vertices[me.loops[li].vertex_index].co
        x, y, z = p.x, p.z, -p.y  # Roblox coords
        c = TAN
        if y > 2.05 and -1.7 < z < 1.95:
            c = DARK  # the saddle
        if z < -2.65 and y > 2.7:
            c = DARK  # the muzzle
        if y > 3.45:
            c = DARK  # the ears
        if y < 1.75 and -1.6 < z < -0.7 and abs(x) < 0.35:
            c = CREAM  # the chest
        if z > 2.45 and y < 1.75:
            c = DARK  # the tail tip
        col.data[li].color = c

# rig
arm = bpy.data.armatures.new("ShepherdRig")
rig = bpy.data.objects.new("ShepherdRig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.edit_bones


def bone(n, a, b, parent=None, deform=True):
    x = eb.new(n)
    x.head, x.tail, x.use_deform = V[a][0] if isinstance(a, str) else B(*a), V[b][0] if isinstance(b, str) else B(*b), deform
    if parent:
        x.parent = eb[parent]
    return x


bone("Root", (0, 0, 0), (0, 0.5, 0), deform=False)
bone("Spine", "hips", "belly", "Root")
bone("Chest", "belly", "withers", "Spine")
bone("Neck", "withers", "neck", "Chest")
bone("Head", "neck", "head", "Neck")
bone("Muzzle", "head", "nose", "Head")
bone("Jaw", "head", "jaw", "Head")
for side in ("L", "R"):
    bone("Ear" + side, "ear0" + side, "ear1" + side, "Head")
    bone("FrontUpper" + side, "fs" + side, "fe" + side, "Chest")
    bone("FrontLower" + side, "fe" + side, "fw" + side, "FrontUpper" + side)
    bone("FrontPaw" + side, "fw" + side, "fp" + side, "FrontLower" + side)
    bone("RearUpper" + side, "rh" + side, "rk" + side, "Spine")
    bone("RearLower" + side, "rk" + side, "rk2" + side, "RearUpper" + side)
    bone("RearPaw" + side, "rk2" + side, "rp" + side, "RearLower" + side)
bone("Tail1", "hips", "t1", "Spine")
bone("Tail2", "t1", "t2", "Tail1")
bone("Tail3", "t2", "t3", "Tail2")
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

# UVs and the colour bake (vertex colour x AO)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.006)
bpy.ops.object.mode_set(mode="OBJECT")
img = bpy.data.images.new("shepherd_color", 1024, 1024)
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
ao.inputs["Distance"].default_value = 0.3
mx = nt.nodes.new("ShaderNodeMix")
mx.data_type = "RGBA"
mx.blend_type = "MULTIPLY"
mx.inputs["Factor"].default_value = 0.5
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
baked = True
try:
    bpy.ops.object.bake(type="EMIT", margin=6)
    img.filepath_raw = os.path.join(HERE, "shepherd_color.png")
    img.file_format = "PNG"
    img.save()
except Exception as ex:
    baked = False
    print("bake failed", ex)
plain = bpy.data.materials.new("ShepherdPlastic")
me.materials.clear()
me.materials.append(plain)

tris = sum(len(p.vertices) - 2 for p in me.polygons)
out = os.path.join(HERE, "shepherd.fbx")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
                         add_leaf_bones=False, bake_anim=False, use_mesh_modifiers=True, object_types={"ARMATURE", "MESH"})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "shepherd.blend"))
dims = body.dimensions
stats = {"tris": tris, "bones": len(arm.bones), "baked": baked, "size_studs": [round(dims.x, 2), round(dims.z, 2), round(dims.y, 2)]}
json.dump(stats, open(os.path.join(HERE, "shepherd_stats.json"), "w"), indent=1)
print("SHEPHERD", json.dumps(stats))

# review renders (the baked colours on a plain material)
try:
    rm = bpy.data.materials.new("Review")
    rm.use_nodes = True
    bsdf = rm.node_tree.nodes.get("Principled BSDF")
    t2 = rm.node_tree.nodes.new("ShaderNodeTexImage")
    t2.image = img
    rm.node_tree.links.new(t2.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.7
    me.materials.clear()
    me.materials.append(rm)
    w = bpy.data.worlds.new("W")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.8, 0.82, 0.85, 1)
    bpy.ops.object.light_add(type="SUN", location=(3, -4, 6))
    bpy.context.active_object.data.energy = 3
    cd = bpy.data.cameras.new("C")
    cam = bpy.data.objects.new("C", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sc.render.resolution_x = sc.render.resolution_y = 640
    sc.cycles.samples = 24
    rd = os.path.join(HERE, "review")
    os.makedirs(rd, exist_ok=True)
    for nm, ang in (("side", 90), ("three_quarter", 140), ("front", 180)):
        a = math.radians(ang)
        cam.location = Vector((9 * math.sin(a), 9 * math.cos(a), 2.2))
        d = Vector((0, 0, 1.8)) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(rd, nm + ".png")
        bpy.ops.render.render(write_still=True)
except Exception as ex:
    print("review failed", ex)
