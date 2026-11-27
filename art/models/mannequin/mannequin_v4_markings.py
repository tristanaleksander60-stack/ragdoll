# v4 markings: draws the black-and-yellow quarter-circle crash-test targets as CRISP vector shapes (4x supersampled,
# anti-aliased, with a thin black outline) into the right column of the baked 2048 colour map, one per flat UV square
# that build_mannequin_v4.py reserved (mannequin_v4_marks.json). Output: mannequin_v4_color.png.
import json, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
YELLOW = (246, 196, 18, 255)
BLACK = (18, 18, 20, 255)

base = Image.open(os.path.join(HERE, "mannequin_v4_base.png")).convert("RGBA")
N = base.size[0]
marks = json.load(open(os.path.join(HERE, "mannequin_v4_marks.json")))
SS = 4
for sq in marks["squares"]:
    side = int(sq["size"] * N)
    x0 = int(sq["u0"] * N)
    y0 = int((1 - sq["v0"] - sq["size"]) * N)  # (the image's y runs down, UV v runs up)
    crop = base.crop((x0, y0, x0 + side, y0 + side)).resize((side * SS, side * SS), Image.NEAREST)
    d = ImageDraw.Draw(crop)
    c = side * SS / 2
    r = sq["circle"] * side * SS
    box = (c - r, c - r, c + r, c + r)
    if sq.get("plate"):
        # the chest plate: a soft lighter oval with a thin darker rim, set into the chest
        pw, ph = sq["plate"][0] * side * SS, sq["plate"][1] * side * SS
        d.ellipse((c - pw, c - ph, c + pw, c + ph), fill=(176, 176, 180, 255), outline=(120, 120, 124, 255), width=max(2, int(pw * 0.03)))
        for bx, by in ((-0.78, -0.62), (0.78, -0.62), (-0.78, 0.62), (0.78, 0.62)):
            bxp, byp, br = c + bx * pw * 0.85, c + by * ph * 0.8, pw * 0.05
            d.ellipse((bxp - br, byp - br, bxp + br, byp + br), fill=(100, 100, 104, 255))
    # four quarters, yellow and black crossed
    d.pieslice(box, 0, 90, fill=YELLOW)
    d.pieslice(box, 90, 180, fill=BLACK)
    d.pieslice(box, 180, 270, fill=YELLOW)
    d.pieslice(box, 270, 360, fill=BLACK)
    # the thin black outline ring
    d.ellipse(box, outline=BLACK, width=max(2, int(r * 0.07)))
    crop = crop.resize((side, side), Image.LANCZOS)
    base.paste(crop, (x0, y0))
base.save(os.path.join(HERE, "mannequin_v4_color.png"))
print("markings drawn:", len(marks["squares"]))
