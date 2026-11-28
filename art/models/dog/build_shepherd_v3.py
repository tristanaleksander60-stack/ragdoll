# DOG3 (v3, the 7 review points) on top of A0 / row 13 (owner's answer 27 Nov: "Blender is installed, so A0 builds a RIGGED German Shepherd in Blender with real leg,
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


# body, v3 (DOG3, the cloud's review): a deeper and broader chest, a SHORT THICK neck, a longer crisp muzzle, real hind
# legs with a hock (stifle forward, hock back, a near-vertical metatarsus), flat paws with toe pads, a long bushy tail.
v("hips", 0, 2.1, 1.2, 0.62, 0.62)
v("loin", 0, 2.1, 0.5, 0.5, 0.47)   # the tucked waist
v("belly", 0, 1.95, -0.15, 0.6, 0.66)
v("chest", 0, 2.0, -0.95, 0.82, 0.82)
v("brisket", 0, 1.4, -1.05, 0.6, 0.6)   # the deep chest, down between the front legs
v("withers", 0, 2.45, -1.35, 0.62, 0.66)
v("neck", 0, 2.85, -1.72, 0.6, 0.6)   # short and thick
v("head", 0, 3.15, -2.1, 0.5, 0.52)
v("cheek", 0, 2.95, -2.5, 0.38, 0.36)
v("snout", 0, 2.85, -3.0, 0.25, 0.26)
v("nose", 0, 2.86, -3.5, 0.16, 0.15)
v("jaw", 0, 2.62, -3.05, 0.16, 0.12)
for a, b in (("hips", "loin"), ("loin", "belly"), ("belly", "chest"), ("chest", "brisket"), ("chest", "withers"), ("withers", "neck"), ("neck", "head"), ("head", "cheek"), ("cheek", "snout"), ("snout", "nose"), ("cheek", "jaw")):
    e(a, b)
for side, s in (("L", -1), ("R", 1)):
    v("ear0" + side, 0.28 * s, 3.5, -2.0, 0.22, 0.22)
    v("earm" + side, 0.34 * s, 3.9, -1.95, 0.15, 0.15)
    v("ear1" + side, 0.4 * s, 4.3, -1.9, 0.08, 0.08)
    e("head", "ear0" + side)
    e("ear0" + side, "earm" + side)
    e("earm" + side, "ear1" + side)
    # front leg: straight, a flat paw
    v("fs" + side, 0.42 * s, 1.9, -1.25, 0.42)
    v("fe" + side, 0.45 * s, 1.05, -1.2, 0.27)
    v("fw" + side, 0.45 * s, 0.42, -1.2, 0.2)
    v("fp" + side, 0.45 * s, 0.12, -1.4, 0.22, 0.13)
    for a, b in (("withers", "fs"), ("fs", "fe"), ("fe", "fw"), ("fw", "fp")):
        e(a if a == "withers" else a + side, b + side)
    # rear leg: the thick thigh, the STIFLE forward, the HOCK back, a near-vertical metatarsus, a flat paw
    v("rh" + side, 0.42 * s, 1.85, 1.15, 0.5)
    v("rk" + side, 0.45 * s, 1.2, 0.72, 0.3)   # the stifle, well forward
    v("rk2" + side, 0.45 * s, 0.75, 1.78, 0.17)   # the hock, well back and up: the dog's hind-leg Z
    v("rp" + side, 0.45 * s, 0.12, 1.55, 0.21, 0.12)
    for a, b in (("hips", "rh"), ("rh", "rk"), ("rk", "rk2"), ("rk2", "rp")):
        e(a if a == "hips" else a + side, b + side)
v("t1", 0, 2.1, 1.75, 0.24)
v("t2", 0, 1.55, 2.3, 0.27)
v("t3", 0, 0.85, 2.6, 0.2)
for a, b in (("hips", "t1"), ("t1", "t2"), ("t2", "t3")):
    e(a, b)

