import sys
sys.path.insert(0, 'aidiet-backend')
from app.api.plan import normalize_plan_for_frontend
plan = {
    'day_1': [
        {
            'meal': 'Завтрак',
            'ingredients': [
                {'name': 'Овсянка', 'amount': 50, 'unit': 'г'},
                {'name': 'Молоко', 'amount': 150, 'unit': 'мл'}
            ]
        }
    ]
}
norm = normalize_plan_for_frontend(plan, budget_level="Средний")
print(norm['shopping_list'])
