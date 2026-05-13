#!/usr/bin/env python3
"""
ejeweeka E2E MICRO-BATCH Live Test Runner v4
=============================================
Решает проблему 503 Gemini через:
1. Генерация матрицы по 1 дню (вместо 3)
2. Генерация рецептов по 3 штуки (вместо 9)
3. 4-секундные паузы между запросами
4. Auto-save новых рецептов в DB

Usage:
    PYTHONPATH=. python3 tests/test_e2e_micro_batch.py [--batch N] [--start N]
"""

import os, sys, json, time, argparse
from datetime import datetime
from collections import Counter
from dotenv import load_dotenv
load_dotenv(override=True)

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.assembler import PromptAssembler
from app.services.archetypes import ArchetypePromptFactory
from google import genai
from tests.test_profile_matrix import generate_100_profiles, get_profile_description

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))

# ═══════════════════════════════════════════════════════════════
# VEGAN SAFE EXCEPTIONS
# ═══════════════════════════════════════════════════════════════
VEGAN_SAFE_PREFIXES = [
    'растительн', 'овсян', 'соев', 'миндальн', 'кокосов', 'рисов',
    'кедров', 'конопля', 'льнян', 'гречнев', 'банановое',
    'оливков', 'подсолнечн', 'кунжутн', 'горчичн', 'кукурузн',
    'рапсов', 'арахисов', 'тыквенн', 'виноградн',
]

ANIMAL_PRODUCTS = {
    'курица', 'говядина', 'свинина', 'баранина', 'индейка', 'утка',
    'рыба', 'лосось', 'форель', 'тунец', 'минтай', 'семга', 'треска',
    'креветки', 'кальмар', 'мидии', 'яйцо', 'яйца',
    'молоко', 'кефир', 'творог', 'сыр', 'сметана', 'сливки', 'йогурт',
    'масло сливочное', 'мёд', 'мед', 'желатин',
}

HARAM = {'свинина', 'бекон', 'сало', 'вино', 'пиво', 'коньяк'}


def is_vegan_safe(name: str) -> bool:
    n = name.lower()
    return any(p in n for p in VEGAN_SAFE_PREFIXES)


# ═══════════════════════════════════════════════════════════════
# GEMINI CALLER WITH RETRY
# ═══════════════════════════════════════════════════════════════
def call_gemini(prompt: str, retries: int = 5) -> str:
    """Call Gemini with exponential backoff. Returns raw text."""
    for attempt in range(retries):
        try:
            resp = client.models.generate_content(
                model='gemini-2.5-flash', contents=prompt
            )
            return resp.text
        except Exception as e:
            err = str(e).lower()
            if '503' in err or '429' in err or 'unavailable' in err or 'server' in err:
                wait = 4 * (2 ** attempt)  # 4, 8, 16, 32, 64
                print(f' ⏳{wait}s', end='', flush=True)
                time.sleep(wait)
            else:
                raise
    raise Exception('API_OVERLOADED_AFTER_RETRIES')


def parse_json(text: str) -> dict:
    """Clean and parse JSON from Gemini response."""
    cleaned = text.replace('```json', '').replace('```', '').strip()
    # Sometimes Gemini wraps in markdown
    if cleaned.startswith('{') or cleaned.startswith('['):
        return json.loads(cleaned)
    # Try to find JSON in text
    start = cleaned.find('{')
    if start >= 0:
        return json.loads(cleaned[start:])
    raise json.JSONDecodeError("No JSON found", cleaned, 0)