# ---- the body: ONE smooth signed-distance shape (the LihFolk creature tool: smooth-union round cones along the
# skeleton's edges + ellipsoids for the deep chest, the haunch and the head), meshed by surface nets, a voxel remesh
# and QuadriFlow, exactly X-symmetric. (The Skin modifier gave a balloon look with flat patches; rejected.)
sys.path.append("C:/Users/tristan/LihFolk-Vault-V2/skills/roblox-blender-modeling/scripts")
import lihfolk_creature as lcr

bpy.ops.wm.read_factory_settings(use_empty=True)
parts = []
for i, (a_, b_) in enumerate(E):
    pa, pb = V[a_][0], V[b_][0]
    if pa.x < -1e-4 or pb.x < -1e-4:
        continue  # the left side is the field's own mirror
    ra, rb = (V[a_][1] + V[a_][2]) / 2, (V[b_][1] + V[b_][2]) / 2
    ear = a_.startswith("ear") or b_.startswith("ear")
    parts.append({"name": "e%d" % i, "type": "cone", "a": list(pa), "b": list(pb), "r": [ra, rb], "k": 0.05 if ear else 0.16})


def ell(name, c, r, k=0.25):
    parts.append({"name": name, "type": "ellipsoid", "c": list(B(*c)), "r": [r[0], r[2], r[1]], "k": k})


ell("ribcage", (0, 1.85, -0.85), (0.78, 0.9, 1.1))  # the deep, broad chest (down to the elbows)
ell("haunch", (0.3, 1.9, 1.1), (0.34, 0.5, 0.52))  # the rear thighs (smaller in v3: the hock angle shows)
ell("shoulderblade", (0.32, 2.05, -1.2), (0.32, 0.52, 0.45))
ell("skull", (0, 3.15, -2.15), (0.47, 0.44, 0.48), 0.2)
ell("nosetip", (0, 2.87, -3.52), (0.14, 0.11, 0.1), 0.06)
ell("tailbrush", (0, 1.45, 2.35), (0.26, 0.4, 0.3), 0.2)  # the bushy middle of the tail
for px, pz in ((0.45, -1.4), (0.45, 1.55)):
    for tx in (-0.1, 0.1):
        ell("toe%.2f%.2f%.2f" % (px, pz, tx), (px + tx, 0.11, pz - 0.2), (0.09, 0.08, 0.11), 0.05)  # toe pads
    ell("toeout%.2f%.2f" % (px, pz), (px + 0.2, 0.11, pz - 0.12), (0.08, 0.075, 0.1), 0.05)
    ell("toein%.2f%.2f" % (px, pz), (px - 0.2, 0.11, pz - 0.12), (0.08, 0.075, 0.1), 0.05)
spec = lcr._merge({"name": "Shepherd", "tris": 9000, "grid": 0.035, "relax": 2, "parts": parts})
field = lcr.Field(spec)
body = lcr.build_body(spec, field)
body.name = "Shepherd"
me = body.data
me.name = "Shepherd"
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.shade_smooth()

# colours: tan, the black saddle over the back, a black muzzle, dark ears, a lighter chest and legs' inside
col = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
NOSE = (0.02, 0.02, 0.02, 1.0)


def ss(e0, e1, x):  # a soft edge (smoothstep), so the colour borders are clean curves, not stair steps
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def mix(c1, c2, t):
    return tuple(c1[i] * (1 - t) + c2[i] * t for i in range(4))


