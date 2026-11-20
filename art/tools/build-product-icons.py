#!/usr/bin/env python3
"""Builds the 512x512 icons for every pass, developer product, event product and badge that the
owner still has to create on the Creator Dashboard. No AI, no credits: it composes the game's own
hand-drawn stickers (art/icons, art/events) on a lit background with a title, and draws the few
missing pictures (trail, flame, robot dog, parrot, spider, bolt, crate) in the same sticker style.

Run from the repo root:  python3 art/tools/build-product-icons.py
Writes art/shop/<key>.png, art/shop/event_<id>.png, art/badges/badge_<key>.png and
art/shop/_sheet.png (a contact sheet to look at).
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICONS = os.path.join(ROOT, "art", "icons")
EVENTS = os.path.join(ROOT, "art", "events")
SHOP = os.path.join(ROOT, "art", "shop")
BADGES = os.path.join(ROOT, "art", "badges")
FONT = "/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf"
S = 512
INK = (28, 28, 34, 255)
WHITE = (255, 255, 255, 255)


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


# ---------------------------------------------------------------- backgrounds and text
def background(top, bottom, rays=True):
    img = Image.new("RGBA", (S, S))
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / (S - 1)
        d.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    if rays:
        ray = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ray)
        cx, cy = S / 2, S * 0.44
        for i in range(16):
            a0 = i * math.tau / 16
            a1 = a0 + math.tau / 32
            rd.polygon([(cx, cy), (cx + 800 * math.cos(a0), cy + 800 * math.sin(a0)), (cx + 800 * math.cos(a1), cy + 800 * math.sin(a1))], fill=(255, 255, 255, 22))
        img.alpha_composite(ray)
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([S * 0.12, S * 0.06, S * 0.88, S * 0.82], fill=(255, 255, 255, 70))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(40)))
    return img


def rounded(img, radius=64):
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius, fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def title(img, text, size=64, y=None):
    d = ImageDraw.Draw(img)
    f = font(size)
    while d.textlength(text, font=f) > S - 60 and size > 28:
        size -= 4
        f = font(size)
    w = d.textlength(text, font=f)
    y = S - size - 34 if y is None else y
    x = (S - w) / 2
    d.text((x + 4, y + 6), text, font=f, fill=(0, 0, 0, 120), stroke_width=10, stroke_fill=(0, 0, 0, 120))
    d.text((x, y), text, font=f, fill=WHITE, stroke_width=9, stroke_fill=INK)


def chip(img, text, color):
    d = ImageDraw.Draw(img)
    f = font(34)
    w = d.textlength(text, font=f)
    box = [S - w - 64, 26, S - 26, 84]
    d.rounded_rectangle(box, 22, fill=color, outline=INK, width=6)
    d.text((box[0] + 19, 32), text, font=f, fill=WHITE, stroke_width=4, stroke_fill=INK)


def sticker(name, size):
    im = Image.open(os.path.join(ICONS, name + ".png")).convert("RGBA")
    return im.resize((size, size), Image.LANCZOS)


def shadowed(img, pic, x, y):
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = pic.split()[3].point(lambda v: int(v * 0.45))
    blk = Image.new("RGBA", pic.size, (0, 0, 0, 255))
    blk.putalpha(a)
    sh.alpha_composite(blk, (int(x + 8), int(y + 14)))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
    img.alpha_composite(pic, (int(x), int(y)))


def place(img, pics):
    """pics: list of (picture, cx, cy, size) with centre in 0..1 of the art area above the title."""
    for pic, cx, cy, size in pics:
        p = pic if isinstance(pic, Image.Image) else sticker(pic, size)
        p = p.resize((size, size), Image.LANCZOS) if p.size != (size, size) else p
        shadowed(img, p, cx * S - size / 2, cy * S - size / 2)


# ---------------------------------------------------------------- drawn stickers (missing art)
def canvas():
    return Image.new("RGBA", (256, 256), (0, 0, 0, 0)), None


def finish(layer):
    """Sticker look: a white rim and an ink outline round the drawing."""
    a = layer.split()[3]
    rim = a.filter(ImageFilter.MaxFilter(17))
    ink = a.filter(ImageFilter.MaxFilter(9))
    out = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    w = Image.new("RGBA", layer.size, WHITE)
    w.putalpha(rim)
    k = Image.new("RGBA", layer.size, INK)
    k.putalpha(ink)
    out.alpha_composite(w)
    out.alpha_composite(k)
    out.alpha_composite(layer)
    return out


def draw_rainbow():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cols = [(235, 64, 52), (245, 150, 40), (250, 215, 60), (80, 200, 90), (60, 140, 235), (140, 90, 220)]
    for i, c in enumerate(cols):
        r = 110 - i * 14
        d.arc([128 - r, 150 - r, 128 + r, 150 + r], 180, 360, fill=c + (255,), width=15)
        d.arc([128 - r, 150 - r, 128 + r, 150 + r], 180, 360, fill=INK, width=2)
    for cx in (42, 214):
        d.ellipse([cx - 30, 140, cx + 30, 190], fill=WHITE, outline=INK, width=5)
    return finish(im)


def draw_flame():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    outer = [(128, 20), (170, 80), (205, 120), (200, 190), (160, 236), (96, 236), (56, 190), (52, 130), (86, 96), (98, 140), (118, 70)]
    inner = [(130, 100), (160, 150), (164, 200), (140, 226), (114, 226), (92, 196), (100, 158), (116, 170)]
    d.polygon(outer, fill=(240, 90, 40, 255), outline=INK, width=6)
    d.polygon(inner, fill=(255, 210, 70, 255), outline=INK, width=4)
    return finish(im)


def draw_spider(gold=False):
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body = (235, 190, 60) if gold else (60, 52, 80)
    for side in (-1, 1):
        for i in range(4):
            y0 = 120 + i * 18
            pts = [(128 + side * 40, y0), (128 + side * (80 + i * 6), y0 - 40 + i * 8), (128 + side * (112 + i * 4), y0 + 30 + i * 6)]
            d.line(pts, fill=INK, width=14, joint="curve")
            d.line(pts, fill=body + (255,), width=7, joint="curve")
    d.ellipse([78, 110, 178, 210], fill=body + (255,), outline=INK, width=6)
    d.ellipse([96, 66, 160, 124], fill=body + (255,), outline=INK, width=6)
    for ex in (114, 142):
        d.ellipse([ex - 12, 80, ex + 12, 104], fill=WHITE, outline=INK, width=3)
        d.ellipse([ex - 4, 88, ex + 5, 100], fill=INK)
    if gold:
        for sx, sy in ((60, 60), (200, 70), (210, 200)):
            d.polygon([(sx, sy - 16), (sx + 5, sy - 5), (sx + 16, sy), (sx + 5, sy + 5), (sx, sy + 16), (sx - 5, sy + 5), (sx - 16, sy), (sx - 5, sy - 5)], fill=(255, 245, 180, 255), outline=INK)
    return finish(im)


def draw_bolt(label=None):
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    hexa = [(128 + 92 * math.cos(math.radians(a)), 128 + 92 * math.sin(math.radians(a))) for a in range(30, 390, 60)]
    d.polygon(hexa, fill=(190, 198, 210, 255), outline=INK, width=7)
    d.ellipse([88, 88, 168, 168], fill=(110, 118, 132, 255), outline=INK, width=6)
    d.arc([60, 60, 196, 196], 200, 260, fill=WHITE, width=8)
    if label:
        f = font(70)
        w = d.textlength(label, font=f)
        d.text((128 - w / 2, 88), label, font=f, fill=(255, 210, 60, 255), stroke_width=7, stroke_fill=INK)
    return finish(im)


def draw_crate():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([40, 70, 216, 226], fill=(196, 140, 78, 255), outline=INK, width=7)
    for y in (122, 174):
        d.line([(40, y), (216, y)], fill=INK, width=5)
    d.line([(46, 76), (210, 220)], fill=(150, 100, 52, 255), width=16)
    d.line([(46, 76), (210, 220)], fill=INK, width=3)
    d.rectangle([30, 52, 226, 80], fill=(176, 120, 62, 255), outline=INK, width=7)
    return finish(im)


def draw_robot_dog():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    metal = (176, 190, 206, 255)
    for x in (70, 96, 160, 186):
        d.rounded_rectangle([x - 9, 150, x + 9, 220], 6, fill=metal, outline=INK, width=5)
    d.rounded_rectangle([50, 106, 200, 168], 26, fill=metal, outline=INK, width=6)
    d.line([(198, 120), (232, 86)], fill=INK, width=12)
    d.line([(198, 120), (232, 86)], fill=metal, width=5)
    d.rounded_rectangle([20, 62, 104, 124], 20, fill=metal, outline=INK, width=6)
    d.polygon([(30, 66), (40, 30), (58, 64)], fill=metal, outline=INK)
    d.polygon([(66, 64), (84, 30), (94, 66)], fill=metal, outline=INK)
    d.rounded_rectangle([34, 80, 92, 104], 10, fill=(40, 46, 60, 255))
    for ex in (50, 76):
        d.ellipse([ex - 6, 86, ex + 6, 98], fill=(90, 220, 255, 255))
    d.ellipse([112, 122, 140, 150], fill=(90, 220, 255, 255), outline=INK, width=4)
    return finish(im)


def draw_parrot():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(118, 170), (96, 246), (130, 240), (150, 176)], fill=(60, 120, 230, 255), outline=INK, width=5)
    d.ellipse([84, 80, 176, 190], fill=(226, 50, 50, 255), outline=INK, width=6)
    d.polygon([(120, 112), (70, 170), (110, 186), (150, 130)], fill=(250, 200, 50, 255), outline=INK, width=5)
    d.polygon([(132, 128), (96, 176), (128, 182), (152, 140)], fill=(60, 120, 230, 255), outline=INK, width=4)
    d.ellipse([110, 36, 190, 116], fill=(226, 50, 50, 255), outline=INK, width=6)
    d.ellipse([140, 54, 170, 84], fill=WHITE, outline=INK, width=4)
    d.ellipse([152, 62, 164, 76], fill=INK)
    d.polygon([(178, 66), (214, 82), (186, 104), (176, 90)], fill=(60, 60, 66, 255), outline=INK, width=4)
    return finish(im)


def dummy(tint=None):
    """The crash-test dummy from the guide_feed sticker (left part), optionally tinted."""
    src = Image.open(os.path.join(ICONS, "guide_feed.png")).convert("RGBA")
    crop = src.crop((0, 0, 112, 220)).resize((130, 256), Image.LANCZOS)
    pic = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    pic.alpha_composite(crop, (63, 0))
    if tint:
        r, g, b, a = pic.split()
        lum = Image.merge("RGB", (r, g, b)).convert("L")
        col = Image.new("RGBA", pic.size, tint + (255,))
        gold = Image.composite(col, Image.new("RGBA", pic.size, INK), lum.point(lambda v: 255 if v > 90 else 0))
        shade = lum.point(lambda v: int(150 + v * 0.42))
        gr, gg, gb, _ = gold.split()
        gold = Image.merge("RGBA", tuple(Image.composite(ch, ch.point(lambda v, s=1: v), shade) for ch in (gr, gg, gb)) + (a,))
        pic = gold
    return pic


# ---------------------------------------------------------------- the catalogue
P = "PASS"
GOLD = ((255, 196, 60), (190, 100, 20))
RED = ((255, 104, 70), (150, 30, 30))
BLUE = ((90, 170, 255), (30, 60, 150))
GREEN = ((110, 220, 120), (30, 110, 60))
PURPLE = ((180, 120, 255), (70, 30, 140))
TEAL = ((90, 220, 220), (20, 100, 120))
PINK = ((255, 130, 200), (150, 40, 110))
DARK = ((90, 100, 130), (25, 28, 45))

OFFERS = [
    # key, title, colours, chip, pictures
    ("entrypack", "STARTER CRATE", GOLD, None, [(draw_crate(), 0.5, 0.42, 280), (draw_bolt(), 0.2, 0.25, 130), ("tool_Revolver", 0.8, 0.26, 150)]),
    ("allmelee", "ALL MELEE", RED, P, [("tool_Bat", 0.3, 0.4, 230), ("tool_Katana", 0.7, 0.4, 230), ("tool_Hammer", 0.5, 0.33, 210)]),
    ("allexplosives", "ALL EXPLOSIVES", RED, P, [("tool_Grenade", 0.27, 0.44, 200), ("tool_Nuke", 0.5, 0.36, 250), ("tool_C4", 0.75, 0.46, 190)]),
    ("allguns", "ALL GUNS", DARK, P, [("tool_AK", 0.32, 0.36, 230), ("tool_Minigun", 0.66, 0.46, 250), ("tool_Deagle", 0.5, 0.25, 170)]),
    ("labcontrols", "LAB CONTROLS", RED, P, [("sign_button", 0.5, 0.42, 300)]),
    ("doublebolts", "2x BOLTS", TEAL, P, [(draw_bolt("2x"), 0.5, 0.42, 300)]),
    ("viplab", "VIP LAB", PURPLE, P, [(dummy(), 0.32, 0.46, 250), (dummy(), 0.68, 0.46, 250), ("crown", 0.5, 0.18, 170)]),
    ("eventspass", "EVENTS PASS", PINK, P, [("event_MegaBomb", 0.3, 0.44, 210), ("event_ZeroG", 0.7, 0.44, 210), ("star", 0.5, 0.2, 150)]),
    ("everything", "EVERYTHING", GOLD, P, [("crown", 0.5, 0.17, 170), ("tool_Minigun", 0.3, 0.48, 200), ("tool_Nuke", 0.7, 0.48, 200), (draw_bolt("2x"), 0.5, 0.5, 150)]),
    ("rainbowtrail", "RAINBOW TRAIL", BLUE, P, [(draw_rainbow(), 0.5, 0.4, 320)]),
    ("firetrail", "FIRE TRAIL", RED, P, [(draw_flame(), 0.5, 0.4, 300)]),
    ("crashsuit", "CRASH-TEST SUIT", GOLD, P, [(dummy(), 0.5, 0.42, 330)]),
    ("golddummies", "GOLD DUMMIES", GOLD, P, [(dummy((240, 190, 50)), 0.34, 0.44, 280), (dummy((240, 190, 50)), 0.66, 0.44, 280), ("star", 0.5, 0.15, 110)]),
    ("robotdog", "ROBOT DOG", BLUE, P, [(draw_robot_dog(), 0.5, 0.42, 320)]),
    ("parrot", "PARROT", GREEN, P, [(draw_parrot(), 0.5, 0.42, 320)]),
    ("megatrampoline", "MEGA TRAMPOLINE", BLUE, P, [("tool_Trampoline", 0.5, 0.44, 330), (dummy(), 0.5, 0.16, 150)]),
    ("giantfan", "GIANT FAN", TEAL, P, [("tool_Fan", 0.5, 0.42, 320)]),
    ("spiderdeluxe", "SPIDER DELUXE", GOLD, P, [(draw_spider(True), 0.5, 0.42, 330)]),
    ("boltcrate", "500 BOLTS", TEAL, None, [(draw_crate(), 0.5, 0.46, 260), (draw_bolt(), 0.3, 0.22, 140), (draw_bolt(), 0.7, 0.22, 140)]),
]

EVENT_LIST = [
    ("GorillaRampage", "GORILLA RAMPAGE"), ("BullRun", "BULL RUN"), ("Tornado", "TORNADO"),
    ("MeteorShower", "METEOR SHOWER"), ("TrainRun", "TRAIN RUN"), ("UfoBeam", "UFO BEAM"),
    ("BowlingAvalanche", "BOWLING AVALANCHE"), ("RocketRain", "ROCKET RAIN"), ("MagnetStorm", "MAGNET STORM"),
    ("LightningStorm", "LIGHTNING STORM"), ("Sinkhole", "SINKHOLE"), ("Earthquake", "EARTHQUAKE"),
    ("FanBlast", "GIANT FAN"), ("MoonGravity", "MOON GRAVITY"), ("BalloonDrop", "BALLOON DROP"), ("GiantDummy", "GIANT DUMMY"),
]

BADGE_LIST = [
    ("havoc_maker", "100", GREEN, [(dummy(), 0.5, 0.4, 260)]),
    ("nuked_it", "NUKED IT", RED, [("tool_Nuke", 0.5, 0.42, 300)]),
    ("havoc_legend", "1000", GOLD, [("crown", 0.5, 0.2, 170), (dummy((240, 190, 50)), 0.5, 0.5, 240)]),
]


def build_offer(key, text, colours, tag, pics):
    img = background(*colours)
    place(img, pics)
    if tag:
        chip(img, tag, (40, 44, 60, 255))
    title(img, text)
    img = rounded(img)
    img.save(os.path.join(SHOP, key + ".png"))
    return img


def build_event(eid, text):
    src = Image.open(os.path.join(EVENTS, eid + ".jpg")).convert("RGBA").resize((S, S), Image.LANCZOS)
    band = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    for y in range(S // 2, S):
        bd.line([(0, y), (S, y)], fill=(0, 0, 0, int(200 * (y - S / 2) / (S / 2))))
    src.alpha_composite(band)
    chip(src, "EVENT", (232, 80, 58, 255))
    title(src, text)
    img = rounded(src)
    ImageDraw.Draw(img).rounded_rectangle([3, 3, S - 4, S - 4], 62, outline=(255, 255, 255, 200), width=6)
    img.save(os.path.join(SHOP, "event_" + eid + ".png"))
    return img


def build_badge(key, text, colours, pics):
    img = background(*colours)
    place(img, pics)
    title(img, text, size=64, y=S - 150)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    ImageDraw.Draw(out).ellipse([6, 6, S - 7, S - 7], outline=WHITE, width=12)
    ImageDraw.Draw(out).ellipse([0, 0, S - 1, S - 1], outline=INK, width=6)
    out.save(os.path.join(BADGES, "badge_" + key + ".png"))
    return out


def main():
    made = [build_offer(*o) for o in OFFERS]
    made += [build_event(*e) for e in EVENT_LIST]
    made += [build_badge(*b) for b in BADGE_LIST]
    cols = 8
    rows = math.ceil(len(made) / cols)
    sheet = Image.new("RGBA", (cols * 260, rows * 260), (40, 42, 52, 255))
    for i, im in enumerate(made):
        sheet.alpha_composite(im.resize((250, 250), Image.LANCZOS), ((i % cols) * 260 + 5, (i // cols) * 260 + 5))
    sheet.save(os.path.join(SHOP, "_sheet.png"))
    print(len(made), "icons")


if __name__ == "__main__":
    main()
