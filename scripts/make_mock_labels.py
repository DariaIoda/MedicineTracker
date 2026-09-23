# -*- coding: utf-8 -*-
"""Генерирует набор «фотографий» упаковок лекарств для mock-сканера в симуляторе."""
import os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Убедитесь, что папка MockImages существует.
OUT = os.path.join(os.path.dirname(__file__), "..", "MedicineTracker", "Resources", "MockImages")
os.makedirs(OUT, exist_ok=True)

FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
FONT_REGULAR = "C:/Windows/Fonts/arial.ttf"

# (Имя файла, Название лекарства, Дозировка, Цвет фона)
LABELS = [
    ("aspirin_label", "Аспирин", "500 мг", (200, 160, 160)),
    ("ibuprofen_label", "Ибупрофен", "200 мг", (160, 180, 200)),
    ("paracetamol_label", "Парацетамол", "500 мг", (170, 200, 170)),
    ("nurofen_label", "Нурофен", "Сироп", (210, 190, 140)),
]

def make(name, title, dosage, bg, seed):
    rnd = random.Random(seed)
    W, H = 900, 1100
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    
    # Фактура фона (стол)
    for _ in range(2500):
        x, y = rnd.randrange(W), rnd.randrange(H)
        c = tuple(max(0, min(255, v + rnd.randint(-20, 20))) for v in bg)
        d.point((x, y), fill=c)
        
    # Упаковка
    label = Image.new("RGB", (620, 400), (250, 250, 247))
    ld = ImageDraw.Draw(label)
    
    try:
        f1 = ImageFont.truetype(FONT_BOLD, 70)
        f2 = ImageFont.truetype(FONT_REGULAR, 45)
    except IOError:
        f1 = ImageFont.load_default()
        f2 = ImageFont.load_default()

    # Отрисовка названия
    tw = ld.textlength(title, font=f1)
    ld.text(((620 - tw) / 2, 120), title, fill=(20, 20, 20), font=f1)
    
    # Отрисовка дозировки
    cw = ld.textlength(dosage, font=f2)
    ld.text(((620 - cw) / 2, 220), dosage, fill=(100, 100, 100), font=f2)
    
    # Рамка упаковки
    ld.rectangle([2, 2, 617, 397], outline=(200, 200, 200), width=4)
    
    label = label.rotate(rnd.uniform(-6, 6), expand=True, fillcolor=bg, resample=Image.BICUBIC)
    img.paste(label, ((W - label.width) // 2, (H - label.height) // 2))
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    img.thumbnail((600, 733))
    
    img.save(os.path.join(OUT, name + ".png"), optimize=True)

for i, row in enumerate(LABELS):
    make(*row, seed=i)

print("Готово: сгенерировано", len(LABELS), "упаковок")