for poly in me.polygons:
    for li in poly.loop_indices:
        p = me.vertices[me.loops[li].vertex_index].co
        x, y, z = p.x, p.z, -p.y  # Roblox coords
        c = TAN
        c = mix(c, CREAM, ss(1.75, 1.35, y) * ss(-0.4, -0.8, z) * ss(0.5, 0.3, abs(x)))  # the chest
        saddle = ss(2.14, 2.2, y + 0.08 * math.sin(z * 4.0)) * ss(-1.62, -1.52, z) * ss(1.95, 1.85, z)
        c = mix(c, DARK, saddle)  # the saddle: a CRISP wavy edge (v3)
        c = mix(c, DARK, ss(-2.95, -3.08, z) * ss(2.55, 2.65, y))  # the dark muzzle
        c = mix(c, NOSE, ss(-3.4, -3.44, z) * ss(2.72, 2.76, y))  # the black nose
        c = mix(c, NOSE, ss(-2.75, -2.85, z) * (1 - ss(0.0, 0.05, abs(y - 2.7))))  # the mouth line
        c = mix(c, DARK, ss(3.5, 3.62, y))  # the ears
        c = mix(c, DARK, ss(2.45, 2.55, z) * ss(1.2, 1.05, y))  # the tail tip
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
bone("Spine", "hips", "loin", "Root")
bone("Chest", "loin", "withers", "Spine")
bone("Neck", "withers", "neck", "Chest")
bone("Head", "neck", "head", "Neck")
bone("Muzzle", "cheek", "nose", "Head")
bone("Jaw", "cheek", "jaw", "Head")
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
import bmesh
bm = bmesh.new()
bm.from_mesh(me)
uvl = bm.loops.layers.uv.active
for f in bm.faces:
    for l in f.loops:
        l[uvl].uv.x *= 0.8
EYES = []
for k, sx in enumerate((-1, 1)):
    c = Vector((0.34 * sx, 3.25, -2.42))
    n = Vector((0.85 * sx, 0.15, -0.5)).normalized()
    u = Vector((0, 1, 0)).cross(n).normalized()
    w = n.cross(u).normalized()
    Rr = 0.2
    u0, v0, size = 0.82, 0.8 - k * 0.2, 0.16
    EYES.append({"u0": u0, "v0": v0, "size": size})
    for f in bm.faces:
        fc = f.calc_center_median()
        fc = Vector((fc.x, fc.z, -fc.y))
        fn = Vector((f.normal.x, f.normal.z, -f.normal.y))
        if (fc - c).length < Rr * 1.1 and fn.dot(n) > 0.3:
            for l in f.loops:
                q = Vector((l.vert.co.x, l.vert.co.z, -l.vert.co.y)) - c
                a2, b2 = q.dot(u) / (2 * Rr) + 0.5, q.dot(w) / (2 * Rr) + 0.5
                l[uvl].uv = (u0 + max(0, min(1, a2)) * size, v0 + max(0, min(1, b2)) * size)
bm.to_mesh(me)
bm.free()
json.dump(EYES, open(os.path.join(HERE, "shepherd_v3_eyes.json"), "w"))
img = bpy.data.images.new("shepherd_color", 2048, 2048)
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
    img.filepath_raw = os.path.join(HERE, "shepherd_v3_base.png")
    img.file_format = "PNG"
    img.save()
except Exception as ex:
    baked = False
    print("bake failed", ex)
plain = bpy.data.materials.new("ShepherdPlastic")
me.materials.clear()
me.materials.append(plain)

tris = sum(len(p.vertices) - 2 for p in me.polygons)
out = os.path.join(HERE, "shepherd_v3.fbx")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_scale_options="FBX_SCALE_UNITS", axis_forward="Z", axis_up="Y",
                         add_leaf_bones=False, bake_anim=False, use_mesh_modifiers=True, object_types={"ARMATURE", "MESH"})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "shepherd_v3.blend"))
dims = body.dimensions
stats = {"tris": tris, "bones": len(arm.bones), "baked": baked, "size_studs": [round(dims.x, 2), round(dims.z, 2), round(dims.y, 2)]}
json.dump(stats, open(os.path.join(HERE, "shepherd_v3_stats.json"), "w"), indent=1)
print("SHEPHERD", json.dumps(stats))

