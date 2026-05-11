"""
Скрипт для проставления preview-картинок всем рецептам в meals_library.
Использует Unsplash Source API (бесплатно, без API ключа).
При показе рецепта в приложении картинка будет заменена на Imagen 4.

Run: python3 -m app.scripts.seed_meal_images
"""

import os
import sys
import urllib.parse
from pathlib import Path
from dotenv import load_dotenv

_backend_root = Path(__file__).resolve().parent.parent.parent
load_dotenv(_backend_root / ".env")
sys.path.insert(0, str(_backend_root))

from app.db import SessionLocal
from app.models.recipe_cache import MealCache


# Маппинг русских слов → английские теги для Unsplash
FOOD_TAGS = {
    "каша": "porridge",
    "овсян": "oatmeal",
    "гречк": "buckwheat",
    "рис": "rice,bowl",
    "суп": "soup,bowl",
    "салат": "salad",
    "курица": "chicken,grilled",
    "рыба": "fish,grilled",
    "лосос": "salmon",
    "творог": "cottage-cheese",
    "йогурт": "yogurt,bowl",
    "омлет": "omelette",
    "яичниц": "scrambled-eggs",
    "смузи": "smoothie",
    "тост": "toast,avocado",
    "блин": "pancakes",
    "запеканк": "casserole",
    "котлет": "meatballs",
    "тефтел": "meatballs",
    "паст": "pasta",
    "овощ": "vegetables,grilled",
    "тыкв": "pumpkin,soup",
    "фрукт": "fruit,bowl",
    "ягод": "berries,bowl",
    "орех": "nuts,granola",
    "хлеб": "bread,whole-grain",
    "индейк": "turkey",
    "говядин": "beef,steak",
    "печен": "liver",
    "кабачк": "zucchini",
    "брокколи": "broccoli",
    "шпинат": "spinach",
    "авокадо": "avocado",
    "банан": "banana",
}


def get_image_url(meal_name: str) -> str:
    """Generate a relevant Unsplash image URL based on meal name."""
    name_lower = meal_name.lower()
    
    # Find matching food tags
    tags = []
    for ru_word, en_tag in FOOD_TAGS.items():
        if ru_word in name_lower:
            tags.append(en_tag)
    
    if not tags:
        tags = ["healthy-food,plate"]
    
    # Use first 2 tags max
    query = ",".join(tags[:2])
    encoded = urllib.parse.quote(query)
    return f"https://images.unsplash.com/photo-healthy-food?w=800&h=600&q=80&fit=crop&auto=format&s={encoded}"


def get_pexels_url(meal_name: str) -> str:
    """Fallback: use a deterministic food photo URL pattern."""
    name_lower = meal_name.lower()
    
    tags = []
    for ru_word, en_tag in FOOD_TAGS.items():
        if ru_word in name_lower:
            tags.append(en_tag)
    
    if not tags:
        tags = ["healthy-food"]
    
    query = "+".join(tags[:2])
    # Using Lorem Picsum as reliable free image source
    # Each recipe gets a unique but deterministic photo based on hash
    import hashlib
    seed = int(hashlib.md5(meal_name.encode()).hexdigest()[:8], 16) % 1000
    return f"https://picsum.photos/seed/{seed}/800/600"


def main():
    db = SessionLocal()
    
    # Find all recipes without image_url
    no_image = db.query(MealCache).filter(
        (MealCache.image_url == None) | (MealCache.image_url == "")
    ).all()
    
    total = db.query(MealCache).count()
    print(f"📸 Meals without images: {len(no_image)} / {total} total")
    
    if not no_image:
        print("✅ All meals already have images!")
        db.close()
        return
    
    updated = 0
    for meal in no_image:
        meal.image_url = get_pexels_url(meal.name)
        updated += 1
    
    db.commit()
    db.close()
    print(f"✅ Updated {updated} meals with preview images")


if __name__ == "__main__":
    main()
