from __future__ import annotations

from pathlib import Path

import imageio.v2 as imageio
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "hr-banner-user-original.mp4"
OUT = ROOT / "assets" / "hr-banner.mp4"
POSTER = ROOT / "assets" / "hr-banner.jpg"

NAVY = (8, 16, 32)
COPY = (
    "The ultimate global cloud HR platform. Manage,\n"
    "pay, and support your people from any office,\n"
    "or anywhere in the world."
)

# Cover boxes as (x1, y1, x2, y2) at keyframe progress 0..1
PARAGRAPH = [
    (0.00, (40, 248, 555, 432)),
    (0.17, (28, 246, 560, 448)),
    (0.34, (0, 238, 430, 500)),
    (0.55, (0, 230, 240, 520)),
    (1.00, (0, 220, 140, 520)),
]
FLIGHT_BADGE = [
    (0.00, (755, 160, 1030, 178)),
    (0.17, (775, 160, 1060, 180)),
    (0.34, (835, 116, 1130, 136)),
    (0.67, (318, 108, 540, 142)),
    (1.00, (260, 100, 510, 150)),
]


def lerp_box(keys: list[tuple[float, tuple[int, int, int, int]]], t: float) -> tuple[int, int, int, int]:
    if t <= keys[0][0]:
        return keys[0][1]
    if t >= keys[-1][0]:
        return keys[-1][1]
    for i in range(1, len(keys)):
        t0, b0 = keys[i - 1]
        t1, b1 = keys[i]
        if t <= t1:
            u = (t - t0) / (t1 - t0)
            return tuple(int(a + (b - a) * u) for a, b in zip(b0, b1))
    return keys[-1][1]


def sample_fill(img: Image.Image, box: tuple[int, int, int, int]) -> tuple[int, int, int]:
    x1, y1, x2, y2 = box
    x1, y1 = max(0, x1), max(0, y1)
    x2, y2 = min(img.width, x2), min(img.height, y2)
    if x2 <= x1 or y2 <= y1:
        return NAVY
    crop = np.asarray(img.crop((x1, y1, x2, y2)))
    lum = crop.mean(axis=2)
    mid = crop[(lum > np.percentile(lum, 20)) & (lum < np.percentile(lum, 80))]
    if mid.size == 0:
        return NAVY
    return tuple(int(v) for v in np.median(mid, axis=0))


def hide_flight_caption(img: Image.Image, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = [int(v) for v in box]
    x1, y1 = max(0, x1), max(0, y1)
    x2, y2 = min(img.width, x2), min(img.height, y2)
    h = y2 - y1
    if h <= 2 or x2 <= x1:
        return
    src_y1 = min(img.height - h, y2 + 6)
    src = img.crop((x1, src_y1, x2, src_y1 + h))
    img.paste(src, (x1, y1))


def erase_label(img: Image.Image, box: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = [int(v) for v in box]
    x1, y1 = max(0, x1), max(0, y1)
    x2, y2 = min(img.width, x2), min(img.height, y2)
    if x2 <= x1 or y2 <= y1:
        return
    crop = np.asarray(img.crop((x1, y1, x2, y2)))
    lum = crop.mean(axis=2)
    mid = crop[(lum > 90) & (lum < 210)]
    color = tuple(int(v) for v in np.median(mid if mid.size else crop.reshape(-1, 3), axis=0))
    ImageDraw.Draw(img).rectangle((x1, y1, x2, y2), fill=color)


def cover(
    img: Image.Image,
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int] | None = None,
    radius: int = 10,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill or sample_fill(img, box))


def replace_badge(img: Image.Image, t: float) -> None:
    x1, y1, x2, y2 = lerp_box(FLIGHT_BADGE, t)
    erase_label(img, (x1, y1, x2, y2))
    font_size = 13 if t < 0.4 else 18
    font = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", font_size)
    draw = ImageDraw.Draw(img)
    label = "GLOBAL CLOUD"
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = x1 + max(8, (x2 - x1 - tw) // 2)
    y = y1 + max(2, (y2 - y1 - th) // 2)
    draw.text((x, y), label, font=font, fill=(255, 255, 255))


def draw_copy(img: Image.Image, t: float) -> None:
    if t > 0.46:
        return
    font = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 16)
    draw = ImageDraw.Draw(img)
    x = 48 - int(20 * t)
    y = 258 - int(8 * t)
    draw.multiline_text((x, y), COPY, font=font, fill=(203, 213, 225), spacing=5)


def process_frame(frame: np.ndarray, t: float) -> np.ndarray:
    img = Image.fromarray(frame).convert("RGB")
    draw = ImageDraw.Draw(img)
    cover(img, draw, lerp_box(PARAGRAPH, t), fill=NAVY, radius=8)
    draw_copy(img, t)
    return np.asarray(img)


def main() -> None:
    reader = imageio.get_reader(SRC)
    meta = reader.get_meta_data()
    fps = float(meta.get("fps") or 24)
    writer = imageio.get_writer(
        OUT,
        fps=fps,
        codec="libx264",
        quality=7,
        pixelformat="yuv420p",
        macro_block_size=None,
    )
    count = 0
    try:
        for i, frame in enumerate(reader):
            t = min(i / 239, 1.0)
            out = process_frame(frame, t)
            if i == 0:
                Image.fromarray(out).save(POSTER, quality=92)
            writer.append_data(out)
            count += 1
    finally:
        writer.close()
        reader.close()
    print(f"Wrote {OUT} from {count} frames at {fps} fps")


if __name__ == "__main__":
    main()
