"""Genera l'icona 1024x1024 in stile hardware MBStudio91 in stile hardware MBStudio91.

Uso: python3 scripts/make_icon.py icons/OUTPUT.png "TESTO DEL CHIP"
Telaio nero, logo MBSTUDIO91 stampato, zona incassata con forma d'onda, LED verde.
"""
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
ROOT = __file__.rsplit("/scripts/", 1)[0]
WORDMARK = f"{ROOT}/MBStudioUI/brand/mbstudio91-wordmark.png"
BEBAS = f"{ROOT}/MBStudioUI/fonts/BebasNeue-Regular.ttf"
GREEN = (62, 224, 92)
PRINT = (243, 243, 241)


def chassis() -> Image.Image:
    """Telaio: gradiente verticale #151617 -> #0a0a0b, angoli arrotondati."""
    img = Image.new("RGBA", (SIZE, SIZE))
    px = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip((21, 22, 23), (10, 10, 11)))
        px.line([(0, y), (SIZE, y)], fill=c + (255,))
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=190, fill=255)
    img.putalpha(mask)
    return img


def wordmark_print(width: int) -> Image.Image:
    """Logo stampato in bianco, con un'ombra sottile come da serigrafia."""
    src = Image.open(WORDMARK).convert("RGBA")
    alpha = src.split()[-1]
    h = round(src.height * width / src.width)
    alpha = alpha.resize((width, h), Image.LANCZOS)
    layer = Image.new("RGBA", (width, h), PRINT + (0,))
    layer.putalpha(alpha.point(lambda v: round(v * 0.96)))
    return layer


def display(img: Image.Image, box: tuple[int, int, int, int]) -> None:
    """Zona incassata #050506 con bordo #26282b e forma d'onda in verde."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, radius=28, fill=(5, 5, 6, 255), outline=(38, 40, 43, 255), width=4)
    rnd = random.Random(91)
    cx, cy = x0 + w / 2, y0 + h / 2
    bars = 64
    step = (w - 80) / bars
    for i in range(bars):
        t = i / (bars - 1)
        env = 0.25 + 0.75 * math.sin(math.pi * t) ** 0.8
        amp = env * (0.35 + 0.65 * rnd.random()) * (h / 2 - 36)
        x = x0 + 40 + i * step + step * 0.3
        d.rounded_rectangle([x, cy - amp, x + step * 0.4, cy + amp], radius=6, fill=GREEN + (255,))


def led(img: Image.Image, centre: tuple[int, int], radius: int) -> None:
    """LED verde con alone morbido."""
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cx, cy = centre
    ImageDraw.Draw(glow).ellipse([cx - radius * 3, cy - radius * 3, cx + radius * 3, cy + radius * 3],
                                 fill=GREEN + (120,))
    glow = glow.filter(ImageFilter.GaussianBlur(radius))
    img.alpha_composite(glow)
    ImageDraw.Draw(img).ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                                fill=GREEN + (255,))


def main(out: str) -> None:
    img = chassis()

    # marchio stampato in alto
    logo = wordmark_print(700)
    img.alpha_composite(logo, ((SIZE - logo.width) // 2, 150))

    # zona incassata con forma d'onda
    display(img, (150, 360, 874, 700))

    # etichetta del prodotto: chip bianco con testo nero, come nel kit
    chip_font = ImageFont.truetype(BEBAS, 92)
    text = sys.argv[2] if len(sys.argv) > 2 else "AI SONG FIXER"
    bbox = ImageDraw.Draw(img).textbbox((0, 0), text, font=chip_font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pad_x, pad_y = 40, 22
    cw, ch = tw + pad_x * 2, th + pad_y * 2
    cx0 = (SIZE - cw) // 2
    cy0 = 770
    ImageDraw.Draw(img).rounded_rectangle([cx0, cy0, cx0 + cw, cy0 + ch], radius=6, fill=PRINT + (255,))
    ImageDraw.Draw(img).text((cx0 + pad_x - bbox[0], cy0 + pad_y - bbox[1]), text,
                             font=chip_font, fill=(11, 11, 12, 255))

    # LED di stato
    led(img, (SIZE // 2, 900), 9)

    img.save(out)
    print("icona scritta:", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/icon-1024.png")
