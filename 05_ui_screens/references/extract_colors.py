"""
Color extraction from aidiet UI reference screenshot.
Image: 1280×877 px — 6 panels, each ~213px wide.

Panel layout:
  P0  0-213   : Home / Feed (утро)
  P1  213-426 : Progress Dashboard
  P2  426-640 : Profile & Settings
  P3  640-853 : Dietary Preferences (Tailor)
  P4  853-1066: Select Diet Type / Dietary Preferences
  P5  1066-1280: Home Evening (тёмные карточки)
"""
from PIL import Image, ImageDraw, ImageFont
import os

IMG_PATH = "/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/references/photo_2026-04-10 18.45.18.jpeg"
OUT_PATH = "/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/references/color_map.png"

img = Image.open(IMG_PATH).convert("RGB")
W, H = img.size
PW = W // 6  # panel width ≈ 213

def avg(image, x, y, r=6):
    """Среднее по квадрату 2r×2r, clamp к границам."""
    x1, y1 = max(0, x-r), max(0, y-r)
    x2, y2 = min(W, x+r), min(H, y+r)
    region = image.crop((x1, y1, x2, y2))
    pixels = list(region.getdata())
    n = len(pixels)
    return tuple(sum(p[i] for p in pixels) // n for i in range(3))

def hex_(rgb): return "#{:02X}{:02X}{:02X}".format(*rgb)

def scan_for(image, check_fn, x1, y1, x2, y2, limit=5000):
    """Вернуть список (rgb, x, y) удовлетворяющих check_fn в зоне."""
    hits = []
    step = max(1, (x2-x1)*(y2-y1) // limit)
    idx = 0
    for y in range(y1, y2):
        for x in range(x1, x2):
            idx += 1
            if idx % step != 0:
                continue
            rgb = image.getpixel((x, y))
            if check_fn(*rgb):
                hits.append((rgb, x, y))
    return hits

# ── Точки замера (x, y) ──────────────────────────────────────────────────────
# Откалиброваны по визуальному осмотру изображения 1280×877

zones = {}

# ФОНЫ
zones["Фон экрана (светло-серый)"]    = avg(img,  10,  10, 8)
zones["Фон карточки (белый)"]         = avg(img, PW//2, 240, 8)     # центр карточки Daily Nutrients
zones["Фон таб-бара"]                 = avg(img,  60, H-12, 8)

# ТЕКСТ
zones["Текст заголовок (тёмный)"]     = avg(img,  60,  18, 5)       # "Good morning, Julian"
zones["Текст вторичный (серый)"]      = avg(img,  60,  28, 4)

# ТАБ-БАР (иконки)
zones["Активная иконка таб-бара"]     = avg(img,  14, H-10, 4)
zones["Неактивная иконка таб-бара"]   = avg(img,  50, H-10, 4)

# НУТРИЕНТЫ (прогресс-бары в панели 1)
# Белки — верхняя строка, ~y=257
zones["Зелёный (белки/Protein)"]      = avg(img, PW + 140, 257, 5)
# Углеводы
zones["Жёлто-оранжевый (жиры)"]      = avg(img, PW + 140, 273, 5)
# Жиры
zones["Синий/фиолетовый (3-й)"]      = avg(img, PW + 140, 289, 5)

# КОЛЬЦО КАЛОРИЙ (панель 1, верх)
zones["Калорийное кольцо — акцент"]   = avg(img, PW + 106, 120, 5)
zones["Калорийное кольцо — серый фон"]= avg(img, PW +  80, 108, 5)

# GOLD БЕЙДЖ (панель 2, "Signature Light Plan")
zones["Gold бейдж"]                   = avg(img, 2*PW + 106, 205, 5)

# ЗЕЛЁНЫЙ ЧИП (панель 3, Tailor — зелёный акцент)
zones["Зелёный чип (уверенность)"]    = avg(img, 3*PW +  30, 165, 5)

# РАЗДЕЛИТЕЛЬ
zones["Разделитель (border)"]         = avg(img, 2*PW + 106, 255, 5)

# АКЦЕНТЫ ПРАВОЙ ПАНЕЛИ (тёмные карточки)
zones["Тёмный фон карточки"]          = avg(img, 5*PW + 106, 300, 8)
zones["Белый текст на тёмной карточке"]= avg(img, 5*PW + 20, 270, 5)

# ── Автосканирование оранжевых пикселей ──────────────────────────────────────
print("\nИзображение: {}×{} px  |  Ширина панели: {} px".format(W, H, PW))
print("="*72)

# Оранжевый/золотой CTA — ищем в полосе y=430–530 (кнопка в нижней части экрана P0)
is_orange = lambda r,g,b: r > 190 and 80 < g < 200 and b < 120 and r > g + 50

orange_hits = scan_for(img, is_orange, 0, 0, PW, H)

cta_center = cta_left = cta_right = None
if orange_hits:
    cta_left  = min(orange_hits, key=lambda t: t[1])
    cta_right = max(orange_hits, key=lambda t: t[1])
    ar = sum(p[0][0] for p in orange_hits) // len(orange_hits)
    ag = sum(p[0][1] for p in orange_hits) // len(orange_hits)
    ab = sum(p[0][2] for p in orange_hits) // len(orange_hits)
    cta_center = (ar, ag, ab)

# Зелёный — по всему изображению
is_green = lambda r,g,b: g > 140 and g > r + 25 and g > b + 25 and r < 200
green_hits = scan_for(img, is_green, 0, 0, W, H)

green_avg = green_sat = None
if green_hits:
    ar = sum(p[0][0] for p in green_hits) // len(green_hits)
    ag = sum(p[0][1] for p in green_hits) // len(green_hits)
    ab = sum(p[0][2] for p in green_hits) // len(green_hits)
    green_avg = (ar, ag, ab)
    green_sat = max(green_hits, key=lambda p: p[0][1] - p[0][0] - p[0][2])[0]

# ── Вывод ────────────────────────────────────────────────────────────────────

sections = {
    "ФОНЫ": [
        "Фон экрана (светло-серый)",
        "Фон карточки (белый)",
        "Фон таб-бара",
    ],
    "КНОПКИ CTA (оранжевый градиент)": [],
    "ТЕКСТ": [
        "Текст заголовок (тёмный)",
        "Текст вторичный (серый)",
    ],
    "НУТРИЕНТЫ / ПРОГРЕСС-БАРЫ": [
        "Зелёный (белки/Protein)",
        "Жёлто-оранжевый (жиры)",
        "Синий/фиолетовый (3-й)",
    ],
    "КОЛЬЦО КАЛОРИЙ": [
        "Калорийное кольцо — акцент",
        "Калорийное кольцо — серый фон",
    ],
    "ТАБ-БАР": [
        "Активная иконка таб-бара",
        "Неактивная иконка таб-бара",
    ],
    "БЕЙДЖИ / ЧИПЫ": [
        "Gold бейдж",
        "Зелёный чип (уверенность)",
    ],
    "РАЗДЕЛИТЕЛИ": [
        "Разделитель (border)",
    ],
    "АКЦЕНТЫ (тёмные карточки)": [
        "Тёмный фон карточки",
        "Белый текст на тёмной карточке",
    ],
}

for section, keys in sections.items():
    print(f"\n[{section}]")
    if section == "КНОПКИ CTA (оранжевый градиент)":
        if cta_center:
            print(f"  {'CTA кнопка — центр (средний)':<38} → {hex_(cta_center)}  →  RGB{cta_center}")
            print(f"  {'CTA кнопка — левый край':<38} → {hex_(cta_left[0])}  →  RGB{cta_left[0]}  at ({cta_left[1]},{cta_left[2]})")
            print(f"  {'CTA кнопка — правый край':<38} → {hex_(cta_right[0])}  →  RGB{cta_right[0]}  at ({cta_right[1]},{cta_right[2]})")
        else:
            print("  Оранжевых пикселей не найдено в панели 0")
        continue
    for key in keys:
        rgb = zones[key]
        print(f"  {key:<38} → {hex_(rgb)}  →  RGB{rgb}")

print(f"\n[АВТОСКАНИРОВАНИЕ: зелёный акцент]")
if green_avg:
    print(f"  {'Средний зелёный (все панели)':<38} → {hex_(green_avg)}  →  RGB{green_avg}")
    print(f"  {'Насыщенный зелёный':<38} → {hex_(green_sat)}  →  RGB{green_sat}")
    print(f"  Всего зелёных пикселей: {len(green_hits)}")

print("\n" + "="*72)

# ── Генерируем визуальный color map ─────────────────────────────────────────
all_colors = dict(zones)
if cta_center:
    all_colors["CTA центр (оранжевый)"] = cta_center
    all_colors["CTA левый край"]        = cta_left[0]
    all_colors["CTA правый край"]       = cta_right[0]
if green_avg:
    all_colors["Зелёный средний"]       = green_avg
    all_colors["Зелёный насыщенный"]    = green_sat

chip_w, chip_h = 220, 36
pad = 10
cols = 2
rows = (len(all_colors) + 1) // cols

canvas_w = cols * (chip_w + pad) + pad
canvas_h = rows * (chip_h + pad) + pad + 30
canvas = Image.new("RGB", (canvas_w, canvas_h), (245, 245, 245))
draw = ImageDraw.Draw(canvas)
draw.text((pad, pad), "AIDiet — Color Map", fill=(50, 50, 50))

for i, (name, rgb) in enumerate(all_colors.items()):
    col = i % cols
    row = i // cols
    x = pad + col * (chip_w + pad)
    y = 30 + pad + row * (chip_h + pad)
    # цветной прямоугольник
    draw.rectangle([x, y, x + chip_h - 4, y + chip_h - 4], fill=rgb)
    # контур
    draw.rectangle([x, y, x + chip_h - 4, y + chip_h - 4], outline=(180,180,180))
    # текст
    label = f"{hex_(rgb)}  {name}"
    draw.text((x + chip_h, y + 8), label[:38], fill=(30, 30, 30))

canvas.save(OUT_PATH)
print(f"\nColor map сохранён: {OUT_PATH}")
