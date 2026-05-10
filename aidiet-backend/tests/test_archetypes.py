"""
E2E Tests for ArchetypePromptFactory
Validates all 30+ archetype combinations for:
1. Correct archetype_code generation
2. Presence of mandatory keywords in prompt
3. Absence of forbidden clinical terms
4. Pregnancy/BF safety overrides
5. Fuzzy goal matching
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.archetypes import (
    ArchetypePromptFactory, GoalCluster, LifeStage
)

PASSED = 0
FAILED = 0
ERRORS = []


def assert_contains(prompt: str, keyword: str, context: str):
    global PASSED, FAILED, ERRORS
    if keyword.lower() in prompt.lower():
        PASSED += 1
    else:
        FAILED += 1
        ERRORS.append(f"❌ [{context}] Missing keyword: '{keyword}'")


def assert_not_contains(prompt: str, keyword: str, context: str):
    global PASSED, FAILED, ERRORS
    if keyword.lower() not in prompt.lower():
        PASSED += 1
    else:
        FAILED += 1
        ERRORS.append(f"❌ [{context}] Forbidden keyword found: '{keyword}'")


def assert_equals(actual, expected, context: str):
    global PASSED, FAILED, ERRORS
    if actual == expected:
        PASSED += 1
    else:
        FAILED += 1
        ERRORS.append(f"❌ [{context}] Expected '{expected}', got '{actual}'")


# ═══════════════════════════════════════════════════════════════
# TEST 1: Goal Classification (9 goals → 5 clusters)
# ═══════════════════════════════════════════════════════════════
print("=" * 60)
print("TEST 1: Goal Classification")
print("=" * 60)

goal_tests = [
    ('weight_loss', GoalCluster.DEFICIT),
    ('reduce_cravings', GoalCluster.DEFICIT),
    ('Снизить вес', GoalCluster.DEFICIT),
    ('muscle_gain', GoalCluster.SURPLUS),
    ('Набрать мышечную массу', GoalCluster.SURPLUS),
    ('maintenance', GoalCluster.BALANCE),
    ('improve_energy', GoalCluster.BALANCE),
    ('health_restrictions', GoalCluster.THERAPEUTIC),
    ('recovery', GoalCluster.THERAPEUTIC),
    ('skin_hair_nails', GoalCluster.AESTHETIC),
    ('age_adaptation', GoalCluster.AESTHETIC),
    # Fuzzy matching
    ('Хочу похудеть', GoalCluster.DEFICIT),
    ('Набрать массу', GoalCluster.SURPLUS),
    ('Красивая кожа', GoalCluster.AESTHETIC),
    ('Восстановление', GoalCluster.THERAPEUTIC),
    # Unknown → BALANCE (safe default)
    ('что-то непонятное', GoalCluster.BALANCE),
    ('', GoalCluster.BALANCE),
]

for goal, expected_cluster in goal_tests:
    result = ArchetypePromptFactory.classify_goal(goal)
    assert_equals(result, expected_cluster, f"classify_goal('{goal}')")

print(f"  ✓ {len(goal_tests)} goal classification tests")


# ═══════════════════════════════════════════════════════════════
# TEST 2: Life Stage Classification
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("TEST 2: Life Stage Classification")
print("=" * 60)

age_tests = [
    (18, LifeStage.YOUNG), (25, LifeStage.YOUNG), (39, LifeStage.YOUNG),
    (40, LifeStage.MATURE), (50, LifeStage.MATURE), (59, LifeStage.MATURE),
    (60, LifeStage.SENIOR), (75, LifeStage.SENIOR), (99, LifeStage.SENIOR),
]

for age, expected_stage in age_tests:
    result = ArchetypePromptFactory.classify_life_stage(age)
    assert_equals(result, expected_stage, f"classify_life_stage({age})")

print(f"  ✓ {len(age_tests)} age classification tests")


# ═══════════════════════════════════════════════════════════════
# TEST 3: Archetype Code Generation (all 30 combos)
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("TEST 3: Archetype Code Generation")
print("=" * 60)

archetype_tests = [
    # (goal, gender, age, womens_health, expected_code)
    ('weight_loss', 'male', 25, None, 'DEFICIT_M_YOUNG'),
    ('weight_loss', 'female', 25, None, 'DEFICIT_F_YOUNG'),
    ('weight_loss', 'male', 50, None, 'DEFICIT_M_MATURE'),
    ('weight_loss', 'female', 50, None, 'DEFICIT_F_MATURE'),
    ('weight_loss', 'male', 65, None, 'DEFICIT_M_SENIOR'),
    ('weight_loss', 'female', 65, None, 'DEFICIT_F_SENIOR'),
    ('muscle_gain', 'male', 25, None, 'SURPLUS_M_YOUNG'),
    ('muscle_gain', 'female', 30, None, 'SURPLUS_F_YOUNG'),
    ('muscle_gain', 'male', 45, None, 'SURPLUS_M_MATURE'),
    ('maintenance', 'male', 25, None, 'BALANCE_M_YOUNG'),
    ('improve_energy', 'female', 55, None, 'BALANCE_F_MATURE'),
    ('maintenance', 'male', 70, None, 'BALANCE_M_SENIOR'),
    ('health_restrictions', 'female', 35, None, 'THERAPEUTIC_F_YOUNG'),
    ('recovery', 'male', 50, None, 'THERAPEUTIC_M_MATURE'),
    ('skin_hair_nails', 'female', 28, None, 'AESTHETIC_F_YOUNG'),
    ('age_adaptation', 'male', 55, None, 'AESTHETIC_M_MATURE'),
    # Pregnancy override
    ('weight_loss', 'female', 30, ['Беременность'], 'DEFICIT_F_YOUNG_PREG'),
    ('maintenance', 'female', 35, ['Беременность'], 'BALANCE_F_YOUNG_PREG'),
    # Breastfeeding override
    ('weight_loss', 'female', 28, ['Кормление грудью'], 'DEFICIT_F_YOUNG_BF'),
    # Pregnancy does NOT apply to males
    ('weight_loss', 'male', 30, ['Беременность'], 'DEFICIT_M_YOUNG'),
]

for goal, gender, age, wh, expected_code in archetype_tests:
    prompt, code = ArchetypePromptFactory.get_system_role(
        goal=goal, gender=gender, age=age, womens_health=wh, days=7
    )
    assert_equals(code, expected_code, f"archetype_code({goal},{gender},{age},{wh})")

print(f"  ✓ {len(archetype_tests)} archetype code tests")


# ═══════════════════════════════════════════════════════════════
# TEST 4: Prompt Content Validation (mandatory keywords)
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("TEST 4: Prompt Content — Mandatory Keywords")
print("=" * 60)

# DEFICIT prompts must contain deficit-related terms
for age in [25, 50, 65]:
    prompt, code = ArchetypePromptFactory.get_system_role(
        goal='weight_loss', gender='male', age=age, days=7
    )
    assert_contains(prompt, 'дефицит', f'DEFICIT_M age={age}')
    assert_contains(prompt, 'сытост', f'DEFICIT_M age={age}')
    assert_contains(prompt, 'белок', f'DEFICIT_M age={age}')
    assert_contains(prompt, 'Мужчина', f'DEFICIT_M age={age}')

# SURPLUS prompts must contain surplus-related terms
for age in [25, 50, 65]:
    prompt, code = ArchetypePromptFactory.get_system_role(
        goal='muscle_gain', gender='male', age=age, days=7
    )
    assert_contains(prompt, 'профицит', f'SURPLUS_M age={age}')
    assert_contains(prompt, 'лейцин', f'SURPLUS_M age={age}')
    assert_contains(prompt, '1.8', f'SURPLUS_M age={age}')

# BALANCE prompts
prompt, _ = ArchetypePromptFactory.get_system_role(
    goal='maintenance', gender='female', age=30, days=7
)
assert_contains(prompt, 'изокалорийн', 'BALANCE_F_YOUNG')
assert_contains(prompt, 'микронутриент', 'BALANCE_F_YOUNG')
assert_contains(prompt, 'Женщина', 'BALANCE_F_YOUNG')

# THERAPEUTIC prompts
prompt, _ = ArchetypePromptFactory.get_system_role(
    goal='health_restrictions', gender='male', age=55, days=7
)
assert_contains(prompt, 'щадящ', 'THERAPEUTIC_M_MATURE')
assert_contains(prompt, 'противовоспалительн', 'THERAPEUTIC_M_MATURE')

# AESTHETIC prompts
prompt, _ = ArchetypePromptFactory.get_system_role(
    goal='skin_hair_nails', gender='female', age=28, days=7
)
assert_contains(prompt, 'антиоксидант', 'AESTHETIC_F_YOUNG')
assert_contains(prompt, 'коллаген', 'AESTHETIC_F_YOUNG')
assert_contains(prompt, 'Омега-3', 'AESTHETIC_F_YOUNG')
assert_contains(prompt, 'биотин', 'AESTHETIC_F_YOUNG')

# Age-specific content
prompt_mature, _ = ArchetypePromptFactory.get_system_role(
    goal='weight_loss', gender='female', age=50, days=7
)
assert_contains(prompt_mature, 'саркопения', 'DEFICIT_F_MATURE — age modifier')
assert_contains(prompt_mature, 'кальций', 'DEFICIT_F_MATURE — age modifier')
assert_contains(prompt_mature, '1.2', 'DEFICIT_F_MATURE — protein target')

prompt_senior, _ = ArchetypePromptFactory.get_system_role(
    goal='maintenance', gender='male', age=70, days=7
)
assert_contains(prompt_senior, 'B12', 'BALANCE_M_SENIOR — B12')
assert_contains(prompt_senior, '1200мг', 'BALANCE_M_SENIOR — calcium')
assert_contains(prompt_senior, 'жеванием', 'BALANCE_M_SENIOR — texture')

print(f"  ✓ Content validation tests complete")


# ═══════════════════════════════════════════════════════════════
# TEST 5: Pregnancy/BF Safety Override
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("TEST 5: Pregnancy/BF Safety Overrides")
print("=" * 60)

# Pregnancy: MUST override deficit goal
prompt_preg, code_preg = ArchetypePromptFactory.get_system_role(
    goal='weight_loss', gender='female', age=30,
    womens_health=['Беременность'], days=7
)
assert_contains(prompt_preg, 'ДЕФИЦИТ КАЛОРИЙ КАТЕГОРИЧЕСКИ ЗАПРЕЩЁН', 'PREG override — deficit ban')
assert_contains(prompt_preg, 'фолиевая', 'PREG override — folic acid')
assert_contains(prompt_preg, '≥600мкг', 'PREG override — folic dose')
assert_contains(prompt_preg, 'сырая рыба', 'PREG override — banned foods')
assert_contains(prompt_preg, 'АБСОЛЮТНЫЙ ЗАПРЕТ', 'PREG override — alcohol ban')
assert_contains(prompt_preg, '≤200мг', 'PREG override — caffeine limit')

# Breastfeeding
prompt_bf, code_bf = ArchetypePromptFactory.get_system_role(
    goal='weight_loss', gender='female', age=28,
    womens_health=['Кормление грудью'], days=7
)
assert_contains(prompt_bf, '1800 ккал', 'BF override — floor 1800')
assert_contains(prompt_bf, 'лактац', 'BF override — lactation')
assert_contains(prompt_bf, '≥1.3 г/кг', 'BF override — protein')

# Male should NOT get pregnancy override
prompt_male_preg, code_male = ArchetypePromptFactory.get_system_role(
    goal='weight_loss', gender='male', age=30,
    womens_health=['Беременность'], days=7
)
assert_not_contains(prompt_male_preg, 'БЕРЕМЕННОСТЬ', 'Male — no pregnancy override')
assert_equals(code_male, 'DEFICIT_M_YOUNG', 'Male — code no PREG suffix')

print(f"  ✓ Pregnancy/BF safety tests complete")


# ═══════════════════════════════════════════════════════════════
# TEST 6: Compliance — No Forbidden Clinical Terms
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("TEST 6: Compliance — Forbidden Term Sweep")
print("=" * 60)

FORBIDDEN_TERMS = [
    'диагноз', 'диагностик', 'лечение', 'лечить', 'терапия',
    'назначение', 'рецепт врача', 'медицинский прибор',
]

# Check all 5 cluster base prompts × 2 genders × 3 ages = 30 combos
all_goals = ['weight_loss', 'muscle_gain', 'maintenance', 'health_restrictions', 'skin_hair_nails']
all_genders = ['male', 'female']
all_ages = [25, 50, 65]

combo_count = 0
for goal in all_goals:
    for gender in all_genders:
        for age in all_ages:
            prompt, code = ArchetypePromptFactory.get_system_role(
                goal=goal, gender=gender, age=age, days=7
            )
            for term in FORBIDDEN_TERMS:
                assert_not_contains(prompt, term, f'{code} — forbidden: {term}')
            combo_count += 1

print(f"  ✓ {combo_count} combos × {len(FORBIDDEN_TERMS)} terms = {combo_count * len(FORBIDDEN_TERMS)} compliance checks")


# ═══════════════════════════════════════════════════════════════
# TEST 7: wellness_rationale referenced in all cluster prompts
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print("TEST 7: wellness_rationale Key in All Clusters")
print("=" * 60)

for goal in all_goals:
    prompt, code = ArchetypePromptFactory.get_system_role(
        goal=goal, gender='female', age=30, days=7
    )
    assert_contains(prompt, 'wellness_rationale', f'{code} — wellness_rationale reference')

print(f"  ✓ {len(all_goals)} cluster prompts verified")


# ═══════════════════════════════════════════════════════════════
# RESULTS
# ═══════════════════════════════════════════════════════════════
print("\n" + "=" * 60)
print(f"RESULTS: {PASSED} PASSED, {FAILED} FAILED")
print("=" * 60)

if ERRORS:
    print("\nFAILURES:")
    for err in ERRORS:
        print(f"  {err}")
    sys.exit(1)
else:
    print("\n✅ ALL TESTS PASSED")
    sys.exit(0)
