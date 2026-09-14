#!/usr/bin/env python3
"""Procedural gothic pixel sprites for Crimson Covenant."""
from __future__ import annotations

import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "resources" / "sprites"
PREVIEW_IMG = ROOT / "preview" / "img"
MANIFEST = ROOT / "assets" / "resources" / "sprites" / "manifest.json"

# Palette — original gothic night, not a Bloodborne copy.
VOID = (8, 7, 12, 255)
INDIGO = (16, 14, 28, 255)
NAVY = (26, 30, 46, 255)
COBBLE = (40, 38, 52, 255)
COBBLE_L = (58, 54, 70, 255)
COBBLE_D = (24, 22, 34, 255)
STONE = (72, 68, 82, 255)
MOSS = (46, 64, 52, 255)
GOLD = (198, 154, 62, 255)
GOLD_DIM = (126, 92, 38, 255)
CRIMSON = (176, 32, 40, 255)
BLOOD = (112, 16, 26, 255)
PALE = (232, 214, 196, 255)
SKIN_D = (176, 136, 118, 255)
HAIR = (28, 20, 18, 255)
COAT = (34, 24, 28, 255)
COAT_L = (56, 40, 44, 255)
LINING = (104, 18, 30, 255)
SHIRT = (168, 156, 140, 255)
PANTS = (28, 24, 26, 255)
BOOT = (48, 36, 30, 255)
STEEL = (176, 182, 190, 255)
STEEL_D = (92, 98, 108, 255)
BRASS = (168, 124, 58, 255)
BEAST = (74, 58, 48, 255)
BEAST_D = (42, 32, 28, 255)
BEAST_L = (110, 88, 70, 255)
FUR = (90, 72, 58, 255)
SHAWL = (220, 214, 200, 255)
IRON = (36, 36, 42, 255)
MASK = (48, 44, 40, 255)
BOSS_SKIN = (210, 196, 178, 255)
ROBE = (48, 42, 36, 255)
ROBE_G = (150, 126, 64, 255)
FOG = (48, 52, 70, 90)
LANTERN = (255, 210, 110, 255)
WHITE = (236, 230, 220, 255)
UI_BG = (18, 14, 18, 255)
UI_EDGE = (92, 70, 42, 255)


def ensure(p: Path) -> Path:
    p.mkdir(parents=True, exist_ok=True)
    return p


def new(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(img: Image.Image, x: int, y: int, c, w: int = 1, h: int = 1) -> None:
    px, py = img.size
    if w < 1 or h < 1:
        return
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(px, x + w), min(py, y + h)
    if x1 <= x0 or y1 <= y0:
        return
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=c)
    img.alpha_composite(layer)


def pset(img: Image.Image, x: int, y: int, c) -> None:
    if 0 <= x < img.size[0] and 0 <= y < img.size[1]:
        img.putpixel((x, y), c)


