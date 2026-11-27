# Row 6 (docs/BODY_V2.md 4b faces): the new v2 faces, drawn with Pillow in the same style as neutral.png / hurt.png
# (dark wedge brows, almond eyes with a pupil and a glint, one mouth line, the cheek line copied from neutral.png).
# Run: python art/faces/v2/make_faces.py  -> worried.png pain.png angry.png sad.png relieved.png scared.png xeyes.png
import math, os
from PIL import Image, ImageChops, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
S = 4  # supersample
W = 512
INK = (18, 18, 20, 255)
WHITE = (245, 245, 245, 255)
EYES = {"L": (150, 229), "R": (365, 229)}  # the two eye centres in neutral.png
MOUTH_Y = 360


def P(x, y):
    return (x * S, y * S)


def line(d, pts, w):
    pts = [P(*p) for p in pts]
    d.line(pts, fill=INK, width=int(w * S), joint="curve")
    r = w * S / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=INK)


def curve(f, a, b, n=40):
    return [f(a + (b - a) * i / n) for i in range(n + 1)]


def brow(d, side, inner_y, outer_y, thick=22, arch=-6):
    # a wedge: thick at the inner end, thin at the outer; inner ends near the nose
    cx = EYES[side][0]
    sgn = 1 if side == "L" else -1  # L: inner end is to the right (+x)
    xo, xi = cx - sgn * 78, cx + sgn * 58
    top, bot = [], []
    for i in range(31):
        t = i / 30
        x = xo + (xi - xo) * t
        y = outer_y + (inner_y - outer_y) * t + arch * math.sin(math.pi * t)
        h = 3 + thick * t ** 1.3
        top.append(P(x, y - h / 2))
        bot.append(P(x, y + h / 2))
    d.polygon(top + bot[::-1], fill=INK)
    r = (3 + thick) * S / 2
    x, y = P(xi, inner_y)
    d.ellipse((x - r * 0.9, y - r, x + r * 0.9, y + r), fill=INK)


def eye(d, side, open_=1.0, pupil=13, lid=0.0, look=(0, 0)):
    cx, cy = EYES[side]
    hw, hh = 56, 20 * open_
    # a lens (pointed corners like neutral.png), the upper lid lowered by `lid`
    up = curve(lambda u: (cx - hw + 2 * hw * u, cy - hh * (1 - lid * 0.9) * math.sin(math.pi * u)), 0, 1)
    dn = curve(lambda u: (cx + hw - 2 * hw * u, cy + hh * math.sin(math.pi * u)), 0, 1)
    shape = [P(*p) for p in up + dn]
    d.polygon(shape, fill=WHITE)
    # the pupil, clipped to the eye by drawing it on a mask
    m = Image.new("L", (W * S, W * S), 0)
    ImageDraw.Draw(m).polygon(shape, fill=255)
    pi = Image.new("RGBA", (W * S, W * S), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pi)
    px, py = cx + look[0], cy + look[1]
    pd.ellipse((P(px - pupil, py - pupil), P(px + pupil, py + pupil)), fill=INK)
    g = max(3, pupil * 0.3)
    pd.ellipse((P(px - pupil * 0.35 - g, py - pupil * 0.4 - g), P(px - pupil * 0.35 + g, py - pupil * 0.4 + g)), fill=WHITE)
    pi.putalpha(ImageChops.multiply(pi.split()[3], m))
    d._image.alpha_composite(pi)
    line(d, up, 7)
    line(d, dn, 7)


def closed_squeeze(d, side):  # > < eyes
    cx, cy = EYES[side]
    sgn = 1 if side == "L" else -1
    tip = cx + sgn * 30
    line(d, [(cx - sgn * 34, cy - 20), (tip, cy), (cx - sgn * 34, cy + 20)], 9)


def happy_closed(d, side):  # ^ arcs
    cx, cy = EYES[side]
    line(d, curve(lambda t: (cx + 48 * math.cos(t), cy + 6 - 16 * math.sin(t)), math.pi, 0), 8)


def x_eye(d, side):
    cx, cy = EYES[side]
    line(d, [(cx - 28, cy - 24), (cx + 28, cy + 24)], 10)
    line(d, [(cx - 28, cy + 24), (cx + 28, cy - 24)], 10)


def mouth_arc(d, width, bend, y=MOUTH_Y, thick=10, x0=255):
    # bend > 0 = smile (ends up), < 0 = frown
    line(d, curve(lambda t: (x0 + width * t, y - bend * (t * t)), -1, 1), thick)


def mouth_wave(d, width=80, amp=7, y=MOUTH_Y + 2):
    line(d, curve(lambda t: (255 + width * t, y + amp * math.sin(t * math.pi * 2)), -1, 1, 60), 8)


def mouth_open(d, w, h, y=MOUTH_Y, teeth=False):
    x0, x1 = 255 - w, 255 + w
    d.ellipse((P(x0, y - h), P(x1, y + h)), fill=INK)
    if teeth:
        d.rectangle((P(x0 + w * 0.35, y - h * 0.62), P(x1 - w * 0.35, y + h * 0.62)), fill=WHITE)
        for k in (-1, 0, 1):
            x = 255 + k * w * 0.2
            d.line((P(x, y - h * 0.62), P(x, y + h * 0.62)), fill=INK, width=3 * S)
        d.line((P(x0 + w * 0.35, y), P(x1 - w * 0.35, y)), fill=INK, width=3 * S)


def cheek(img):
    n = Image.open(os.path.join(HERE, "neutral.png")).convert("RGBA")
    box = (385, 292, 445, 400)
    img.alpha_composite(n.crop(box), box[:2])


FACES = {}


def face(name):
    def deco(fn):
        FACES[name] = fn
        return fn
    return deco


@face("worried")
def _(d):
    for s in "LR":
        brow(d, s, 168, 186, arch=4)
        eye(d, s, 1.05, 12)
    mouth_wave(d, 62, 6)


@face("pain")
def _(d):
    for s in "LR":
        brow(d, s, 196, 168, thick=24)
        closed_squeeze(d, s)
    mouth_open(d, 70, 26, teeth=True)


@face("angry")
def _(d):
    for s in "LR":
        brow(d, s, 214, 160, thick=26, arch=-2)
        eye(d, s, 0.85, 13, lid=0.35)
    mouth_arc(d, 78, -26, y=372, thick=14)


@face("sad")
def _(d):
    for s in "LR":
        brow(d, s, 170, 194, arch=3)
        eye(d, s, 0.9, 12, lid=0.45, look=(0, 4))
    mouth_arc(d, 70, -22, y=370, thick=10)


@face("relieved")
def _(d):
    for s in "LR":
        brow(d, s, 176, 172, arch=-8)
        happy_closed(d, s)
    mouth_arc(d, 74, 22, y=350, thick=10)


@face("scared")
def _(d):
    for s in "LR":
        brow(d, s, 150, 166, arch=-4)
        eye(d, s, 1.45, 8)
    mouth_open(d, 30, 34, y=368)


@face("xeyes")
def _(d):
    for s in "LR":
        brow(d, s, 186, 178, thick=18, arch=-4)
        x_eye(d, s)
    mouth_wave(d, 78, 9)


def main():
    out = []
    for name, fn in FACES.items():
        big = Image.new("RGBA", (W * S, W * S), (0, 0, 0, 0))
        d = ImageDraw.Draw(big)
        fn(d)
        img = big.resize((W, W), Image.LANCZOS)
        cheek(img)
        path = os.path.join(HERE, name + ".png")
        img.save(path)
        out.append(path)
    print("\n".join(out))


if __name__ == "__main__":
    main()
