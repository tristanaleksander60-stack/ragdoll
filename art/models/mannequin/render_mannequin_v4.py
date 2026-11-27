# v4 review renders (the owner's bar): front, side, three-quarter, back, knocked down (a starfish), next to a
# player-sized block, and close-ups of a hand and the chest marking. Opens mannequin_v4.blend, uses mannequin_v4_color.png.
import bpy, math, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "mannequin_v4.blend"))
body = bpy.data.objects["MannequinBody"]
rig = bpy.data.objects["MannequinRig"]
img = bpy.data.images.load(os.path.join(HERE, "mannequin_v4_color.png"))
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
rd = os.path.join(HERE, "review_v4")
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
    shot(nm, (9 * math.sin(a), 9 * math.cos(a), 0.2), (0, 0, -0.1))
# close-ups: the right hand and the chest marking
shot("closeup_hand", (2.6, 2.4, -0.2), (1.5, 0.14, -0.3), 85)
shot("closeup_marking", (0.4, 3.2, 1.2), (0, 0.6, 1.1), 85)
# next to a player-sized block (5.2 studs)
bpy.ops.mesh.primitive_cube_add(size=1, location=(3.3, 0, -0.3))
ref = bpy.context.active_object
ref.scale = (2.0, 1.0, 5.2)
rm = bpy.data.materials.new("Ref")
rm.diffuse_color = (0.2, 0.4, 0.85, 1)
ref.data.materials.append(rm)
shot("next_to_player", (1.6, 11, 0.3), (1.6, 0, -0.2))
bpy.data.objects.remove(ref)
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
shot("knocked_down", (0.5, 1.0, 9), (0, 0, -1.6))
print("renders done")