def line(img: Image.Image, x0: int, y0: int, x1: int, y1: int, c, t: int = 1) -> None:
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        t0 = i / steps
        x = round(x0 + (x1 - x0) * t0)
        y = round(y0 + (y1 - y0) * t0)
        put(img, x - t // 2, y - t // 2, c, t, t)


def disc(img: Image.Image, cx: int, cy: int, r: int, c) -> None:
    for y in range(-r, r + 1):
        for x in range(-r, r + 1):
            if x * x + y * y <= r * r:
                pset(img, cx + x, cy + y, c)


def oval(img: Image.Image, cx: int, cy: int, rx: int, ry: int, c) -> None:
    for y in range(-ry, ry + 1):
        for x in range(-rx, rx + 1):
            if rx and ry and (x * x) / (rx * rx) + (y * y) / (ry * ry) <= 1.05:
                pset(img, cx + x, cy + y, c)


def save(img: Image.Image, path: Path) -> None:
    ensure(path.parent)
    img.save(path)


def limb(img, x, y, length, ang_deg, thick, col, taper=0):
    a = math.radians(ang_deg)
    x1 = x + math.cos(a) * length
    y1 = y + math.sin(a) * length
    steps = max(int(length) + 1, 1)
    for i in range(steps + 1):
        t = i / steps
        px = round(x + (x1 - x) * t)
        py = round(y + (y1 - y) * t)
        th = max(1, round(thick * (1 - taper * t)))
        put(img, px - th // 2, py - th // 2, col, th, th)
    return round(x1), round(y1)


# ---------------------------------------------------------------------------
# Hunter
# ---------------------------------------------------------------------------
def draw_saw(img, hx, hy, form: str, swing: float, scale=1):
    """form short|long. swing degrees, 0 = pointing forward."""
    a = math.radians(swing)
    length = 22 if form == "short" else 38
    teeth = 6 if form == "short" else 10
    dx, dy = math.cos(a), math.sin(a)
    px, py = hx, hy
    # handle
    hx2 = round(px + dx * 6)
    hy2 = round(py + dy * 6)
    line(img, px, py, hx2, hy2, BOOT, 3)
    line(img, px, py, hx2, hy2, BRASS, 1)
    # blade
    bx = round(px + dx * 7)
    by = round(py + dy * 7)
    ex = round(px + dx * length)
    ey = round(py + dy * length)
    line(img, bx, by, ex, ey, STEEL_D, 4)
    line(img, bx, by - 1, ex, ey - 1, STEEL, 2)
    # teeth on lower edge
    nx, ny = -dy, dx
    for i in range(teeth):
        t = 0.15 + i / teeth * 0.8
        tx = round(bx + (ex - bx) * t)
        ty = round(by + (ey - by) * t)
        pset(img, round(tx + nx * 2), round(ty + ny * 2), STEEL)
        pset(img, round(tx + nx * 3), round(ty + ny * 3), WHITE)
    # blood groove
    line(
        img,
        round(bx + dx * 2),
        round(by + dy * 2),
        round(ex - dx * 3),
        round(ey - dy * 3),
        BLOOD if form == "long" else STEEL_D,
        1,
    )
    return ex, ey


def draw_pistol(img, hx, hy, ang):
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    ex = round(hx + dx * 14)
    ey = round(hy + dy * 14)
    line(img, hx, hy, ex, ey, BRASS, 3)
    line(img, hx, hy + 1, round(hx + dx * 5), round(hy + dy * 5 + 3), BOOT, 2)
    disc(img, ex, ey, 2, GOLD)
    return ex, ey


def draw_hunter(pose: dict) -> Image.Image:
    img = new(96, 80)
    # origin: feet near (40, 74)
    fx = pose.get("x", 40)
    fy = pose.get("y", 74)
    facing = pose.get("facing", 1)
    form = pose.get("form", "short")
    show_gun = pose.get("gun", False)
    smear = pose.get("smear", 0)
    crouch = pose.get("crouch", 0)
    body_lean = pose.get("lean", 0)
    breath = pose.get("breath", 0)

    def X(x):
        return fx + (x - 40) * facing + fx - fx

    # We'll draw in local space then maybe flip
    canvas = new(96, 80)
    ox, oy = 40, 74 - crouch
    hip_x = ox + body_lean
    hip_y = oy - 22 + breath
    chest_x = hip_x + pose.get("chest", 1)
    chest_y = hip_y - 12
    head_x = chest_x + pose.get("head_x", 2)
    head_y = chest_y - 11

    # smear ghosts
    if smear:
        for i in range(smear):
            put(canvas, hip_x - 6 - i * 4, hip_y - 8, (*COAT[:3], 50), 10, 16)

    # legs
    l_ang = pose.get("lleg", 80)
    r_ang = pose.get("rleg", 100)
    l_len = pose.get("llen", 16)
    r_len = pose.get("rlen", 16)
    lx, ly = limb(canvas, hip_x - 2, hip_y, l_len, l_ang, 4, PANTS, 0.2)
    rx, ry = limb(canvas, hip_x + 2, hip_y, r_len, r_ang, 4, PANTS, 0.2)
    # boots
    put(canvas, lx - 1, ly - 1, BOOT, 7, 4)
    put(canvas, rx - 1, ry - 1, BOOT, 7, 4)
    pset(canvas, lx + 5, ly, GOLD_DIM)
    pset(canvas, rx + 5, ry, GOLD_DIM)

    # coat tails
    flare = pose.get("flare", 4)
    for i in range(14):
        put(canvas, hip_x - 6 - flare // 2, hip_y - 2 + i, COAT, 14 + flare, 1)
        if i > 6:
            put(canvas, hip_x - 7 - flare // 2, hip_y - 2 + i, LINING, 3, 1)
    put(canvas, hip_x - 5, hip_y - 10, COAT, 12, 14)
    put(canvas, hip_x - 4, hip_y - 9, COAT_L, 4, 8)
    # crimson hem stitch
    put(canvas, hip_x - 6 - flare // 2, hip_y + 10, CRIMSON, 14 + flare, 1)

    # torso / shirt peek
    put(canvas, chest_x - 4, chest_y - 2, SHIRT, 7, 8)
    put(canvas, chest_x - 5, chest_y - 4, COAT, 11, 10)
    put(canvas, chest_x + 3, chest_y - 2, GOLD_DIM, 1, 5)

    # back arm (left)
    la = pose.get("larm", 40)
    lhand = limb(canvas, chest_x - 3, chest_y, 11, la, 3, COAT)
    disc(canvas, lhand[0], lhand[1], 2, SKIN_D)

    # head
    oval(canvas, head_x, head_y, 5, 6, PALE)
    oval(canvas, head_x - 1, head_y + 1, 4, 5, SKIN_D)
    oval(canvas, head_x + 1, head_y, 4, 5, PALE)
    # hair
    put(canvas, head_x - 5, head_y - 5, HAIR, 10, 4)
    put(canvas, head_x - 6, head_y - 2, HAIR, 3, 6)
    # eye
    pset(canvas, head_x + 3, head_y, VOID)
    pset(canvas, head_x + 4, head_y, GOLD)
    # grim mouth
    put(canvas, head_x + 1, head_y + 3, BLOOD, 3, 1)
    # tricorn
    put(canvas, head_x - 8, head_y - 6, VOID, 16, 3)
    put(canvas, head_x - 5, head_y - 10, VOID, 11, 5)
    put(canvas, head_x - 4, head_y - 9, GOLD_DIM, 9, 1)
    pset(canvas, head_x + 6, head_y - 7, GOLD)

    # front arm
    ra = pose.get("rarm", 20)
    rhand = limb(canvas, chest_x + 3, chest_y, pose.get("rarm_len", 12), ra, 3, COAT_L)
    disc(canvas, rhand[0], rhand[1], 2, PALE)

    if show_gun:
        muzzle = draw_pistol(canvas, rhand[0], rhand[1], pose.get("gun_ang", 0))
        if pose.get("flash"):
            disc(canvas, muzzle[0] + 3, muzzle[1], 4, LANTERN)
            disc(canvas, muzzle[0] + 3, muzzle[1], 2, WHITE)
    else:
        draw_saw(canvas, rhand[0], rhand[1], form, pose.get("swing", 0))

    # holster
    put(canvas, hip_x + 4, hip_y - 4, BOOT, 4, 6)
    put(canvas, hip_x + 5, hip_y - 3, BRASS, 2, 3)

    if facing < 0:
        canvas = canvas.transpose(Image.FLIP_LEFT_RIGHT)
    img.alpha_composite(canvas)
    return img


def hunter_frames() -> dict[str, list[Image.Image]]:
    sets: dict[str, list[Image.Image]] = {}

    def add(name, poses):
        sets[name] = [draw_hunter(p) for p in poses]

    add(
        "idle_short",
        [
            {"breath": i % 2, "flare": 3 + (i % 2), "swing": -12, "form": "short", "larm": 55, "rarm": 15, "lleg": 82, "rleg": 98}
            for i in range(4)
        ],
    )
    add(
        "idle_long",
        [
            {"breath": i % 2, "flare": 4, "swing": -25, "form": "long", "larm": 60, "rarm": 8, "rarm_len": 13, "lleg": 82, "rleg": 98}
            for i in range(4)
        ],
    )
    walk = []
    for i in range(6):
        ph = i / 6 * math.tau
        walk.append(
            {
                "form": "short",
                "swing": -8,
                "lean": int(math.sin(ph) * 1),
                "lleg": 70 + math.sin(ph) * 28,
                "rleg": 70 + math.sin(ph + math.pi) * 28,
                "llen": 15 + (1 if math.cos(ph) > 0 else 0),
                "rlen": 15 + (1 if math.cos(ph + math.pi) > 0 else 0),
                "larm": 40 + math.sin(ph + math.pi) * 20,
                "rarm": 10 + math.sin(ph) * 12,
                "flare": 5,
            }
        )
    add("walk_short", walk)
    walk_l = []
    for p in walk:
        q = dict(p)
        q["form"] = "long"
        q["swing"] = -22
        walk_l.append(q)
    add("walk_long", walk_l)

    add(
        "dodge",
        [
            {"crouch": 4, "lean": 6, "smear": 1, "form": "short", "swing": 20, "lleg": 40, "rleg": 120, "larm": 0, "rarm": 40, "flare": 8},
            {"crouch": 8, "lean": 10, "smear": 3, "form": "short", "swing": 40, "lleg": 20, "rleg": 150, "larm": -20, "rarm": 60, "flare": 10},
            {"crouch": 6, "lean": 8, "smear": 2, "form": "short", "swing": 10, "lleg": 50, "rleg": 110, "flare": 7},
            {"crouch": 2, "lean": 3, "smear": 1, "form": "short", "swing": -10, "lleg": 80, "rleg": 100, "flare": 4},
        ],
    )
    add(
        "attack_short_1",
        [
            {"form": "short", "swing": 130, "rarm": -50, "larm": 80, "lean": -3, "crouch": 2, "flare": 6},
            {"form": "short", "swing": 70, "rarm": -10, "larm": 70, "lean": 0, "flare": 5},
            {"form": "short", "swing": 10, "rarm": 20, "rarm_len": 14, "lean": 4, "flare": 8},
            {"form": "short", "swing": -20, "rarm": 30, "lean": 5, "flare": 7},
            {"form": "short", "swing": -8, "rarm": 18, "lean": 2, "flare": 4},
        ],
    )
    add(
        "attack_short_2",
        [
            {"form": "short", "swing": -40, "rarm": 50, "larm": 20, "lean": 3, "crouch": 1},
            {"form": "short", "swing": 20, "rarm": 10, "lean": 1},
            {"form": "short", "swing": 90, "rarm": -30, "lean": -2, "crouch": 2, "flare": 8},
            {"form": "short", "swing": 150, "rarm": -70, "lean": -4, "flare": 6},
            {"form": "short", "swing": 100, "rarm": -20, "lean": -1},
        ],
    )
    add(
        "attack_long",
        [
            {"form": "long", "swing": 160, "rarm": -80, "rarm_len": 14, "larm": 90, "lean": -5, "crouch": 3, "flare": 5},
            {"form": "long", "swing": 90, "rarm": -20, "lean": 0, "flare": 6},
            {"form": "long", "swing": 20, "rarm": 15, "rarm_len": 15, "lean": 6, "flare": 10},
            {"form": "long", "swing": -10, "rarm": 25, "lean": 7, "flare": 9},
            {"form": "long", "swing": 5, "rarm": 18, "lean": 3, "flare": 6},
            {"form": "long", "swing": -20, "rarm": 10, "lean": 1},
        ],
    )
    add(
        "transform",
        [
            {"form": "short", "swing": 40, "rarm": 0, "lean": 0, "flare": 5},
            {"form": "short", "swing": 100, "rarm": -40, "lean": -2, "flare": 8},
            {"form": "long", "swing": 20, "rarm": 10, "rarm_len": 14, "lean": 5, "flare": 10},
            {"form": "long", "swing": -15, "rarm": 20, "lean": 4, "flare": 7},
            {"form": "long", "swing": -22, "rarm": 8, "lean": 1},
        ],
    )
    add(
        "gun",
        [
            {"gun": True, "gun_ang": -10, "rarm": 0, "rarm_len": 14, "lean": -2, "form": "short", "larm": 70, "crouch": 1},
            {"gun": True, "gun_ang": 0, "flash": True, "rarm": 5, "rarm_len": 15, "lean": 3, "smear": 1},
            {"gun": True, "gun_ang": 8, "rarm": 8, "lean": 2},
            {"gun": True, "gun_ang": 0, "rarm": 0, "lean": 0},
        ],
    )
    add(
        "visceral",
        [
            {"crouch": 6, "lean": 8, "form": "short", "swing": 80, "lleg": 40, "rleg": 130, "flare": 9},
            {"crouch": 2, "lean": 10, "form": "short", "swing": 20, "rarm": 10, "smear": 2},
            {"lean": 6, "form": "short", "swing": -10, "rarm": 30, "rarm_len": 14, "flare": 8},
            {"lean": 4, "form": "short", "swing": 60, "rarm": -10, "flare": 10},
            {"lean": 2, "form": "short", "swing": 120, "rarm": -40},
            {"lean": 0, "form": "short", "swing": 40, "rarm": 0, "flare": 4},
        ],
    )
    add(
        "hurt",
        [
            {"lean": -6, "crouch": 3, "form": "short", "swing": 50, "rarm": -20, "larm": 90, "flare": 8, "lleg": 60, "rleg": 120},
            {"lean": -3, "crouch": 1, "form": "short", "swing": 20, "flare": 5},
        ],
    )
    add(
        "death",
        [
            {"lean": -4, "crouch": 4, "form": "short", "swing": 80, "lleg": 50, "rleg": 130},
            {"lean": -8, "crouch": 10, "form": "short", "swing": 100, "head_x": 0, "chest": 0},
            {"crouch": 16, "lean": -10, "form": "short", "swing": 140, "head_x": -2, "y": 76},
            {"crouch": 20, "form": "short", "swing": 170, "y": 78, "head_x": -4, "larm": 160, "rarm": 20},
        ],
    )
    return sets


# ---------------------------------------------------------------------------
# Beast
# ---------------------------------------------------------------------------
def draw_beast(pose: dict) -> Image.Image:
    img = new(96, 64)
    ox, oy = pose.get("x", 48), pose.get("y", 58)
    crouch = pose.get("crouch", 0)
    stretch = pose.get("stretch", 0)
    open_jaw = pose.get("jaw", 2)
    body_x = ox + pose.get("lean", 0)
    body_y = oy - 16 - crouch

    # hind legs
    h1 = limb(img, body_x - 10, body_y + 6, 14 + pose.get("hleg", 0), 80 + pose.get("h1", 0), 4, BEAST_D)
    h2 = limb(img, body_x - 4, body_y + 6, 14 + pose.get("hleg", 0), 100 + pose.get("h2", 0), 4, BEAST)
    put(img, h1[0] - 2, h1[1], BEAST_D, 6, 3)
    put(img, h2[0] - 2, h2[1], BEAST, 6, 3)
    # body
    oval(img, body_x, body_y, 16 + stretch, 10, BEAST)
    oval(img, body_x - 2, body_y + 2, 12, 7, BEAST_D)
    # spine
    for i in range(5):
        pset(img, body_x - 8 + i * 4, body_y - 9 - (i % 2), FUR)
        pset(img, body_x - 8 + i * 4, body_y - 10 - (i % 2), BEAST_L)
    # forelegs
    f1 = limb(img, body_x + 8, body_y + 2, 16 + pose.get("fleg", 0), pose.get("f1", 70), 4, BEAST_L)
    f2 = limb(img, body_x + 12, body_y + 4, 15, pose.get("f2", 95), 3, BEAST)
    # claws
    for hx, hy in (f1, f2):
        line(img, hx, hy, hx + 5, hy + 2, STEEL, 1)
        line(img, hx, hy, hx + 4, hy + 4, STEEL, 1)
        pset(img, hx + 5, hy + 2, CRIMSON)
    # neck + head
    nx = body_x + 14 + pose.get("neck", 0)
    ny = body_y - 4 + pose.get("head_y", 0)
    oval(img, nx, ny, 8, 6, BEAST_L)
    # jaw
    oval(img, nx + 6, ny + 1, 7, 4 + open_jaw, BEAST_D)
    put(img, nx + 4, ny + 2, CRIMSON, 8, 2 + open_jaw)
    for i in range(4):
        pset(img, nx + 5 + i * 2, ny + 1, WHITE)
        pset(img, nx + 6 + i * 2, ny + 3 + open_jaw, WHITE)
    # eye
    pset(img, nx + 2, ny - 2, VOID)
    pset(img, nx + 3, ny - 2, GOLD)
    pset(img, nx + 3, ny - 3, WHITE)
    # ear
    put(img, nx - 4, ny - 8, BEAST_D, 3, 5)
    if pose.get("flash"):
        disc(img, nx + 10, ny, 4, CRIMSON)
    return img


def beast_frames() -> dict[str, list[Image.Image]]:
    sets = {}
    sets["idle"] = [
        draw_beast({"jaw": 1 + i % 2, "h1": -i, "h2": i, "head_y": i % 2}) for i in range(4)
    ]
    walk = []
    for i in range(6):
        ph = i / 6 * math.tau
        walk.append(
            draw_beast(
                {
                    "lean": int(math.sin(ph) * 2),
                    "h1": math.sin(ph) * 20,
                    "h2": math.sin(ph + math.pi) * 20,
                    "f1": 60 + math.sin(ph + math.pi) * 25,
                    "f2": 90 + math.sin(ph) * 20,
                    "jaw": 2,
                }
            )
        )
    sets["walk"] = walk
    sets["swipe"] = [
        draw_beast({"lean": -4, "f1": 200, "f2": 180, "jaw": 1, "crouch": 2}),
        draw_beast({"lean": -2, "f1": 240, "f2": 210, "jaw": 3, "stretch": 2}),
        draw_beast({"lean": 6, "f1": 20, "f2": 40, "jaw": 4, "stretch": 4, "flash": True}),
        draw_beast({"lean": 4, "f1": 50, "f2": 70, "jaw": 3}),
        draw_beast({"lean": 0, "f1": 70, "jaw": 2}),
    ]
    sets["lunge"] = [
        draw_beast({"crouch": 6, "stretch": -2, "lean": -6, "jaw": 1, "f1": 120}),
        draw_beast({"crouch": 4, "stretch": 2, "lean": 0, "jaw": 3}),
        draw_beast({"crouch": 0, "stretch": 8, "lean": 12, "jaw": 5, "f1": 10, "fleg": 6, "flash": True}),
        draw_beast({"stretch": 4, "lean": 8, "jaw": 3, "f1": 40}),
        draw_beast({"stretch": 0, "lean": 2, "jaw": 2}),
    ]
    sets["stagger"] = [
        draw_beast({"lean": -8, "jaw": 5, "head_y": 3, "crouch": 3, "f1": 140}),
        draw_beast({"lean": -4, "jaw": 3, "crouch": 1}),
    ]
    sets["death"] = [
        draw_beast({"lean": -6, "crouch": 4, "jaw": 4, "head_y": 4}),
        draw_beast({"lean": -10, "crouch": 10, "jaw": 5, "y": 60}),
        draw_beast({"lean": -12, "crouch": 14, "jaw": 2, "y": 62, "head_y": 8}),
        draw_beast({"crouch": 18, "y": 63, "head_y": 10, "jaw": 0, "lean": -8}),
    ]
    return sets


# ---------------------------------------------------------------------------
# Executioner (elite)
# ---------------------------------------------------------------------------
def draw_greatsword(img, hx, hy, ang):
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    ex = round(hx + dx * 42)
    ey = round(hy + dy * 42)
    line(img, hx, hy, round(hx + dx * 8), round(hy + dy * 8), BOOT, 3)
    line(img, round(hx + dx * 8), round(hy + dy * 8), ex, ey, STEEL_D, 6)
    line(img, round(hx + dx * 8), round(hy + dy * 8 - 1), ex, ey - 1, STEEL, 3)
    put(img, round(hx + dx * 7 - 3), round(hy + dy * 7), GOLD_DIM, 7, 3)
    return ex, ey


def draw_executioner(pose: dict) -> Image.Image:
    img = new(112, 96)
    ox, oy = 50, 90 - pose.get("crouch", 0)
    lean = pose.get("lean", 0)
    hip_x, hip_y = ox + lean, oy - 26
    chest_x, chest_y = hip_x + 1, hip_y - 14
    head_x, head_y = chest_x + 1, chest_y - 14

    l_ang, r_ang = pose.get("lleg", 80), pose.get("rleg", 100)
    lx, ly = limb(img, hip_x - 3, hip_y, 20, l_ang, 5, IRON)
    rx, ry = limb(img, hip_x + 3, hip_y, 20, r_ang, 5, IRON)
    put(img, lx - 2, ly - 1, VOID, 9, 4)
    put(img, rx - 2, ry - 1, VOID, 9, 4)

    # skirt / shawl
    put(img, hip_x - 10, hip_y - 8, SHAWL, 22, 20)
    put(img, hip_x - 9, hip_y - 6, WHITE, 6, 14)
    put(img, hip_x + 2, hip_y + 6, BLOOD, 8, 3)

    # cuirass
    put(img, chest_x - 8, chest_y - 4, IRON, 18, 16)
    put(img, chest_x - 6, chest_y - 2, STEEL_D, 12, 10)
    put(img, chest_x, chest_y, GOLD_DIM, 2, 8)

    # arms
    la = pose.get("larm", 70)
    ra = pose.get("rarm", 50)
    lhand = limb(img, chest_x - 6, chest_y, 14, la, 4, IRON)
    rhand = limb(img, chest_x + 6, chest_y, pose.get("rarm_len", 14), ra, 4, IRON)
    disc(img, lhand[0], lhand[1], 2, MASK)
    disc(img, rhand[0], rhand[1], 2, MASK)
    draw_greatsword(img, rhand[0], rhand[1], pose.get("swing", 80))

    # head / beak mask
    oval(img, head_x, head_y, 6, 7, MASK)
    put(img, head_x + 4, head_y, MASK, 10, 4)
    put(img, head_x + 10, head_y + 1, VOID, 6, 3)
    pset(img, head_x + 2, head_y - 1, GOLD)
    # hood
    put(img, head_x - 7, head_y - 8, SHAWL, 16, 6)
    put(img, head_x - 8, head_y - 4, SHAWL, 5, 10)
    return img


def executioner_frames() -> dict[str, list[Image.Image]]:
    sets = {}
    sets["idle"] = [
        draw_executioner({"swing": 78 + i, "breath": i, "lleg": 82, "rleg": 98, "larm": 75, "rarm": 70})
        for i in range(4)
    ]
    walk = []
    for i in range(6):
        ph = i / 6 * math.tau
        walk.append(
            draw_executioner(
                {
                    "lean": int(math.sin(ph)),
                    "lleg": 70 + math.sin(ph) * 22,
                    "rleg": 70 + math.sin(ph + math.pi) * 22,
                    "swing": 80,
                    "larm": 70,
                    "rarm": 65,
                }
            )
        )
    sets["walk"] = walk
    sets["slash"] = [
        draw_executioner({"swing": 200, "rarm": -70, "lean": -4, "crouch": 2, "larm": 100}),
        draw_executioner({"swing": 140, "rarm": -20, "lean": 0}),
        draw_executioner({"swing": 40, "rarm": 20, "rarm_len": 16, "lean": 6, "crouch": 1}),
        draw_executioner({"swing": 10, "rarm": 30, "lean": 5}),
        draw_executioner({"swing": 70, "rarm": 10, "lean": 1}),
    ]
    sets["shoot"] = [
        draw_executioner({"swing": 90, "larm": 10, "rarm": 80, "lean": -2}),
        draw_executioner({"swing": 90, "larm": 0, "lean": 2}),
        draw_executioner({"swing": 85, "larm": 15}),
    ]
    sets["stagger"] = [
        draw_executioner({"lean": -8, "crouch": 4, "swing": 120, "rarm": -20}),
        draw_executioner({"lean": -3, "crouch": 1, "swing": 90}),
    ]
    sets["death"] = [
        draw_executioner({"lean": -6, "crouch": 6, "swing": 130}),
        draw_executioner({"lean": -10, "crouch": 14, "swing": 160}),
        draw_executioner({"crouch": 22, "swing": 180, "larm": 140}),
        draw_executioner({"crouch": 26, "swing": 190}),
    ]
    return sets


# ---------------------------------------------------------------------------
# Boss preacher
# ---------------------------------------------------------------------------
def draw_boss(pose: dict) -> Image.Image:
    img = new(128, 160)
    ox, oy = 58, 150 - pose.get("crouch", 0)
    lean = pose.get("lean", 0)
    hip_x, hip_y = ox + lean, oy - 40
    chest_x, chest_y = hip_x + pose.get("chest", 0), hip_y - 28
    head_x, head_y = chest_x, chest_y - 22 + pose.get("head_y", 0)

    # legs
    limb(img, hip_x - 6, hip_y, 32, pose.get("lleg", 78), 5, ROBE)
    limb(img, hip_x + 6, hip_y, 32, pose.get("rleg", 102), 5, ROBE)
    put(img, hip_x - 16, hip_y - 6, ROBE, 34, 40)
    put(img, hip_x - 14, hip_y + 20, ROBE_G, 30, 2)
    put(img, hip_x - 10, hip_y + 8, BLOOD, 8, 12)

    # ribs / torso
    oval(img, chest_x, chest_y, 12, 16, BOSS_SKIN)
    put(img, chest_x - 10, chest_y - 8, ROBE, 22, 24)
    put(img, chest_x - 4, chest_y - 4, BOSS_SKIN, 8, 14)
    for i in range(4):
        put(img, chest_x - 3, chest_y - 2 + i * 3, VOID, 8, 1)

    # arms + censer staff
    la = pose.get("larm", 50)
    ra = pose.get("rarm", 40)
    lhand = limb(img, chest_x - 8, chest_y - 4, 22, la, 3, BOSS_SKIN)
    rhand = limb(img, chest_x + 8, chest_y - 4, 22, ra, 3, BOSS_SKIN)
    # staff
    a = math.radians(pose.get("staff", -80))
    sx, sy = rhand
    ex = round(sx + math.cos(a) * 50)
    ey = round(sy + math.sin(a) * 50)
    line(img, sx, sy, ex, ey, GOLD_DIM, 3)
    line(img, sx, sy, ex, ey, ROBE_G, 1)
    disc(img, ex, ey, 7, IRON)
    disc(img, ex, ey, 5, GOLD)
    if pose.get("censer_lit"):
        disc(img, ex, ey, 9, (*LANTERN[:3], 180))
        disc(img, ex - 2, ey - 10, 3, CRIMSON)
        disc(img, ex + 3, ey - 14, 2, GOLD)

    # head
    oval(img, head_x, head_y, 8, 10, BOSS_SKIN)
    put(img, head_x - 3, head_y + 2, VOID, 4, 3)
    pset(img, head_x + 3, head_y, CRIMSON)
    pset(img, head_x + 4, head_y - 1, GOLD)
    # mitre + antlers
    put(img, head_x - 8, head_y - 14, ROBE_G, 16, 10)
    put(img, head_x - 6, head_y - 18, ROBE, 12, 6)
    put(img, head_x - 4, head_y - 16, GOLD, 8, 2)
    # antlers
    line(img, head_x - 6, head_y - 16, head_x - 16, head_y - 28, BOSS_SKIN, 2)
    line(img, head_x - 12, head_y - 22, head_x - 18, head_y - 20, BOSS_SKIN, 2)
    line(img, head_x + 6, head_y - 16, head_x + 16, head_y - 30, BOSS_SKIN, 2)
    line(img, head_x + 12, head_y - 24, head_x + 20, head_y - 22, BOSS_SKIN, 2)
    return img


def boss_frames() -> dict[str, list[Image.Image]]:
    sets = {}
    sets["idle"] = [
        draw_boss({"censer_lit": i % 2 == 0, "head_y": i % 2, "staff": -82 + i, "larm": 48 + i, "rarm": 38})
        for i in range(4)
    ]
    sets["slam"] = [
        draw_boss({"staff": -140, "rarm": -60, "larm": 80, "crouch": 4, "lean": -4}),
        draw_boss({"staff": -100, "rarm": -20, "crouch": 2}),
        draw_boss({"staff": -20, "rarm": 30, "censer_lit": True, "lean": 8, "crouch": 6}),
        draw_boss({"staff": 10, "rarm": 40, "censer_lit": True, "lean": 6}),
        draw_boss({"staff": -60, "rarm": 10, "censer_lit": True}),
    ]
    sets["sweep"] = [
        draw_boss({"staff": 160, "rarm": -40, "lean": -6, "larm": 20}),
        draw_boss({"staff": 80, "rarm": 0, "censer_lit": True}),
        draw_boss({"staff": 10, "rarm": 40, "lean": 8, "censer_lit": True}),
        draw_boss({"staff": -40, "rarm": 20, "lean": 2, "censer_lit": True}),
    ]
    sets["cast"] = [
        draw_boss({"staff": -90, "censer_lit": True, "head_y": -2, "chest": 0}),
        draw_boss({"staff": -90, "censer_lit": True, "head_y": -4, "larm": 20, "rarm": 20}),
        draw_boss({"staff": -90, "censer_lit": True, "larm": 10, "rarm": 10}),
    ]
    sets["stagger"] = [
        draw_boss({"lean": -10, "crouch": 6, "staff": -40, "head_y": 4}),
        draw_boss({"lean": -4, "crouch": 2, "staff": -70}),
    ]
    sets["death"] = [
        draw_boss({"lean": -8, "crouch": 8, "staff": 20, "head_y": 6}),
        draw_boss({"lean": -12, "crouch": 16, "staff": 40}),
        draw_boss({"crouch": 28, "staff": 70, "head_y": 10}),
        draw_boss({"crouch": 36, "staff": 90}),
    ]
    return sets


# ---------------------------------------------------------------------------
# Tiles, backdrop, UI, FX
# ---------------------------------------------------------------------------
def tile_cobble() -> Image.Image:
    img = new(32, 32)
    rnd = 0xA5
    for y in range(32):
        for x in range(32):
            rnd = (rnd * 1103515245 + 12345 + x * 17 + y * 31) & 0x7FFFFFFF
            n = (rnd >> 8) & 7
            base = COBBLE if ((x // 8 + y // 6) % 2 == 0) else COBBLE_D
            if n < 2:
                base = COBBLE_L
            if n == 7:
                base = MOSS
            pset(img, x, y, base)
    # grout lines that wrap
    for y in range(0, 32, 6):
        for x in range(32):
            pset(img, x, y, COBBLE_D)
    for x in range(0, 32, 8):
        for y in range(32):
            if (y + x) % 6:
                pset(img, x, y, (*COBBLE_D[:3], 200))
    # wet specks
    for i in range(12):
        pset(img, (i * 7 + 3) % 32, (i * 13 + 5) % 32, (*NAVY[:3], 180))
    return img


def tile_brick() -> Image.Image:
    img = new(32, 32)
    for y in range(32):
        for x in range(32):
            row = y // 8
            shift = (row % 2) * 8
            pset(img, x, y, STONE if ((x + shift) // 16 + row) % 2 == 0 else COBBLE)
    for y in range(0, 32, 8):
        for x in range(32):
            pset(img, x, y, COBBLE_D)
    for y in range(32):
        row = y // 8
        shift = (row % 2) * 8
        for x in range(shift, 32, 16):
            pset(img, x % 32, y, COBBLE_D)
    for i in range(8):
        pset(img, (i * 11) % 32, (i * 5 + 2) % 32, MOSS)
    return img


def prop_lantern() -> Image.Image:
    img = new(32, 64)
    line(img, 15, 0, 15, 18, IRON, 2)
    put(img, 8, 18, IRON, 16, 3)
    put(img, 10, 21, GOLD_DIM, 12, 16)
    put(img, 12, 23, LANTERN, 8, 12)
    put(img, 14, 25, WHITE, 4, 6)
    put(img, 10, 37, IRON, 12, 3)
    disc(img, 16, 28, 10, (*LANTERN[:3], 40))
    return img


def prop_fence() -> Image.Image:
    img = new(48, 40)
    for x in range(4, 44, 8):
        line(img, x, 8, x, 38, IRON, 2)
        pset(img, x, 6, STEEL_D)
        pset(img, x, 5, STEEL)
    line(img, 4, 18, 44, 18, IRON, 2)
    line(img, 4, 28, 44, 28, IRON, 2)
    return img


def backdrop() -> Image.Image:
    w, h = 480, 180
    img = new(w, h)
    for y in range(h):
        t = y / h
        r = int(10 + t * 18)
        g = int(8 + t * 14)
        b = int(18 + t * 22)
        put(img, 0, y, (r, g, b, 255), w, 1)
    # moon
    disc(img, 380, 36, 14, (220, 214, 190, 255))
    disc(img, 384, 34, 10, (16, 14, 28, 255))
    # distant spires
    spires = [(40, 110, 18, 70), (90, 100, 22, 80), (160, 120, 14, 55), (220, 90, 28, 90),
              (300, 115, 16, 60), (340, 85, 24, 95), (430, 108, 20, 70)]
    for x, y, bw, bh in spires:
        put(img, x, y, (18, 16, 28, 255), bw, bh)
        put(img, x + bw // 2 - 2, y - 22, (14, 12, 22, 255), 4, 22)
        pset(img, x + bw // 2, y - 24, GOLD_DIM)
        # windows
        for wy in range(y + 8, y + bh - 8, 10):
            for wx in range(x + 3, x + bw - 3, 6):
                pset(img, wx, wy, GOLD_DIM if (wx + wy) % 7 else LANTERN)
    # fog bands
    fog = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    fd.rectangle([0, 130, w, h], fill=(40, 44, 60, 70))
    fd.rectangle([0, 150, w, h], fill=(30, 32, 48, 90))
    img.alpha_composite(fog)
    return img


def ui_panel() -> Image.Image:
    img = new(160, 96)
    put(img, 0, 0, UI_BG, 160, 96)
    put(img, 2, 2, GOLD_DIM, 156, 92)
    put(img, 4, 4, UI_BG, 152, 88)
    put(img, 4, 4, GOLD, 8, 2)
    put(img, 148, 4, GOLD, 8, 2)
    put(img, 4, 90, GOLD, 8, 2)
    put(img, 148, 90, GOLD, 8, 2)
    put(img, 8, 8, LINING, 144, 2)
    return img


def ui_bar_frame() -> Image.Image:
    img = new(128, 12)
    put(img, 0, 0, VOID, 128, 12)
    put(img, 1, 1, GOLD_DIM, 126, 10)
    put(img, 2, 2, (40, 16, 18, 255), 124, 8)
    return img


def ui_button() -> Image.Image:
    img = new(48, 48)
    disc(img, 24, 24, 22, VOID)
    disc(img, 24, 24, 20, GOLD_DIM)
    disc(img, 24, 24, 17, UI_BG)
    disc(img, 24, 24, 15, COAT)
    return img


def fx_slash() -> Image.Image:
    img = new(48, 32)
    line(img, 2, 24, 40, 6, WHITE, 2)
    line(img, 4, 26, 42, 8, CRIMSON, 3)
    line(img, 6, 22, 38, 10, STEEL, 1)
    return img


def fx_parry() -> Image.Image:
    img = new(32, 32)
    disc(img, 16, 16, 12, (*LANTERN[:3], 120))
    disc(img, 16, 16, 6, WHITE)
    for a in range(0, 360, 45):
        limb(img, 16, 16, 14, a, 1, GOLD)
    return img


def fx_blood() -> Image.Image:
    img = new(24, 24)
    disc(img, 10, 10, 4, CRIMSON)
    disc(img, 14, 8, 3, BLOOD)
    pset(img, 18, 6, CRIMSON)
    pset(img, 6, 14, BLOOD)
    pset(img, 16, 16, CRIMSON)
    return img


def sheet(frames: list[Image.Image], pad=0) -> Image.Image:
    w, h = frames[0].size
    img = new((w + pad) * len(frames), h)
    for i, f in enumerate(frames):
        img.alpha_composite(f, ((w + pad) * i, 0))
    return img


def write_frames(prefix: Path, anim: str, frames: list[Image.Image], collected: dict) -> None:
    d = ensure(prefix / anim)
    names = []
    for i, f in enumerate(frames):
        name = f"{i:02d}.png"
        save(f, d / name)
        names.append(f"{prefix.name}/{anim}/{name}")
    save(sheet(frames), prefix / f"{anim}_sheet.png")
    collected[f"{prefix.name}/{anim}"] = {
        "count": len(frames),
        "w": frames[0].size[0],
        "h": frames[0].size[1],
        "files": names,
    }


def contact(groups: list[tuple[str, list[Image.Image]]]) -> Image.Image:
    rows = []
    max_w = 0
    total_h = 8
    for title, frames in groups:
        sh = sheet(frames, 2)
        rows.append(sh)
        max_w = max(max_w, sh.size[0] + 8)
        total_h += sh.size[1] + 10
    img = Image.new("RGBA", (max(max_w, 64), total_h), INDIGO)
    y = 4
    for sh in rows:
        img.alpha_composite(sh, (4, y))
        y += sh.size[1] + 10
    return img


def main() -> None:
    for p in (OUT, PREVIEW_IMG):
        ensure(p)
    manifest: dict = {"anims": {}, "tiles": {}, "ui": {}, "fx": {}}

    hunter = hunter_frames()
    hp = ensure(OUT / "hunter")
    for k, fr in hunter.items():
        write_frames(hp, k, fr, manifest["anims"])

    beast = beast_frames()
    bp = ensure(OUT / "beast")
    for k, fr in beast.items():
        write_frames(bp, k, fr, manifest["anims"])

    exe = executioner_frames()
    ep = ensure(OUT / "executioner")
    for k, fr in exe.items():
        write_frames(ep, k, fr, manifest["anims"])

    boss = boss_frames()
    bop = ensure(OUT / "boss")
    for k, fr in boss.items():
        write_frames(bop, k, fr, manifest["anims"])

    tiles = {
        "cobble": tile_cobble(),
        "brick": tile_brick(),
        "lantern": prop_lantern(),
        "fence": prop_fence(),
        "backdrop": backdrop(),
    }
    td = ensure(OUT / "world")
    for k, im in tiles.items():
        save(im, td / f"{k}.png")
        save(im, PREVIEW_IMG / f"{k}.png")
        manifest["tiles"][k] = {"w": im.size[0], "h": im.size[1]}

    ui = {"panel": ui_panel(), "bar": ui_bar_frame(), "button": ui_button()}
    ud = ensure(OUT / "ui")
    for k, im in ui.items():
        save(im, ud / f"{k}.png")
        manifest["ui"][k] = {"w": im.size[0], "h": im.size[1]}

    fx = {"slash": fx_slash(), "parry": fx_parry(), "blood": fx_blood()}
    fd = ensure(OUT / "fx")
    for k, im in fx.items():
        save(im, fd / f"{k}.png")
        manifest["fx"][k] = {"w": im.size[0], "h": im.size[1]}

    # copy sheets into preview/img for the HTML build
    for who, data in (("hunter", hunter), ("beast", beast), ("executioner", exe), ("boss", boss)):
        for anim, frames in data.items():
            dest = ensure(PREVIEW_IMG / who / anim)
            for i, f in enumerate(frames):
                save(f, dest / f"{i:02d}.png")
            save(sheet(frames), PREVIEW_IMG / who / f"{anim}_sheet.png")

    groups = []
    for name, fr in hunter.items():
        groups.append((name, fr))
    save(contact(groups), PREVIEW_IMG / "sheet_hunter.png")
    save(contact(list(beast.items())), PREVIEW_IMG / "sheet_beast.png")
    save(contact(list(exe.items())), PREVIEW_IMG / "sheet_executioner.png")
    save(contact(list(boss.items())), PREVIEW_IMG / "sheet_boss.png")

    # 2x2 cobble seam check
    c = tiles["cobble"]
    chk = new(64, 64)
    for y in range(2):
        for x in range(2):
            chk.alpha_composite(c, (x * 32, y * 32))
    save(chk, PREVIEW_IMG / "cobble_2x2.png")

    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    (PREVIEW_IMG / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print("wrote", OUT)
    print("anims", len(manifest["anims"]))


if __name__ == "__main__":
    main()
