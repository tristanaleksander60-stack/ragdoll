# The shepherd's review renders (side, three-quarter, front, a close-up of the head) with the final colour map.
import bpy, math, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "shepherd.blend"))
body = bpy.data.objects["Shepherd"]
img = bpy.data.images.load(os.path.join(HERE, "shepherd_color.png"))
m = bpy.data.materials.new("Review")
m.use_nodes = True
bsdf = m.node_tree.nodes.get("Principled BSDF")
t = m.node_tree.nodes.new("ShaderNodeTexImage")
t.image = img
m.node_tree.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.7
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
bpy.ops.object.light_add(type="SUN", location=(3, -6, 8))
bpy.context.active_object.data.energy = 2.6
cd = bpy.data.cameras.new("C")
cam = bpy.data.objects.new("C", cd)
sc.collection.objects.link(cam)
sc.camera = cam
rd = os.path.join(HERE, "review")
os.makedirs(rd, exist_ok=True)


def shot(name, loc, look, lens=50):
    cam.location = Vector(loc)
    d = Vector(look) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cd.lens = lens
    sc.render.filepath = os.path.join(rd, name + ".png")
    bpy.ops.render.render(write_still=True)


# (the nose points to Roblox -Z = Blender +Y)
shot("side", (11, 0, 2.2), (0, -0.4, 2.1))
shot("three_quarter", (8.0, 8.0, 3.0), (0, -0.6, 2.1))
shot("front", (0, 9.5, 2.4), (0, 0, 2.0))
shot("closeup_head", (1.6, 5.2, 3.4), (0, 2.6, 3.1), 70)
print("renders done")
