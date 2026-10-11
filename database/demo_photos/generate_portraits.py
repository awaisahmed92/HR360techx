"""Original illustrated headshots for the HR360 demo directory.

Writes m00.png–m39.png and f00.png–f39.png next to this script.
These are drawn here; they are not photographs of real people.
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
SIZE = 640

SKINS = [
    (255, 224, 198), (244, 204, 168), (232, 184, 142), (214, 164, 122),
    (196, 142, 102), (168, 114, 80), (140, 92, 64), (112, 74, 52),
    (232, 190, 170), (186, 132, 108),
]
HAIR = [
    (32, 24, 20), (58, 38, 26), (92, 58, 32), (128, 78, 42),
    (168, 122, 64), (48, 40, 36), (20, 20, 22), (150, 72, 48),
]
SHIRTS = [
    (27, 58, 110), (18, 92, 86), (72, 42, 64), (48, 56, 68),
    (150, 62, 48), (36, 78, 122), (58, 72, 48), (90, 48, 42),
    (32, 48, 72), (70, 70, 78),
]
BGS = [
    ((226, 234, 244), (198, 214, 232)),
    ((236, 228, 242), (214, 200, 226)),
    ((226, 242, 234), (196, 220, 206)),
    ((244, 236, 224), (226, 208, 188)),
    ((232, 236, 244), (206, 214, 230)),
    ((242, 230, 230), (224, 204, 204)),
    ((228, 240, 236), (198, 220, 214)),
    ((240, 236, 226), (220, 210, 190)),
]
EYES = [(50, 70, 90), (70, 50, 36), (40, 60, 50), (60, 48, 40)]


def shade(rgb, delta):
    return tuple(max(0, min(255, c + delta)) for c in rgb)


def ellipse(draw, box, fill):
    draw.ellipse(box, fill=fill)


def portrait(index: int, female: bool) -> Image.Image:
    skin = SKINS[index % len(SKINS)]
    hair = HAIR[(index * 3) % len(HAIR)]
    shirt = SHIRTS[(index * 5) % len(SHIRTS)]
    bg_a, bg_b = BGS[index % len(BGS)]
    eye = EYES[index % len(EYES)]
    style = index % 8
    glasses = index % 5 == 0
    beard = (not female) and index % 3 == 0
    face_w = 210 + (index % 5) * 8
    face_h = 250 + (index % 4) * 6

    im = Image.new("RGB", (SIZE, SIZE), bg_a)
    px = im.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        row = tuple(int(bg_a[c] * (1 - t) + bg_b[c] * t) for c in range(3))
        for x in range(SIZE):
            px[x, y] = row
    draw = ImageDraw.Draw(im)

    cx, cy = SIZE // 2, 292
    # shoulders and shirt
    ellipse(draw, [cx - 250, 470, cx + 250, 820], shade(shirt, -18))
    ellipse(draw, [cx - 210, 455, cx + 210, 760], shirt)
    # collar
    draw.polygon([(cx - 46, 500), (cx, 575), (cx + 46, 500)], fill=(245, 246, 248))
    draw.polygon([(cx - 18, 500), (cx, 548), (cx + 18, 500)], fill=shade(shirt, -28))

    # hair behind the head
    if female:
        if style in (0, 1):
            ellipse(draw, [cx - 200, 150, cx + 200, 620], hair)
        elif style == 2:
            ellipse(draw, [cx - 175, 120, cx + 175, 430], hair)
            ellipse(draw, [cx + 70, 250, cx + 210, 430], hair)
        elif style == 3:
            ellipse(draw, [cx - 190, 140, cx + 190, 520], shade(hair, 12))
        elif style == 4:
            ellipse(draw, [cx - 150, 90, cx + 150, 280], hair)
            ellipse(draw, [cx - 40, 40, cx + 90, 170], hair)
        else:
            ellipse(draw, [cx - 185, 145, cx + 185, 560], hair)
    else:
        if style == 7:
            pass
        elif style in (0, 1):
            ellipse(draw, [cx - 175, 105, cx + 175, 340], hair)
        elif style == 2:
            ellipse(draw, [cx - 168, 125, cx + 168, 300], hair)
        elif style == 3:
            ellipse(draw, [cx - 185, 115, cx + 185, 360], shade(hair, 8))
        else:
            ellipse(draw, [cx - 170, 118, cx + 150, 330], hair)

    # neck and face
    ellipse(draw, [cx - 52, 400, cx + 52, 530], shade(skin, -12))
    ellipse(draw, [cx - face_w // 2, cy - face_h // 2, cx + face_w // 2, cy + face_h // 2], skin)
    # ears
    ellipse(draw, [cx - face_w // 2 - 18, cy - 10, cx - face_w // 2 + 28, cy + 48], shade(skin, -8))
    ellipse(draw, [cx + face_w // 2 - 28, cy - 10, cx + face_w // 2 + 18, cy + 48], shade(skin, -8))

    # hairline sits on top of the face so the fringe stays a smooth cap
    if not (not female and style == 7):
        cap_bottom = 248 if style % 2 == 0 else 228
        ellipse(draw, [cx - 158, 108, cx + 158, cap_bottom], hair)
        # open the forehead again under the hairline
        ellipse(draw, [cx - face_w // 2 + 8, cy - 20, cx + face_w // 2 - 8, cy + face_h // 2], skin)

    # eyes
    eye_y = cy - 8
    gap = 52 + (index % 3) * 4
    for side in (-1, 1):
        ex = cx + side * gap
        ellipse(draw, [ex - 28, eye_y - 14, ex + 28, eye_y + 16], (255, 255, 255))
        ellipse(draw, [ex - 14, eye_y - 12, ex + 14, eye_y + 12], eye)
        ellipse(draw, [ex - 6, eye_y - 6, ex + 6, eye_y + 6], (24, 24, 28))
        ellipse(draw, [ex - 12, eye_y - 10, ex - 4, eye_y - 2], (255, 255, 255))
        draw.arc([ex - 32, eye_y - 28, ex + 32, eye_y - 4], 200, 340, fill=shade(hair, 20), width=4)

    # nose and mouth
    draw.line([(cx, cy + 8), (cx - 6, cy + 42), (cx + 10, cy + 42)], fill=shade(skin, -35), width=3)
    smile = 18 + (index % 4) * 4
    draw.arc([cx - smile, cy + 52, cx + smile, cy + 88], 20, 160, fill=shade(skin, -55), width=4)

    if beard:
        ellipse(draw, [cx - 78, cy + 40, cx + 78, cy + 130], shade(hair, 10))
        ellipse(draw, [cx - 58, cy + 10, cx + 58, cy + 80], skin)

    if glasses:
        for side in (-1, 1):
            ex = cx + side * gap
            draw.rounded_rectangle([ex - 36, eye_y - 22, ex + 36, eye_y + 24], radius=8, outline=(50, 54, 60), width=4)
        draw.line([(cx - gap + 36, eye_y), (cx + gap - 36, eye_y)], fill=(50, 54, 60), width=4)

    if female and index % 4 == 1:
        ellipse(draw, [cx - face_w // 2 - 8, cy + 18, cx - face_w // 2 + 10, cy + 36], (212, 168, 72))

    out = im.resize((320, 320), Image.Resampling.LANCZOS)
    return out


def main():
    for i in range(40):
        portrait(i, False).save(OUT / f"m{i:02d}.png", "PNG", optimize=True)
        portrait(i + 11, True).save(OUT / f"f{i:02d}.png", "PNG", optimize=True)
    print(f"wrote 80 portraits in {OUT}")


if __name__ == "__main__":
    main()
