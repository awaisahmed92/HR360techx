from __future__ import annotations

import math
from pathlib import Path

import imageio.v2 as imageio
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "hr-banner.jpg"
OUT = ROOT / "assets" / "hr-banner.mp4"

WIDTH, HEIGHT = 1600, 900
FPS = 30
SECONDS = 6
FRAMES = FPS * SECONDS


def crop_window(image: Image.Image, zoom: float, pan_x: float, pan_y: float) -> Image.Image:
    crop_w = max(WIDTH, int(image.width / zoom))
    crop_h = max(HEIGHT, int(image.height / zoom))
    max_x = max(0, image.width - crop_w)
    max_y = max(0, image.height - crop_h)
    x = int(max_x * pan_x)
    y = int(max_y * pan_y)
    return image.crop((x, y, x + crop_w, y + crop_h)).resize(
        (WIDTH, HEIGHT), Image.Resampling.LANCZOS
    )


def shine_layer(t: float) -> Image.Image:
    layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    center = -280 + (t * 1.15) * (WIDTH + 560)
    for i in range(140):
        alpha = int(28 * math.sin((i / 140) * math.pi))
        if alpha <= 0:
            continue
        x = int(center + i - 70)
        draw.line([(x, -40), (x - 170, HEIGHT + 40)], fill=(255, 255, 255, alpha), width=3)
    return layer.filter(ImageFilter.GaussianBlur(8))


def dots_layer(t: float) -> Image.Image:
    layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    seeds = [
        (0.12, 0.18), (0.28, 0.72), (0.46, 0.22), (0.63, 0.80),
        (0.78, 0.16), (0.88, 0.58), (0.18, 0.88), (0.54, 0.48),
    ]
    for i, (x, y) in enumerate(seeds):
        pulse = 0.45 + 0.55 * math.sin((t * math.pi * 2) + i)
        r = 2.2 + pulse * 1.8
        px = x * WIDTH + math.sin(t * math.pi * 2 + i) * 10
        py = y * HEIGHT + math.cos(t * math.pi * 2 + i * 0.7) * 8
        alpha = int(40 + pulse * 70)
        draw.ellipse((px - r, py - r, px + r, py + r), fill=(125, 211, 252, alpha))
    return layer


def main() -> None:
    source = Image.open(SRC).convert("RGB")
    base = source.resize((int(WIDTH * 1.16), int(HEIGHT * 1.16)), Image.Resampling.LANCZOS)
    writer = imageio.get_writer(
        OUT,
        fps=FPS,
        codec="libx264",
        quality=7,
        pixelformat="yuv420p",
        macro_block_size=None,
    )
    try:
        for i in range(FRAMES):
            t = i / (FRAMES - 1)
            zoom = 1.02 + (0.08 * t)
            pan_x = 0.28 + (0.44 * t)
            pan_y = 0.38 + (0.12 * math.sin(t * math.pi))
            frame = crop_window(base, zoom, pan_x, pan_y)
            glow = 1.0 + (0.04 * math.sin(t * math.pi * 2))
            frame = ImageEnhance.Contrast(frame).enhance(1.04)
            frame = ImageEnhance.Brightness(frame).enhance(glow)
            composed = Image.alpha_composite(frame.convert("RGBA"), shine_layer(t))
            composed = Image.alpha_composite(composed, dots_layer(t))
            writer.append_data(np.asarray(composed.convert("RGB")))
    finally:
        writer.close()
    print(f"Wrote {OUT} ({SECONDS}s, {FPS} fps)")


if __name__ == "__main__":
    main()
