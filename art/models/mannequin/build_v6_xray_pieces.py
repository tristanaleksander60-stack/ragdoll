# FIXES_27NOV_LATE 1 + 5: the approved v6 mannequin split into its 15 R15 pieces (each face goes to the R15 part whose
# bones weigh most on its vertices; the finger bones count as the hand), each piece pushed out 0.015 along its normals.
# One asset does both jobs: the X-ray glass in the limb's own shape, and the hit hull for bullet holes.
# Run: blender -b art/models/mannequin/mannequin_v6.blend --python art/models/mannequin/build_v6_xray_pieces.py
import bpy, bmesh, os, json
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "mannequin_v6_xray.glb")
PARTS = ["Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm",
         "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"]

def part_of(group):
    if group in PARTS:
        return group
    g = group.lower()
    side = "Left" if "left" in g or g.endswith(".l") or g.endswith("_l") else ("Right" if "right" in g or g.endswith(".r") or g.endswith("_r") else None)
    if side and any(k in g for k in ("thumb", "index", "middle", "ring", "pinky", "finger", "hand")):
        return side + "Hand"
    if side and any(k in g for k in ("toe", "foot")):
        return side + "Foot"
    if "neck" in g or "head" in g or "jaw" in g:
        return "Head"
    if "root" in g or "hip" in g or "pelvis" in g:
        return "LowerTorso"
    return None

body = None
for ob in bpy.data.objects:
    if ob.type == "MESH" and any(m.type == "ARMATURE" for m in ob.modifiers) and len(ob.data.polygons) > 1000:
        body = ob
assert body, "no skinned body mesh"
names = {g.index: g.name for g in body.vertex_groups}
unmapped = sorted({n for n in names.values() if part_of(n) is None})
print("unmapped groups:", unmapped)

me = body.data
vpart = {}
for v in me.vertices:
    best, bw = None, 0.0
    for ge in v.groups:
        p = part_of(names.get(ge.group, ""))
        if p and ge.weight > bw:
            best, bw = p, ge.weight
    vpart[v.index] = best

faces = {p: [] for p in PARTS}
for poly in me.polygons:
    c = Counter(vpart[i] for i in poly.vertices if vpart[i])
    if c:
        faces[c.most_common(1)[0][0]].append(poly.index)

# fresh scene with only the pieces (world space, rest pose: the armature modifier is not applied)
mw = body.matrix_world.copy()
pieces = []
stats = {}
for p in PARTS:
    idx = faces[p]
    if not idx:
        continue
    bm = bmesh.new()
    bm.from_mesh(me)
    keep = set(idx)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.normal_update()
    for v in bm.verts:
        v.co = v.co + v.normal * (0.015 / max(1e-6, mw.to_scale()[0]))
    m = bpy.data.meshes.new(p + "_xray")
    bm.to_mesh(m)
    bm.free()
    m.materials.clear()
    o = bpy.data.objects.new(p, m)
    o.matrix_world = mw
    bpy.context.scene.collection.objects.link(o)
    pieces.append(o)
    stats[p] = len(m.polygons)

for ob in list(bpy.context.scene.objects):
    ob.select_set(ob in pieces)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True,
                          export_skins=False, export_animations=False, export_materials="NONE")
json.dump({"pieces": stats, "unmapped": unmapped}, open(os.path.join(HERE, "mannequin_v6_xray_stats.json"), "w"), indent=1)
print("XRAY PIECES", stats)
