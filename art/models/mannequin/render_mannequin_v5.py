# v4 review renders (the owner's bar): front, side, three-quarter, back, knocked down (a starfish), next to a
# player-sized block, and close-ups of a hand and the chest marking. Opens mannequin_v5.blend, uses mannequin_v5_color.png.
import bpy, math, os
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "mannequin_v5.blend"))
body = bpy.data.objects["MannequinBody"]
rig = bpy.data.objects["MannequinRig"]
img = bpy.data.images.load(os.path.join(HERE, "mannequin_v5_color.png"))
m = bpy.data.materials.new("Review")
m.use_nodes = True
bsdf = m.node_tree.nodes.get("Principled BSDF")
t = m.node_tree.nodes.new("ShaderNodeTexImage")
t.image = img
m.node_tree.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.45
body.data.materials.clear()
body.data.materials.append(m)
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 48
sc.render.resolution_x = sc.render.resolution_y = 800
w = bpy.data.worlds.new("W")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.82, 0.84, 0.88, 1)
bpy.ops.object.light_add(type="SUN", location=(3, 6, 8))
bpy.context.active_object.data.energy = 2.6
bpy.ops.object.light_add(type="AREA", location=(-4, 5, 3))
bpy.context.active_object.data.energy = 300
cd = bpy.data.cameras.new("C")
cam = bpy.data.objects.new("C", cd)
sc.collection.objects.link(cam)
sc.camera = cam
bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=48, ring_count=32, location=(0, 0, 2.86))
head = bpy.context.active_object
head.scale = (0.86, 0.84, 0.82)
bpy.ops.object.shade_smooth()
hm = bpy.data.materials.new("Head")
hm.use_nodes = True
hn = hm.node_tree
hb = hn.nodes.get("Principled BSDF")
hb.inputs["Roughness"].default_value = 0.45
tc = hn.nodes.new("ShaderNodeTexCoord")
sep = hn.nodes.new("ShaderNodeSeparateXYZ")
hn.links.new(tc.outputs["Object"], sep.inputs[0])
cmb = hn.nodes.new("ShaderNodeCombineXYZ")
mu = hn.nodes.new("ShaderNodeMath"); mu.operation = "MULTIPLY_ADD"; mu.inputs[1].default_value = 0.62; mu.inputs[2].default_value = 0.5
mv = hn.nodes.new("ShaderNodeMath"); mv.operation = "MULTIPLY_ADD"; mv.inputs[1].default_value = 0.62; mv.inputs[2].default_value = 0.5
hn.links.new(sep.outputs["X"], mu.inputs[0]); hn.links.new(sep.outputs["Z"], mv.inputs[0])
hn.links.new(mu.outputs[0], cmb.inputs["X"]); hn.links.new(mv.outputs[0], cmb.inputs["Y"])
fi = hn.nodes.new("ShaderNodeTexImage")
fi.image = bpy.data.images.load(os.path.join(HERE, "..", "..", "faces", "v2", "neutral.png"))
fi.extension = "CLIP"
hn.links.new(cmb.outputs[0], fi.inputs["Vector"])
front = hn.nodes.new("ShaderNodeMath"); front.operation = "GREATER_THAN"; front.inputs[1].default_value = 0.2
hn.links.new(sep.outputs["Y"], front.inputs[0])
am = hn.nodes.new("ShaderNodeMath"); am.operation = "MULTIPLY"
hn.links.new(fi.outputs["Alpha"], am.inputs[0]); hn.links.new(front.outputs[0], am.inputs[1])
mx = hn.nodes.new("ShaderNodeMix"); mx.data_type = "RGBA"
mx.inputs["A"].default_value = (0.42, 0.42, 0.43, 1)
hn.links.new(am.outputs[0], mx.inputs["Factor"]); hn.links.new(fi.outputs["Color"], mx.inputs["B"])
hn.links.new(mx.outputs["Result"], hb.inputs["Base Color"])
head.data.materials.append(hm)
head.parent = rig
head.parent_type = "BONE"
head.parent_bone = "Head"
head.matrix_parent_inverse = (rig.matrix_world @ rig.pose.bones["Head"].matrix @ Matrix.Translation((0, rig.pose.bones["Head"].length, 0))).inverted()
rd = os.path.join(HERE, "review_v5")
os.makedirs(rd, exist_ok=True)


