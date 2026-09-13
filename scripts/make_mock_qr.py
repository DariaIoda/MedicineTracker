# -*- coding: utf-8 -*-
"""Генерирует набор «фотографий» наклеек с QR-кодами для mock-сканера в симуляторе."""
import os, random
import qrcode
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "InventoryQR", "Resources", "MockQR")
FONT = "C:/Windows/Fonts/arialbd.ttf"
FONT2 = "C:/Windows/Fonts/arial.ttf"

LABELS = [
    ("label_box_0001", "INVQR:1:BOX-0001", "Тумба под телевизором", "BOX-0001", (196, 160, 110)),
    ("label_box_0004", "INVQR:1:BOX-0004", "Коробка «Инструменты»", "BOX-0004", (176, 138, 92)),
    ("label_box_0005", "INVQR:1:BOX-0005", "Коробка «Новый год»", "BOX-0005", (205, 170, 120)),
    ("label_box_9999", "INVQR:1:BOX-9999", "Чужая коробка", "BOX-9999", (160, 150, 140)),
    ("label_foreign", "https://www.gstu.by", "Посторонний QR-код", "gstu.by", (120, 130, 145)),
]


def make(name, payload, title, code, bg, seed):
    rnd = random.Random(seed)
    W, H = 900, 1100
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    # фактура картона
    for _ in range(2500):
        x, y = rnd.randrange(W), rnd.randrange(H)
        c = tuple(max(0, min(255, v + rnd.randint(-18, 18))) for v in bg)
        d.point((x, y), fill=c)
    # наклейка
    label = Image.new("RGB", (620, 800), (250, 250, 247))
    ld = ImageDraw.Draw(label)
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=12, border=2)
    qr.add_data(payload)
    qr.make(fit=True)
    q = qr.make_image(fill_color="black", back_color="white").convert("RGB").resize((500, 500), Image.NEAREST)
    label.paste(q, (60, 60))
    f1 = ImageFont.truetype(FONT, 40)
    f2 = ImageFont.truetype(FONT2, 34)
    tw = ld.textlength(title, font=f1)
    ld.text(((620 - tw) / 2, 600), title, fill=(20, 20, 20), font=f1)
    cw = ld.textlength(code, font=f2)
    ld.text(((620 - cw) / 2, 670), code, fill=(90, 90, 90), font=f2)
    ld.rectangle([2, 2, 617, 797], outline=(200, 200, 200), width=3)
    label = label.rotate(rnd.uniform(-6, 6), expand=True, fillcolor=bg, resample=Image.BICUBIC)
    img.paste(label, ((W - label.width) // 2, (H - label.height) // 2))
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    img.thumbnail((600, 733))
    img.save(os.path.join(OUT, name + ".png"), optimize=True)


for i, row in enumerate(LABELS):
    make(*row, seed=i)
print("готово:", len(LABELS))
