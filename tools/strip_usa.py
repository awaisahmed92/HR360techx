from pathlib import Path

import imageio.v2 as imageio
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SRC = Path(r"d:\xampp\htdocs\360tech\HR360techx\assets\hr-banner-user-original.mp4")
OUT = Path(r"d:\xampp\htdocs\360tech\HR360techx\assets\hr-banner.mp4")
POSTER = Path(r"d:\xampp\htdocs\360tech\HR360techx\assets\hr-banner.jpg")
NAVY = (8, 16, 32)
FONT = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 16)
FONT_SM = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 14)
COPY = "The ultimate global cloud HR platform. Manage,\npay, and support your people from any office,\nor anywhere in the world."


def main() -> None:
    reader = imageio.get_reader(SRC)
    fps = float(reader.get_meta_data().get("fps") or 24)
    writer = imageio.get_writer(OUT, fps=fps, codec="libx264", quality=7, pixelformat="yuv420p", macro_block_size=None)
    try:
        for i, frame in enumerate(reader):
            t = min(i / 239, 1)
            img = Image.fromarray(frame)
            d = ImageDraw.Draw(img)
            d.rectangle((0, 240, 560 - int(200 * t), 460 + int(40 * t)), fill=NAVY)
            if t < 0.5:
                d.multiline_text((48, 258), COPY, font=FONT, fill=(203, 213, 225), spacing=5)
            # hide IN-FLIGHT / any USA caption on the plane tile
            if t < 0.25:
                box = (730, 150, 1060, 190)
            elif t < 0.45:
                box = (760, 95, 1160, 150)
            elif t < 0.7:
                box = (820, 40, 1240, 140)
            else:
                box = (250, 70, 720, 200)
            d.rectangle(box, fill=(228, 222, 216))
            d.text((box[0] + 16, box[1] + 8), "CLOUD TEAM", font=FONT_SM, fill=(40, 48, 58))
            arr = np.asarray(img.convert("RGB"))
            if i == 0:
                Image.fromarray(arr).save(POSTER, quality=92)
            writer.append_data(arr)
    finally:
        writer.close()
        reader.close()
    print("done")


if __name__ == "__main__":
    main()