def shot(name, loc, look, lens=50):
    cam.location = Vector(loc)
    d = Vector(look) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cd.lens = lens
    sc.render.filepath = os.path.join(rd, name + ".png")
    bpy.ops.render.render(write_still=True)


# (the front is Blender +Y)
for nm, ang in (("front", 0), ("three_quarter", 35), ("side", 90), ("back", 180)):
    a = math.radians(ang)
    shot(nm, (12 * math.sin(a), 12 * math.cos(a), 0.6), (0, 0, 0.2))
# close-ups: the right hand and the chest marking
shot("closeup_hand", (2.9, 2.6, -0.2), (1.66, 0.1, -0.2), 85)
shot("closeup_hand_side", (1.75, 3.4, -0.25), (1.66, 0.1, -0.25), 85)
shot("closeup_hand_back", (4.2, 0.0, -0.2), (1.66, 0.0, -0.2), 85)
shot("closeup_marking", (0.4, 3.4, 1.2), (0, 0.8, 1.1), 85)
shot("closeup_head", (0.9, 4.2, 2.9), (0, 0, 2.7), 70)
# next to a real Roblox-size blocky R15 avatar (head, torso 2x2x1, arms and legs 1x2x1), standing on the same floor
AV = []
def box(loc, size, colr):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.scale = size
    m_ = bpy.data.materials.new("Av")
    m_.diffuse_color = colr
    m_.use_nodes = True
    m_.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = colr
    o.data.materials.append(m_)
    AV.append(o)
FL, AX = -2.25, 4.7
SKIN, SHIRT, PANTS = (0.96, 0.8, 0.41, 1), (0.13, 0.4, 0.85, 1), (0.2, 0.32, 0.2, 1)
box((AX - 0.5, 0, FL + 1), (1, 1, 2), PANTS)
box((AX + 0.5, 0, FL + 1), (1, 1, 2), PANTS)
box((AX, 0, FL + 3), (2, 1, 2), SHIRT)
box((AX - 1.5, 0, FL + 3), (1, 1, 2), SKIN)
box((AX + 1.5, 0, FL + 3), (1, 1, 2), SKIN)
bpy.ops.mesh.primitive_cylinder_add(radius=0.6, depth=1.2, location=(AX, 0, FL + 4.6))
hd = bpy.context.active_object
bpy.ops.object.shade_smooth()
mh = bpy.data.materials.new("AvH"); mh.use_nodes = True
mh.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = SKIN
hd.data.materials.append(mh)
AV.append(hd)
shot("next_to_player", (2.4, 15, 1.0), (2.4, 0, 0.3))
for o in AV:
    bpy.data.objects.remove(o)
# knocked down: a starfish on its back
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
pb = rig.pose.bones
for n, r in (("LeftUpperArm", (0, 0, 65)), ("RightUpperArm", (0, 0, -75)), ("LeftUpperLeg", (0, 0, 22)), ("RightUpperLeg", (0, 0, -26)), ("RightLowerLeg", (35, 0, 0)), ("LeftLowerArm", (-20, 0, 0))):
    b = pb.get(n)
    if b:
        b.rotation_mode = "XYZ"
        b.rotation_euler = tuple(math.radians(x) for x in r)
bpy.ops.object.mode_set(mode="OBJECT")
rig.rotation_euler = (math.radians(90), 0, math.radians(20))
rig.location = (0, 0, -1.6)
shot("knocked_down", (0.5, 1.0, 11), (0, 0, -1.6))
print("renders done")