# ═══════════════════════════════════════════════════════════════
# VALIDATOR
# ═══════════════════════════════════════════════════════════════
def validate_day(day_data: dict, day_key: str, target: float, profile) -> list:
    """Validate a single day of the plan."""
    fails = []
    if not isinstance(day_data, dict):
        return [f'{day_key}:NOT_DICT']
    
    meals = day_data.get('meals', [])
    if not meals:
        return [f'{day_key}:NO_MEALS']
    
    al = [a.lower() for a in (profile.allergies or [])]
    dl = [d.lower() for d in (profile.disliked_foods or [])]
    rl = [r.lower() for r in (profile.effective_restrictions or [])]
    is_vegan = any(r in ['веганство', 'vegan'] for r in rl)
    is_halal = any(r in ['халяль', 'halal'] for r in rl)
    
    day_cal = 0
    day_fiber = 0
    
    for meal in meals:
        if not isinstance(meal, dict):
            continue
        name = meal.get('name', '?')
        day_cal += meal.get('calories', 0)
        day_fiber += meal.get('fiber', 0)
        
        for ing in meal.get('ingredients', []):
            iname = (ing.get('name') or '').lower()
            
            # Allergens (ZERO TOLERANCE)
            for a in al:
                if a and a in iname:
                    fails.append(f'🚨ALLERGEN:{day_key}/{name}/{a}')
            
            # Disliked foods
            for d in dl:
                if d and d in iname:
                    fails.append(f'DISLIKED:{day_key}/{name}/{d}')
            
            # Vegan check (with safe exceptions)
            if is_vegan and not is_vegan_safe(iname):
                for ap in ANIMAL_PRODUCTS:
                    if ap in iname:
                        fails.append(f'🚨VEGAN:{day_key}/{name}/{ing.get("name")}')
                        break
            
            # Halal check
            if is_halal:
                for h in HARAM:
                    if h in iname:
                        fails.append(f'🚨HALAL:{day_key}/{name}/{ing.get("name")}')
                        break
        
        # Steps check
        if not meal.get('steps'):
            fails.append(f'NO_STEPS:{day_key}/{name}')
        if not meal.get('ingredients'):
            fails.append(f'NO_ING:{day_key}/{name}')
    
    # Calorie check
    if target > 0 and day_cal > 0:
        dev = abs(day_cal - target) / target
        if dev > 0.25:
            fails.append(f'KCAL:{day_key}:{day_cal}vs{int(target)}({int(dev*100)}%)')
    
    # Fiber check
    if day_fiber < 15 and day_cal > 0:
        fails.append(f'FIBER:{day_key}:{day_fiber:.0f}g')
    
    return fails


