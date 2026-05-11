"""
Seed script: populates vitamin_interactions, drug_food_interactions,
and ingredients_reference tables with verified deterministic data.

Run: python -m app.scripts.seed_safety_tables
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from app.db import engine, Base, SessionLocal
from app.models.safety_tables import VitaminInteraction, DrugFoodInteraction, IngredientReference


def seed_vitamin_interactions(db):
    """Verified vitamin/supplement interaction rules."""
    data = [
        # ── CONFLICTS ──
        {"substance_a": "Кальций", "substance_b": "Железо", "interaction_type": "conflict", "severity": "critical",
         "rule_text": "Кальций блокирует усвоение железа на 50-60%. НИКОГДА в один приём пищи. Разнести на 4+ часа.",
         "separation_hours": 4},
        {"substance_a": "Цинк", "substance_b": "Медь", "interaction_type": "conflict", "severity": "moderate",
         "rule_text": "Цинк и медь — антагонисты. Высокие дозы цинка истощают запасы меди. Разнести на 2+ часа.",
         "separation_hours": 2},
        {"substance_a": "Витамин C", "substance_b": "Витамин B12", "interaction_type": "conflict", "severity": "moderate",
         "rule_text": "Витамин C разрушает B12 при совместном приёме. Разнести по разным приёмам пищи.",
         "separation_hours": 2},
        {"substance_a": "Кальций", "substance_b": "Магний", "interaction_type": "conflict", "severity": "moderate",
         "rule_text": "Кальций и магний конкурируют за усвоение. Кальций утром, магний вечером.",
         "separation_hours": 6},
        {"substance_a": "Кальций", "substance_b": "Цинк", "interaction_type": "conflict", "severity": "moderate",
         "rule_text": "Кальций снижает усвоение цинка. Разнести по приёмам пищи.",
         "separation_hours": 2},
        {"substance_a": "Железо", "substance_b": "Кофеин", "interaction_type": "conflict", "severity": "critical",
         "rule_text": "Кофе и чай снижают усвоение железа на 40-90%. Железо принимать за 1 час до или через 2 часа после кофе.",
         "separation_hours": 2},
        {"substance_a": "Железо", "substance_b": "Танины (чай)", "interaction_type": "conflict", "severity": "critical",
         "rule_text": "Танины в чае связывают железо. Не запивать железо чаем. Разнести на 2+ часа.",
         "separation_hours": 2},
        # ── SYNERGIES ──
        {"substance_a": "Витамин D3", "substance_b": "Жирная пища", "interaction_type": "synergy", "severity": "critical",
         "rule_text": "Витамин D — жирорастворимый. Принимать ТОЛЬКО с жирной пищей (масло, авокадо, орехи).",
         "separation_hours": 0, "requires_food": True},
        {"substance_a": "Витамин C", "substance_b": "Железо", "interaction_type": "synergy", "severity": "moderate",
         "rule_text": "Витамин C увеличивает усвоение растительного железа в 2-3 раза. Принимать вместе.",
         "separation_hours": 0},
        {"substance_a": "Витамин D3", "substance_b": "Кальций", "interaction_type": "synergy", "severity": "moderate",
         "rule_text": "Витамин D улучшает усвоение кальция. Можно совмещать в одном приёме.",
         "separation_hours": 0},
        {"substance_a": "Витамин K2", "substance_b": "Витамин D3", "interaction_type": "synergy", "severity": "moderate",
         "rule_text": "K2 направляет кальций в кости, а не в сосуды. Оптимально принимать вместе с D3.",
         "separation_hours": 0},
        # ── TIMING ──
        {"substance_a": "Магний", "substance_b": "Сон", "interaction_type": "timing", "severity": "info",
         "rule_text": "Магний расслабляет мышцы и улучшает засыпание. Оптимально принимать за 30-60 мин до сна.",
         "separation_hours": 0},
        {"substance_a": "Железо", "substance_b": "Натощак", "interaction_type": "timing", "severity": "info",
         "rule_text": "Железо лучше усваивается натощак. Но может раздражать ЖКТ — при дискомфорте принимать с лёгкой пищей.",
         "separation_hours": 0},
        {"substance_a": "Пробиотики", "substance_b": "Натощак", "interaction_type": "timing", "severity": "info",
         "rule_text": "Пробиотики лучше работают на пустой желудок (утром, за 30 мин до завтрака).",
         "separation_hours": 0},
    ]
    for item in data:
        db.add(VitaminInteraction(**item))
    db.commit()
    print(f"✅ Seeded {len(data)} vitamin interactions")


def seed_drug_food_interactions(db):
    """Verified drug-food interaction rules (from assembler.py DRUG_FOOD_RULES + expanded)."""
    data = [
        {"drug_keyword": "варфарин", "drug_name": "Варфарин", "severity": "critical", "category": "anticoagulant",
         "foods_avoid": "шпинат, капуста, брокколи, петрушка, руккола, зелёный чай (большие дозы)",
         "foods_include": "",
         "rule_text": "ЗАПРЕЩЕНЫ резкие скачки витамина K. Стабильное ежедневное потребление зелёных овощей, но без дней-пиков."},
        {"drug_keyword": "метформин", "drug_name": "Метформин", "severity": "critical", "category": "antidiabetic",
         "foods_avoid": "алкоголь (полностью)",
         "foods_include": "печень, рыба, яйца (источники B12)",
         "rule_text": "Метформин истощает запасы B12. Обеспечь продукты богатые B12. ИСКЛЮЧИ алкоголь полностью (риск лактоацидоза)."},
        {"drug_keyword": "л-тироксин", "drug_name": "Л-Тироксин / Левотироксин", "severity": "critical", "category": "thyroid",
         "foods_avoid": "молочные продукты и кальций на завтрак, кофе в течение 30мин",
         "foods_include": "",
         "rule_text": "Принимать за 30-60мин до еды НАТОЩАК. Завтрак БЕЗ молочных продуктов и кальция. Кофе — минимум через 30мин после таблетки."},
        {"drug_keyword": "тироксин", "drug_name": "Тироксин", "severity": "critical", "category": "thyroid",
         "foods_avoid": "молочные продукты и кальций на завтрак",
         "foods_include": "",
         "rule_text": "Принимать за 30-60мин до еды НАТОЩАК. Завтрак БЕЗ молочных и кальция."},
        {"drug_keyword": "статин", "drug_name": "Статины (общие)", "severity": "critical", "category": "statin",
         "foods_avoid": "грейпфрут, помело, лайм",
         "foods_include": "",
         "rule_text": "ИСКЛЮЧИ грейпфрут и помело — они блокируют метаболизм статинов через CYP3A4, что ведёт к токсичности."},
        {"drug_keyword": "аторвастатин", "drug_name": "Аторвастатин", "severity": "critical", "category": "statin",
         "foods_avoid": "грейпфрут, помело",
         "foods_include": "",
         "rule_text": "ИСКЛЮЧИ грейпфрут и помело."},
        {"drug_keyword": "симвастатин", "drug_name": "Симвастатин", "severity": "critical", "category": "statin",
         "foods_avoid": "грейпфрут, помело",
         "foods_include": "",
         "rule_text": "ИСКЛЮЧИ грейпфрут и помело."},
        {"drug_keyword": "эналаприл", "drug_name": "Эналаприл", "severity": "moderate", "category": "ace_inhibitor",
         "foods_avoid": "бананы (большие дозы), курага, картофель (много), шпинат",
         "foods_include": "",
         "rule_text": "Ограничь продукты с высоким калием: бананы, картофель, курага, шпинат. Риск гиперкалиемии."},
        {"drug_keyword": "лизиноприл", "drug_name": "Лизиноприл", "severity": "moderate", "category": "ace_inhibitor",
         "foods_avoid": "бананы (большие дозы), курага, картофель (много)",
         "foods_include": "",
         "rule_text": "Ограничь продукты с высоким калием. Риск гиперкалиемии."},
        {"drug_keyword": "литий", "drug_name": "Литий", "severity": "critical", "category": "psychiatric",
         "foods_avoid": "",
         "foods_include": "стабильное потребление соли и жидкости",
         "rule_text": "Стабильное потребление соли и жидкости. Резкие изменения водного баланса опасны — литий накапливается."},
        {"drug_keyword": "ингибитор мао", "drug_name": "Ингибиторы МАО", "severity": "critical", "category": "psychiatric",
         "foods_avoid": "выдержанные сыры, копчёности, квашеная капуста, соевый соус, красное вино, пиво",
         "foods_include": "",
         "rule_text": "ЗАПРЕЩЕНЫ тирамин-содержащие продукты: выдержанные сыры, копчёности, квашеная капуста, соевый соус, красное вино. Риск гипертонического криза."},
        {"drug_keyword": "аллопуринол", "drug_name": "Аллопуринол", "severity": "moderate", "category": "gout",
         "foods_avoid": "алкоголь, красное мясо, субпродукты, морепродукты",
         "foods_include": "вишня, вода (2+ литра/день)",
         "rule_text": "Исключи пурин-богатые продукты: красное мясо, субпродукты, морепродукты, пиво. Увеличь потребление воды."},
        {"drug_keyword": "омепразол", "drug_name": "Омепразол / ИПП", "severity": "moderate", "category": "ppi",
         "foods_avoid": "",
         "foods_include": "продукты с B12, кальций, магний",
         "rule_text": "Длительный приём ИПП снижает усвоение B12, кальция и магния. Компенсируй через пищу или добавки."},
    ]
    for item in data:
        db.add(DrugFoodInteraction(**item))
    db.commit()
    print(f"✅ Seeded {len(data)} drug-food interactions")


def seed_ingredients_reference(db):
    """Core ingredients USDA-like reference (per 100g raw). Top-50 most used in ejeweeka plans."""
    data = [
        # ── Мясо и птица ──
        {"name_ru": "Куриная грудка", "name_en": "Chicken breast", "calories": 165, "protein": 31, "fat": 3.6, "carbs": 0, "fiber": 0, "category": "мясо", "is_budget_friendly": True},
        {"name_ru": "Куриное бедро", "name_en": "Chicken thigh", "calories": 209, "protein": 26, "fat": 10.9, "carbs": 0, "fiber": 0, "category": "мясо", "is_budget_friendly": True},
        {"name_ru": "Говядина (лопатка)", "name_en": "Beef chuck", "calories": 250, "protein": 26, "fat": 15, "carbs": 0, "fiber": 0, "category": "мясо", "is_budget_friendly": False},
        {"name_ru": "Индейка (филе)", "name_en": "Turkey breast", "calories": 157, "protein": 30, "fat": 3.2, "carbs": 0, "fiber": 0, "category": "мясо", "is_budget_friendly": True},
        {"name_ru": "Печень говяжья", "name_en": "Beef liver", "calories": 135, "protein": 20, "fat": 3.6, "carbs": 3.9, "fiber": 0, "category": "мясо", "is_budget_friendly": True},
        {"name_ru": "Яйцо куриное", "name_en": "Egg", "calories": 155, "protein": 13, "fat": 11, "carbs": 1.1, "fiber": 0, "category": "яйца", "is_budget_friendly": True},
        # ── Рыба ──
        {"name_ru": "Минтай", "name_en": "Alaska pollock", "calories": 82, "protein": 17.6, "fat": 0.9, "carbs": 0, "fiber": 0, "category": "рыба", "is_budget_friendly": True},
        {"name_ru": "Лосось", "name_en": "Salmon", "calories": 208, "protein": 20, "fat": 13.4, "carbs": 0, "fiber": 0, "category": "рыба", "is_budget_friendly": False},
        {"name_ru": "Хек", "name_en": "Hake", "calories": 86, "protein": 17.2, "fat": 2.2, "carbs": 0, "fiber": 0, "category": "рыба", "is_budget_friendly": True},
        {"name_ru": "Тунец консервированный", "name_en": "Canned tuna", "calories": 116, "protein": 25.5, "fat": 0.8, "carbs": 0, "fiber": 0, "category": "рыба", "is_budget_friendly": True},
        # ── Крупы ──
        {"name_ru": "Рис белый (сухой)", "name_en": "White rice", "calories": 360, "protein": 6.7, "fat": 0.7, "carbs": 79, "fiber": 1.3, "category": "крупы", "is_budget_friendly": True},
        {"name_ru": "Гречка (сухая)", "name_en": "Buckwheat", "calories": 343, "protein": 13.3, "fat": 3.4, "carbs": 68, "fiber": 10, "category": "крупы", "is_budget_friendly": True},
        {"name_ru": "Овсянка (сухая)", "name_en": "Oats", "calories": 379, "protein": 13.2, "fat": 6.5, "carbs": 66, "fiber": 10.1, "category": "крупы", "is_budget_friendly": True},
        {"name_ru": "Перловка (сухая)", "name_en": "Pearl barley", "calories": 315, "protein": 9.3, "fat": 1.2, "carbs": 66, "fiber": 15.6, "category": "крупы", "is_budget_friendly": True},
        {"name_ru": "Макароны (сухие)", "name_en": "Pasta", "calories": 371, "protein": 13, "fat": 1.5, "carbs": 75, "fiber": 3.2, "category": "крупы", "is_budget_friendly": True},
        # ── Овощи ──
        {"name_ru": "Брокколи", "name_en": "Broccoli", "calories": 34, "protein": 2.8, "fat": 0.4, "carbs": 7, "fiber": 2.6, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Шпинат", "name_en": "Spinach", "calories": 23, "protein": 2.9, "fat": 0.4, "carbs": 3.6, "fiber": 2.2, "category": "овощи", "allergen_tags": "витамин K", "is_budget_friendly": True},
        {"name_ru": "Помидор", "name_en": "Tomato", "calories": 18, "protein": 0.9, "fat": 0.2, "carbs": 3.9, "fiber": 1.2, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Огурец", "name_en": "Cucumber", "calories": 15, "protein": 0.7, "fat": 0.1, "carbs": 3.6, "fiber": 0.5, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Капуста белокочанная", "name_en": "Cabbage", "calories": 25, "protein": 1.3, "fat": 0.1, "carbs": 5.8, "fiber": 2.5, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Морковь", "name_en": "Carrot", "calories": 41, "protein": 0.9, "fat": 0.2, "carbs": 10, "fiber": 2.8, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Свёкла", "name_en": "Beetroot", "calories": 43, "protein": 1.6, "fat": 0.2, "carbs": 10, "fiber": 2.8, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Картофель", "name_en": "Potato", "calories": 77, "protein": 2, "fat": 0.1, "carbs": 17, "fiber": 2.2, "category": "овощи", "is_budget_friendly": True},
        {"name_ru": "Лук репчатый", "name_en": "Onion", "calories": 40, "protein": 1.1, "fat": 0.1, "carbs": 9.3, "fiber": 1.7, "category": "овощи", "is_budget_friendly": True},
        # ── Бобовые ──
        {"name_ru": "Чечевица (сухая)", "name_en": "Lentils", "calories": 352, "protein": 25, "fat": 1.1, "carbs": 60, "fiber": 10.7, "category": "бобовые", "is_budget_friendly": True},
        {"name_ru": "Нут (сухой)", "name_en": "Chickpeas", "calories": 364, "protein": 19, "fat": 6, "carbs": 61, "fiber": 17, "category": "бобовые", "is_budget_friendly": True},
        {"name_ru": "Фасоль (сухая)", "name_en": "Beans", "calories": 333, "protein": 23, "fat": 0.8, "carbs": 60, "fiber": 15.2, "category": "бобовые", "is_budget_friendly": True},
        # ── Молочные ──
        {"name_ru": "Творог 5%", "name_en": "Cottage cheese 5%", "calories": 121, "protein": 17, "fat": 5, "carbs": 1.8, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
        {"name_ru": "Кефир 1%", "name_en": "Kefir 1%", "calories": 40, "protein": 3.3, "fat": 1, "carbs": 4.7, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
        {"name_ru": "Йогурт натуральный", "name_en": "Plain yogurt", "calories": 59, "protein": 3.5, "fat": 3.3, "carbs": 4.7, "fiber": 0, "category": "молочные", "allergen_tags": "лактоза", "is_budget_friendly": True},
        # ── Фрукты ──
        {"name_ru": "Яблоко", "name_en": "Apple", "calories": 52, "protein": 0.3, "fat": 0.2, "carbs": 14, "fiber": 2.4, "category": "фрукты", "is_budget_friendly": True},
        {"name_ru": "Банан", "name_en": "Banana", "calories": 89, "protein": 1.1, "fat": 0.3, "carbs": 23, "fiber": 2.6, "category": "фрукты", "is_budget_friendly": True},
        {"name_ru": "Авокадо", "name_en": "Avocado", "calories": 160, "protein": 2, "fat": 15, "carbs": 9, "fiber": 7, "category": "фрукты", "is_budget_friendly": False},
        # ── Масла и жиры ──
        {"name_ru": "Оливковое масло", "name_en": "Olive oil", "calories": 884, "protein": 0, "fat": 100, "carbs": 0, "fiber": 0, "category": "масла", "is_budget_friendly": True},
        {"name_ru": "Сливочное масло", "name_en": "Butter", "calories": 717, "protein": 0.9, "fat": 81, "carbs": 0.1, "fiber": 0, "category": "масла", "allergen_tags": "лактоза", "is_budget_friendly": True},
        # ── Орехи и семена ──
        {"name_ru": "Миндаль", "name_en": "Almonds", "calories": 579, "protein": 21, "fat": 50, "carbs": 22, "fiber": 12.5, "category": "орехи", "allergen_tags": "орехи", "is_budget_friendly": False},
        {"name_ru": "Грецкий орех", "name_en": "Walnuts", "calories": 654, "protein": 15, "fat": 65, "carbs": 14, "fiber": 6.7, "category": "орехи", "allergen_tags": "орехи", "is_budget_friendly": False},
        {"name_ru": "Семена льна", "name_en": "Flaxseeds", "calories": 534, "protein": 18, "fat": 42, "carbs": 29, "fiber": 27, "category": "семена", "is_budget_friendly": True},
        # ── Хлеб ──
        {"name_ru": "Хлеб цельнозерновой", "name_en": "Whole wheat bread", "calories": 247, "protein": 13, "fat": 3.4, "carbs": 41, "fiber": 6, "category": "хлеб", "allergen_tags": "глютен", "is_budget_friendly": True},
    ]
    for item in data:
        db.add(IngredientReference(**item))
    db.commit()
    print(f"✅ Seeded {len(data)} ingredient references")


def main():
    """Create tables and seed data."""
    # Create tables
    from app.models.safety_tables import VitaminInteraction, DrugFoodInteraction, IngredientReference
    Base.metadata.create_all(bind=engine, tables=[
        VitaminInteraction.__table__,
        DrugFoodInteraction.__table__,
        IngredientReference.__table__,
    ])
    print("✅ Created safety tables")

    db = SessionLocal()
    try:
        # Check if already seeded
        if db.query(VitaminInteraction).count() == 0:
            seed_vitamin_interactions(db)
        else:
            print("⚠️ vitamin_interactions already seeded, skipping")

        if db.query(DrugFoodInteraction).count() == 0:
            seed_drug_food_interactions(db)
        else:
            print("⚠️ drug_food_interactions already seeded, skipping")

        if db.query(IngredientReference).count() == 0:
            seed_ingredients_reference(db)
        else:
            print("⚠️ ingredients_reference already seeded, skipping")
    finally:
        db.close()

    print("\n🎉 Safety tables seeded successfully!")


if __name__ == "__main__":
    main()
