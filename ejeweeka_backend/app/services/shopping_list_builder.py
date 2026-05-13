import json
import re
from typing import Dict, List, Any

# Маппинг стран → валюта + символ
CURRENCY_MAP = {
    'россия': ('RUB', '₽'), 'ru': ('RUB', '₽'), 'беларусь': ('BYN', 'BYN'),
    'украина': ('UAH', '₴'), 'казахстан': ('KZT', '₸'),
    'оаэ': ('AED', 'AED'), 'uae': ('AED', 'AED'),
    'таиланд': ('THB', '฿'), 'th': ('THB', '฿'),
    'турция': ('TRY', '₺'), 'tr': ('TRY', '₺'),
    'израиль': ('ILS', '₪'), 'il': ('ILS', '₪'),
    'сша': ('USD', '$'), 'us': ('USD', '$'),
    'германия': ('EUR', '€'), 'de': ('EUR', '€'),
    'испания': ('EUR', '€'), 'италия': ('EUR', '€'),
    'грузия': ('GEL', '₾'), 'сербия': ('RSD', 'RSD'),
    'аргентина': ('ARS', 'ARS'), 'индонезия': ('IDR', 'IDR'),
}

# Региональные цены (за 1 кг/шт/л) — базовые продукты
PRICE_MATRIX_BY_CURRENCY = {
    'RUB': {
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
    },
    'AED': {
        "экономный": {
            "курица": 15, "яйцо": 1, "яйца": 1, "рис": 5, "картофель": 3, "морковь": 4,
            "хлеб": 3, "банан": 6, "яблоко": 8, "молоко": 5, "масло подсолнечное": 8,
            "нут": 10, "чечевица": 8, "тунец": 20
        },
        "средний": {
            "говядина": 45, "баранина": 55, "сыр": 40, "оливковое масло": 30,
            "помидор": 8, "перец": 10, "шпинат": 15
        },
        "без разницы": {
            "лосось": 80, "креветки": 60, "авокадо": 25, "киноа": 30
        }
    },
    'THB': {
        "экономный": {
            "курица": 100, "яйцо": 4, "яйца": 4, "рис": 30, "тофу": 40, "капуста": 20,
            "морковь": 30, "банан": 20, "хлеб": 30, "масло подсолнечное": 50,
            "рыба": 80, "лапша рисовая": 25
        },
        "средний": {
            "свинина": 150, "креветки": 250, "кокосовое молоко": 60,
            "помидор": 60, "перец": 80, "шпинат": 100
        },
        "без разницы": {
            "лосось": 600, "авокадо": 150, "киноа": 200, "орехи": 400
        }
    },
}

# Дефолт для неизвестных валют (используем RUB как fallback)
DEFAULT_CURRENCY = 'RUB'

def get_currency_info(country: str):
    """Определяет валюту и символ по стране."""
    country_lower = (country or '').lower().strip()
    for key, val in CURRENCY_MAP.items():
        if key in country_lower:
            return val
    return ('RUB', '₽')

def get_price_matrix(currency: str):
    """Возвращает ценовую матрицу для валюты."""
    return PRICE_MATRIX_BY_CURRENCY.get(currency, PRICE_MATRIX_BY_CURRENCY.get(DEFAULT_CURRENCY, {}))

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

def estimate_cost(normalized_name: str, amount: float, unit: str, budget: str, currency: str = 'RUB') -> float:
    """Примерный подсчет стоимости с учётом валюты региона"""
    budget_key = budget.lower() if budget else "средний"
    price_matrix = get_price_matrix(currency)
    
    # Собираем все доступные цены для бюджета и ниже
    prices = {}
    if budget_key in ["экономный", "эконом"]:
        prices.update(price_matrix.get("экономный", {}))
    elif budget_key == "средний":
        prices.update(price_matrix.get("экономный", {}))
        prices.update(price_matrix.get("средний", {}))
    else:
        prices.update(price_matrix.get("экономный", {}))
        prices.update(price_matrix.get("средний", {}))
        prices.update(price_matrix.get("без разницы", {}))

    # Ищем совпадения (очень базово)
    found_price = 0
    for k, v in prices.items():
        if k in normalized_name:
            found_price = v
            break
            
    if not found_price:
        # Дефолтная цена зависит от валюты
        default_prices = {'RUB': 200, 'AED': 10, 'THB': 50, 'TRY': 30, 'ILS': 15, 'USD': 5, 'EUR': 4}
        found_price = default_prices.get(currency, 200)
        
    # Расчет по единицам
    if unit in ["г", "гр", "ml", "мл"]:
        return (amount / 1000) * found_price
    elif unit in ["шт", "штука", "штук"]:
        return amount * found_price
    return 0

def build_shopping_list(plan_data: Dict[str, Any], budget_level: str, country: str = "Россия") -> Dict[str, Any]:
    """
    Парсит JSON-план, суммирует ингредиенты, округляет до удобных магазинных пачек 
    и считает примерную стоимость корзины в валюте региона пользователя.
    """
    currency_code, currency_symbol = get_currency_info(country)
    
    ingredients_map = {}
    total_cost = 0.0
    
    # 1. Сбор и суммирование
    for day_key, day_data in plan_data.items():
        if not key_is_day(day_key): continue
        
        meals = day_data.get('meals', []) if isinstance(day_data, dict) else day_data
        if not isinstance(meals, list): continue
            
        for meal in meals:
            # Считаем корзину ТОЛЬКО по первому варианту
            if meal.get('variant_name', '') not in ['Вариант 1', 'Основной', '']:
                continue
                
            ingredients = meal.get('ingredients', [])
            for ing in ingredients:
                name = ing.get('name', '')
                try:
                    amount = float(ing.get('amount', ing.get('grams', 0)))
                except (ValueError, TypeError):
                    # Если "по вкусу" или другая строка, не суммируем в общий счетчик корзины
                    continue
                unit = ing.get('unit', 'г').lower()
                
                # Игнорируем воду и специи в списке покупок
                norm_name = normalize_name(name)
                if norm_name in ["вода", "специи"]:
                    continue
                    
                key = f"{norm_name}_{unit}"
                if key not in ingredients_map:
                    ingredients_map[key] = {
                        "name": name.capitalize(),
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
            
        cost = estimate_cost(item["norm_name"], amount, unit, budget_level, currency_code)
        total_cost += cost
        
        shopping_list.append({
            "name": item["name"],
            "amount": amount,
            "unit": unit
        })
        
    return {
        "items": shopping_list,
        "total_estimated_cost": round(total_cost, -1),
        "total_estimated_cost_rub": round(total_cost, -1),  # Backward compat
        "currency_code": currency_code,
        "currency_symbol": currency_symbol
    }

def key_is_day(key: str) -> bool:
    return key.startswith("day_")