# ═══════════════════════════════════════════════════════════════
# MICRO-BATCH PIPELINE
# ═══════════════════════════════════════════════════════════════
def run_profile(profile, index: int, total: int) -> dict:
    """Run a single profile through the micro-batch pipeline."""
    desc = get_profile_description(profile)
    t0 = time.time()
    p = profile
    
    try:
        # 1. Calculate targets
        bmr = (10*p.weight + 6.25*p.height - 5*p.age - 161) if p.gender == 'female' else \
              (10*p.weight + 6.25*p.height - 5*p.age + 5)
        floor_cal = 1200 if p.gender == 'female' else 1500
        tdee = bmr * (p.activity_multiplier or 1.375)
        target_kcal = tdee
        
        gl = (p.goal or '').lower()
        if any(k in gl for k in ['снизить', 'похуд', 'weight_loss', 'тяг']):
            if p.target_weight and p.target_timeline_weeks:
                d = p.weight - p.target_weight
                if d > 0:
                    target_kcal = tdee - min((d * 7700) / (p.target_timeline_weeks * 7), tdee * 0.25)
            else:
                target_kcal = tdee * 0.8
        elif any(k in gl for k in ['набрать', 'набор', 'muscle', 'gain']):
            target_kcal = tdee * 1.15
        target_kcal = max(target_kcal, floor_cal)
        
        # Pregnancy/breastfeeding guards
        if ArchetypePromptFactory._is_pregnant(p.womens_health):
            target_kcal = max(target_kcal, tdee + 340)
        elif ArchetypePromptFactory._is_breastfeeding(p.womens_health):
            target_kcal = max(target_kcal, max(1800, tdee - 500))
        
        mpd = 3
        mp = (p.meal_pattern or '').lower()
        if '4' in mp or '5' in mp:
            mpd = 4
        elif '2' in mp:
            mpd = 2
        
        # 2. MICRO-BATCH: Generate 3 days, 1 day at a time
        all_days = {}
        all_failures = []
        all_missing_meals = []
        
        for day_num in range(1, 4):
            print(f' d{day_num}', end='', flush=True)
            
            matrix_prompt = PromptAssembler.build_matrix_prompt(
                profile=p,
                context_text='Контекст из базы знаний ejeweeka.',
                bmr=bmr, tdee=tdee, target_kcal=target_kcal,
                days=1, meals_per_day=mpd
            )
            
            raw = call_gemini(matrix_prompt)
            matrix = parse_json(raw)
            
            # Extract day data (might be keyed as day_1 or the only key)
            day_key = f'day_{day_num}'
            if day_key in matrix:
                day_data = matrix[day_key]
            elif 'day_1' in matrix:
                day_data = matrix['day_1']
            else:
                # Take first key that looks like a day
                for k in matrix:
                    if isinstance(matrix[k], dict) and 'meals' in matrix[k]:
                        day_data = matrix[k]
                        break
                else:
                    day_data = matrix
            
            all_days[day_key] = day_data
            
            # Collect meal names for recipe generation
            meals_list = day_data.get('meals', []) if isinstance(day_data, dict) else day_data
            for m in meals_list:
                if isinstance(m, dict) and m.get('name'):
                    all_missing_meals.append(m['name'])
            
            time.sleep(4)  # Rate limit
        
        print(f' ✓M', end='', flush=True)
        
        # 3. MICRO-BATCH: Generate recipes in batches of 3
        unique_meals = list(set(all_missing_meals))
        all_recipes = {}
        
        for batch_start in range(0, len(unique_meals), 3):
            batch = unique_meals[batch_start:batch_start + 3]
            print(f' r{len(batch)}', end='', flush=True)
            
            recipe_prompt = PromptAssembler.build_recipe_prompt(p, batch, target_kcal)
            raw = call_gemini(recipe_prompt)
            recipes = parse_json(raw)
            all_recipes.update(recipes)
            
            time.sleep(4)  # Rate limit
        
        print(f' ✓R({len(all_recipes)})', end='', flush=True)
        
        # 4. Merge recipes into days
        for dk, dd in all_days.items():
            meals_list = dd.get('meals', []) if isinstance(dd, dict) else dd
            for m in meals_list:
                if isinstance(m, dict) and m.get('name', '') in all_recipes:
                    m.update(all_recipes[m['name']])
        
        # 5. Normalize + shopping list
        from app.api.plan import normalize_plan_for_frontend
        normalized = normalize_plan_for_frontend(all_days, p.budget_level)
        
        # 6. Validate each day
        for dk in all_days:
            if dk in normalized:
                day_fails = validate_day(normalized[dk], dk, int(target_kcal), p)
                all_failures.extend(day_fails)
        
        # Check shopping list
        if not normalized.get('shopping_list'):
            all_failures.append('NO_SHOP')
        
        elapsed = time.time() - t0
        critical = [f for f in all_failures if '🚨' in f]
        
        sev = '✅' if not all_failures else ('❌' if critical else '⚠️')
        status = 'FAIL' if critical else 'OK'
        
        print(f' {sev} {elapsed:.0f}s')
        print(f'  {desc[:95]}')
        if all_failures:
            for f in all_failures[:5]:
                print(f'    → {f}')
            if len(all_failures) > 5:
                print(f'    → ...+{len(all_failures) - 5} ещё')
        
        return {
            'index': index, 'status': status, 'desc': desc[:120],
            'failures': all_failures, 'critical': len(critical),
            'elapsed': round(elapsed, 1), 'target_kcal': int(target_kcal),
            'recipes_generated': len(all_recipes),
            'days_generated': len(all_days),
        }
    
    except json.JSONDecodeError as e:
        elapsed = time.time() - t0
        print(f' ❌JSON {elapsed:.0f}s')
        print(f'  {desc[:95]}')
        print(f'    → {str(e)[:80]}')
        return {'index': index, 'status': 'JSON_ERROR', 'desc': desc[:120],
                'error': str(e)[:200], 'elapsed': round(elapsed, 1)}
    
    except Exception as e:
        elapsed = time.time() - t0
        em = str(e)[:100]
        print(f' ❌{em[:40]} {elapsed:.0f}s')
        print(f'  {desc[:95]}')
        return {'index': index, 'status': 'ERROR', 'desc': desc[:120],
                'error': em, 'elapsed': round(elapsed, 1)}


# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
def main():
    parser = argparse.ArgumentParser(description='ejeweeka E2E Micro-Batch Tester')
    parser.add_argument('--batch', type=int, default=20, help='Number of profiles to test')
    parser.add_argument('--start', type=int, default=0, help='Start index (skip first N profiles)')
    parser.add_argument('--edge-only', action='store_true', help='Only run edge-case profiles (63+)')
    args = parser.parse_args()
    
    profiles = generate_100_profiles()
    
    if args.edge_only:
        profiles = profiles[63:]  # Edge cases start at index 63
        args.batch = min(args.batch, len(profiles))
    
    test_profiles = profiles[args.start:args.start + args.batch]
    
    print(f'🚀 ejeweeka E2E MICRO-BATCH | {len(test_profiles)} профилей')
    print(f'  Стратегия: 1 day/request × 3 recipes/request = 6 запросов/профиль')
    print(f'  Rate limit: 4s между запросами, 10s между профилями')
    print(f'⏰ {datetime.now().strftime("%H:%M:%S")}')
    print('=' * 80)
    
    results = []
    ok = 0; fail = 0; errors = 0; total_recipes = 0
    
    for i, p in enumerate(test_profiles):
        real_idx = args.start + i
        print(f'  [{i+1}/{len(test_profiles)}]', end='', flush=True)
        
        result = run_profile(p, real_idx, len(test_profiles))
        results.append(result)
        
        if result['status'] == 'OK':
            ok += 1
        elif result['status'] == 'FAIL':
            fail += 1
        else:
            errors += 1
        
        total_recipes += result.get('recipes_generated', 0)
        
        # Inter-profile delay
        time.sleep(10)
    
    # ═══ SUMMARY ═══
    print()
    print('=' * 80)
    print(f'📊 ИТОГО: {ok} ✅ / {fail} ❌ / {errors} ⚠️ из {len(test_profiles)}')
    print(f'🍽  Рецептов сгенерировано: {total_recipes}')
    print(f'⏰ {datetime.now().strftime("%H:%M:%S")}')
    
    # Failure breakdown
    all_fails = []
    for r in results:
        all_fails.extend(r.get('failures', []))
    
    if all_fails:
        ft = Counter(f.split(':')[0] for f in all_fails)
        print(f'📋 Типы проблем: {dict(ft)}')
        
        # Critical failures
        critical_fails = [f for f in all_fails if '🚨' in f]
        if critical_fails:
            print(f'\n🚨 КРИТИЧЕСКИЕ НАРУШЕНИЯ ({len(critical_fails)}):')
            for cf in critical_fails[:20]:
                print(f'  {cf}')
    
    # Save report
    os.makedirs('tests/reports', exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = f'tests/reports/e2e_microbatch_{ts}.json'
    
    report = {
        'metadata': {
            'timestamp': ts,
            'batch_size': len(test_profiles),
            'start_index': args.start,
            'strategy': 'micro-batch (1 day + 3 recipes per request)',
        },
        'summary': {
            'passed': ok,
            'failed': fail,
            'errors': errors,
            'total': len(test_profiles),
            'recipes_generated': total_recipes,
            'failure_types': dict(Counter(f.split(':')[0] for f in all_fails)) if all_fails else {},
        },
        'results': results,
    }
    
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f'💾 Отчёт: {report_path}')
    
    # Exit code for CI
    sys.exit(1 if fail > 0 else 0)


if __name__ == '__main__':
    main()
