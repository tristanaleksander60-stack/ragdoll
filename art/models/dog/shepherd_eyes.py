# The shepherd's eyes, drawn crisp (Pillow, 4x supersampled) into their own flat UV squares of the baked colour map:
# a dark brown almond eye with a black pupil and a white glint, a thin dark rim. Output: shepherd_color.png.
import json, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
base = Image.open(os.path.join(HERE, "shepherd_base.png")).convert("RGBA")
N = base.size[0]
SS = 4
for sq in json.load(open(os.path.join(HERE, "shepherd_eyes.json"))):
    side = int(sq["size"] * N)
    x0, y0 = int(sq["u0"] * N), int((1 - sq["v0"] - sq["size"]) * N)
    crop = base.crop((x0, y0, x0 + side, y0 + side)).resize((side * SS, side * SS), Image.NEAREST)
    d = ImageDraw.Draw(crop)
    c, r = side * SS / 2, side * SS * 0.3
    d.ellipse((c - r * 1.15, c - r * 0.8, c + r * 1.15, c + r * 0.8), fill=(16, 12, 10, 255))  # the dark rim
    d.ellipse((c - r, c - r * 0.68, c + r, c + r * 0.68), fill=(92, 54, 26, 255))  # the brown iris
    d.ellipse((c - r * 0.45, c - r * 0.45, c + r * 0.45, c + r * 0.45), fill=(8, 6, 6, 255))  # the pupil
    g = r * 0.17
    d.ellipse((c - r * 0.35 - g, c - r * 0.3 - g, c - r * 0.35 + g, c - r * 0.3 + g), fill=(255, 255, 255, 255))  # the glint
    base.paste(crop.resize((side, side), Image.LANCZOS), (x0, y0))
base.save(os.path.join(HERE, "shepherd_color.png"))
print("eyes drawn")
