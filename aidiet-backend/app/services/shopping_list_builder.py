import json
import re
from typing import Dict, List, Any

# Базовые цены на продукты (Ориентировочные, за 1 кг/шт/л) в рублях
# Это можно будет вынести в базу данных
PRICE_MATRIX = {
    "экономный": {
        "курица": 350, "яйцо": 10, "яйца": 10, "капуста": 40, "морковь": 50, "картофель": 40,
        "гречка": 80, "рис": 100, "овсянка": 50, "макароны": 70, "молоко": 80, "кефир": 90,
        "творог": 350, "яблоко": 120, "банан": 140, "хлеб": 50, "масло подсолнечное": 120,
        "минтай": 250, "свинина": 400, "укроп": 500, "петрушка": 500
    },
    "средний": {
        "индейка": 550, "говядина": 800, "форель": 1200, "сыр": 800, "оливковое масло": 1500,
        "помидор": 300, "огурец": 250, "перец": 400, "шпинат": 800, "ягоды": 1000
    },
    "без разницы": {
        "лосось": 2500, "семга": 2500, "авокадо": 800, "креветки": 1500, "орехи": 1500,
        "киноа": 600, "чиа": 800
    }
}

def normalize_name(name: str) -> str:
    """Нормализует название ингредиента для группировки"""
    name = name.lower().strip()
    name = re.sub(r'[^\w\s]', '', name) # Удаляем пунктуацию
    
    # Простые синонимы
    if "яйцо" in name or "яйца" in name: return "яйца куриные"
    if "филе кури" in name or "куриная грудка" in name: return "куриное филе"
    if "масло оливковое" in name: return "оливковое масло"
    if "укроп" in name: return "зелень (укроп)"
    if "петрушк" in name: return "зелень (петрушка)"
    if "шпинат" in name: return "шпинат свежий"
    if "соль" in name or "перец" in name and "сладкий" not in name: return "специи"
    
    return name

def estimate_cost(normalized_name: str, amount: float, unit: str, budget: str) -> float:
    """Примерный подсчет стоимости"""
    budget_key = budget.lower() if budget else "средний"
    
    # Собираем все доступные цены для бюджета и ниже
    prices = {}
    if budget_key in ["экономный", "эконом"]:
        prices.update(PRICE_MATRIX["экономный"])
    elif budget_key == "средний":
        prices.update(PRICE_MATRIX["экономный"])
        prices.update(PRICE_MATRIX["средний"])
    else:
        prices.update(PRICE_MATRIX["экономный"])
        prices.update(PRICE_MATRIX["средний"])
        prices.update(PRICE_MATRIX["без разницы"])

    # Ищем совпадения (очень базово)
    found_price = 0
    for k, v in prices.items():
        if k in normalized_name:
            found_price = v
            break
            
    if not found_price:
        found_price = 200 # Дефолтная цена 200р за кг
        
    # Расчет по единицам
    if unit in ["г", "гр", "ml", "мл"]:
        return (amount / 1000) * found_price
    elif unit in ["шт", "штука", "штук"]:
        return amount * found_price  # тут found_price за штуку, если это яйца. Иначе бред, но для MVP пойдет
    return 0

def build_shopping_list(plan_data: Dict[str, Any], budget_level: str) -> Dict[str, Any]:
    """
    Парсит JSON-план, суммирует ингредиенты, округляет до удобных магазинных пачек 
    и считает примерную стоимость корзины.
    """
    ingredients_map = {}
    total_cost = 0.0
    
    # 1. Сбор и суммирование
    for day_key, day_data in plan_data.items():
        if not key_is_day(day_key): continue
        
        meals = day_data.get('meals', []) if isinstance(day_data, dict) else day_data
        if not isinstance(meals, list): continue
            
        for meal in meals:
            ingredients = meal.get('ingredients', [])
            for ing in ingredients:
                name = ing.get('name', '')
                amount = float(ing.get('amount', 0))
                unit = ing.get('unit', 'г').lower()
                
                # Игнорируем воду и специи в списке покупок
                norm_name = normalize_name(name)
                if norm_name in ["вода", "специи"]:
                    continue
                    
                key = f"{norm_name}_{unit}"
                if key not in ingredients_map:
                    ingredients_map[key] = {
                        "name": name.capitalize(), # Оригинальное название для отображения
                        "norm_name": norm_name,
                        "amount": 0,
                        "unit": unit
                    }
                ingredients_map[key]["amount"] += amount

    # 2. Округление до магазинных стандартов (Normalizer) и расчет цены
    shopping_list = []
    for item in ingredients_map.values():
        amount = item["amount"]
        unit = item["unit"]
        
        # Округления
        if unit in ["г", "гр", "мл", "ml"]:
            if amount < 50:
                amount = 50
            elif amount < 150:
                amount = round(amount / 50) * 50
            else:
                amount = round(amount / 100) * 100
        elif unit in ["шт", "штук", "штука"]:
            amount = round(amount)
            if amount == 0: amount = 1
            
        cost = estimate_cost(item["norm_name"], amount, unit, budget_level)
        total_cost += cost
        
        shopping_list.append({
            "name": item["name"],
            "amount": amount,
            "unit": unit
        })
        
    return {
        "items": shopping_list,
        "total_estimated_cost_rub": round(total_cost, -1) # Округляем до десятков
    }

def key_is_day(key: str) -> bool:
    return key.startswith("day_")
