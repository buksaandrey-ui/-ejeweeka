#!/usr/bin/env python3
"""
Health Code / AIDiet — E2E Full Audit Script v2.0
Runs 391+ automated checks across all frontend files.

Usage:
    cd 05_ui_screens/main-screens && python3 e2e_full_audit.py
"""

import os
import re
import json
import sys
from pathlib import Path
from collections import defaultdict

# ══════════════════════════════════════════════
# CONFIG
# ══════════════════════════════════════════════
BASE = Path(__file__).parent
BACKEND = BASE.parent.parent / 'aidiet-backend' / 'app'

PASS = 0
FAIL = 0
WARN = 0
results = []

def check(name, condition, detail=''):
    global PASS, FAIL
    if condition:
        PASS += 1
        results.append(('✅', name, ''))
    else:
        FAIL += 1
        results.append(('❌', name, detail))
        print(f"  ❌ FAIL: {name} — {detail}")

def warn(name, detail=''):
    global WARN
    WARN += 1
    results.append(('⚠️', name, detail))

def read(path):
    try:
        return Path(path).read_text(encoding='utf-8', errors='ignore')
    except FileNotFoundError:
        return ''

# ══════════════════════════════════════════════
# BLOCK 1: NAV-CHAIN — File existence (40 checks)
# ══════════════════════════════════════════════
print("\n═══ BLOCK 1: NAV-CHAIN (File existence) ═══")

REQUIRED_FILES = [
    'index.html', 'o1-welcome.html', 'o1-country.html', 'o2-goal.html',
    'o3-profile.html', 'o4-weight-loss.html', 'o5-restrictions.html',
    'o6-health-core.html', 'o7-health-women.html', 'o8-habits.html',
    'o9-sleep.html', 'o10-activity.html', 'o11-budget-cooking.html',
    'o12-blood-tests.html', 'o13-supplements.html', 'o14-motivation.html',
    'o15-preferences.html', 'o16-summary-analysis.html',
    'o16-5-plan-explanation.html', 'o17-statuswall.html', 'o17-5-disclaimer.html',
    'h1-dashboard.html', 'p1-weekly-plan.html', 'p2-recipe-detail.html',
    'p3-replace-meal.html', 'p4-full-recipe.html', 'p5-vitamins.html',
    'ph1-photo-analysis.html', 's1-shopping-list.html', 's2-meal-swap.html',
    'pr1-progress.html', 'pr2-ai-report.html',
    'u1-profile-main.html', 'u2-personal-data.html', 'u3-health-settings.html',
    'u12-subscription.html', 'u13-themes.html',
    'c1-ai-chat.html', 'f1-family-group.html',
    'privacy.html', 'terms.html',
]

for f in REQUIRED_FILES:
    check(f"NAV-FILE: {f}", (BASE / f).exists(), f'File missing: {f}')

# ══════════════════════════════════════════════
# BLOCK 2: NAV-BACK — Back buttons (14 checks)
# ══════════════════════════════════════════════
print("\n═══ BLOCK 2: NAV-BACK (Back buttons) ═══")

BACK_SCREENS = [
    'o2-goal.html', 'o3-profile.html', 'o4-weight-loss.html',
    'o5-restrictions.html', 'o6-health-core.html', 'o7-health-women.html',
    'o8-habits.html', 'o9-sleep.html', 'o10-activity.html',
    'o11-budget-cooking.html', 'o12-blood-tests.html', 'o13-supplements.html',
    'o14-motivation.html', 'o15-preferences.html',
]

for f in BACK_SCREENS:
    content = read(BASE / f)
    has_back = 'btn-back' in content or 'btnBack' in content or '← Назад' in content
    check(f"NAV-BACK: {f}", has_back, 'No back button found')

# ══════════════════════════════════════════════
# BLOCK 3: SSOT — State module integration (77+ checks)
# ══════════════════════════════════════════════
print("\n═══ BLOCK 3: SSOT (State module) ═══")

ONBOARDING_SCREENS = [
    'o1-welcome.html', 'o2-goal.html', 'o3-profile.html',
    'o4-weight-loss.html', 'o5-restrictions.html', 'o6-health-core.html',
    'o7-health-women.html', 'o8-habits.html', 'o9-sleep.html',
    'o10-activity.html', 'o11-budget-cooking.html', 'o12-blood-tests.html',
    'o13-supplements.html', 'o14-motivation.html', 'o15-preferences.html',
    'o16-summary-analysis.html', 'o17-statuswall.html',
]

# onboarding-state.js is the entry point that dynamically loads state-contract.js and i18n.js
# So we only need to check that onboarding-state.js is included
for f in ONBOARDING_SCREENS:
    content = read(BASE / f)
    check(f"SSOT: {f} includes onboarding-state.js", 'onboarding-state.js' in content,
          'onboarding-state.js not referenced')

# No direct localStorage writes in onboarding screens (should use saveField)
for f in ONBOARDING_SCREENS:
    content = read(BASE / f)
    # Find direct localStorage.setItem('aidiet_profile') — BAD
    direct_writes = re.findall(r"localStorage\.setItem\s*\(\s*['\"]aidiet_profile['\"]", content)
    check(f"SSOT-NO-DIRECT: {f}", len(direct_writes) == 0,
          f'Direct localStorage write to aidiet_profile found ({len(direct_writes)} occurrences)')

# ══════════════════════════════════════════════
# BLOCK 4: ENGLISH-ONLY KEYS (critical law)
# ══════════════════════════════════════════════
print("\n═══ BLOCK 4: ENGLISH-ONLY KEYS ═══")

cyrillic_key_pattern = re.compile(r"saveField\s*\(\s*'[А-Яа-яЁё]")
all_js_html = list(BASE.glob('*.html')) + list(BASE.glob('*.js'))

for f in all_js_html:
    content = read(f)
    matches = cyrillic_key_pattern.findall(content)
    # Exclude comments
    real_matches = []
    for line_no, line in enumerate(content.split('\n'), 1):
        stripped = line.strip()
        if stripped.startswith('//') or stripped.startswith('*'):
            continue
        if cyrillic_key_pattern.search(line):
            real_matches.append((line_no, stripped[:80]))
    check(f"EN-KEY: {f.name}", len(real_matches) == 0,
          f'Cyrillic saveField key at lines: {[r[0] for r in real_matches]}')

# ══════════════════════════════════════════════
# BLOCK 5: PROFILE-MAP — Summary screen coverage
# ══════════════════════════════════════════════
print("\n═══ BLOCK 5: PROFILE-MAP (Summary) ═══")

# O-16 uses getProfile() dynamically — check that getProfile is called and key sections exist
summary_content = read(BASE / 'o16-summary-analysis.html')
check("PROFILE-MAP: getProfile() used", 'getProfile' in summary_content, 'No getProfile() call in O-16')
check("PROFILE-MAP: profile section rendering", 'section' in summary_content.lower(), 'No sections in O-16')

# Check key UI sections exist in summary
SUMMARY_SECTIONS = ['профиль', 'Цель', 'Здоровье', 'Питание', 'Активность', 'Аллерг']
for section in SUMMARY_SECTIONS:
    check(f"PROFILE-MAP: section '{section}' in O-16",
          section in summary_content or section.lower() in summary_content.lower(),
          f'Section {section} not found in summary screen')

# ══════════════════════════════════════════════
# BLOCK 6: API-PAYLOAD — profile-to-api.js coverage
# ══════════════════════════════════════════════
print("\n═══ BLOCK 6: API-PAYLOAD ═══")

api_content = read(BASE / 'profile-to-api.js')
API_PAYLOAD_FIELDS = [
    'age', 'gender', 'weight', 'height', 'goal',
    'allergies', 'restrictions', 'diseases', 'medications',
    'country', 'city', 'tier', 'activity_level',
    'meal_pattern', 'fasting_status', 'sleep_schedule',
    'liked_foods', 'disliked_foods',
]

for field in API_PAYLOAD_FIELDS:
    check(f"API-PAYLOAD: {field}", field in api_content,
          f'Field {field} not found in profile-to-api.js')

# Goal normalization
GOAL_KEYS = ['weight_loss', 'muscle_gain', 'maintenance', 'energy',
             'skin_health', 'health_restrictions', 'age_adaptation',
             'sugar_craving', 'recovery']

contract_content = read(BASE / 'state-contract.js')
for goal in GOAL_KEYS:
    check(f"GOAL-NORM: {goal}", goal in contract_content,
          f'Goal key {goal} not in VALUE_NORMALIZE')

# ══════════════════════════════════════════════
# BLOCK 7: BACKEND — Python syntax + coverage
# ══════════════════════════════════════════════
print("\n═══ BLOCK 7: BACKEND ═══")

PY_FILES = list(BACKEND.glob('**/*.py'))
for f in PY_FILES:
    if '__pycache__' in str(f):
        continue
    try:
        compile(read(f), str(f), 'exec')
        check(f"PY-SYNTAX: {f.name}", True)
    except SyntaxError as e:
        check(f"PY-SYNTAX: {f.name}", False, f'SyntaxError at line {e.lineno}: {e.msg}')

# Assembler safety checks
assembler = read(BACKEND / 'services' / 'assembler.py')
check("ASSEMBLER: drug interactions", 'DRUG_FOOD_RULES' in assembler, 'Missing drug-food interaction matrix')
check("ASSEMBLER: vitamin rules", '_build_vitamin_rules' in assembler, 'Missing vitamin conflict rules')
check("ASSEMBLER: disease macros", '_build_disease_macro_rules' in assembler, 'Missing disease macro limits')
check("ASSEMBLER: blood tests", '_build_blood_test_context' in assembler, 'Missing blood test parser')
check("ASSEMBLER: pregnancy guard", 'Беременность' in assembler or 'беремен' in assembler, 'Missing pregnancy guardrail')
check("ASSEMBLER: season/month", 'strftime' in assembler, 'Missing season/month in prompt')
check("ASSEMBLER: muscle no training", 'набрать' in assembler and 'не готов' in assembler, 'Missing muscle gain without training guard')

# Plan.py checks
plan = read(BACKEND / 'api' / 'plan.py')
check("PLAN: floor calories", '1000' in plan and '1300' in plan, 'Missing floor calorie limits')
check("PLAN: meal_pattern respect", 'meal_pattern' in plan, 'Missing meal_pattern handling')

# ══════════════════════════════════════════════
# BLOCK 8: MED-SAFETY
# ══════════════════════════════════════════════
print("\n═══ BLOCK 8: MED-SAFETY ═══")

medsafety = read(BASE / 'medical-safety.js')
check("MED-SAFETY: exists", len(medsafety) > 100, 'medical-safety.js missing or empty')
check("MED-SAFETY: criticalDiagnoses", 'criticalDiagnoses' in medsafety, 'Missing criticalDiagnoses array')
check("MED-SAFETY: pregnancy", 'Беременность' in medsafety, 'Missing pregnancy in critical diagnoses')
check("MED-SAFETY: diabetes", 'Диабет' in medsafety, 'Missing diabetes in critical diagnoses')
check("MED-SAFETY: safe pace 0.5", '0.5' in medsafety, 'Missing safe pace override')

# ══════════════════════════════════════════════
# BLOCK 9: THEME ENGINE
# ══════════════════════════════════════════════
print("\n═══ BLOCK 9: THEMES ═══")

theme = read(BASE / 'theme-engine.js')
# Actual themes: Светлая, Тёмная, Океан, Закат, Лес, Gold Status, Сезонная
THEMES = ['Светлая', 'Тёмная', 'Океан', 'Закат', 'Лес', 'Gold Status', 'Сезонная']
for t in THEMES:
    check(f"THEME: {t}", t in theme, f'Theme {t} not found in theme-engine.js')

# ══════════════════════════════════════════════
# BLOCK 10: JS DEPENDENCIES
# ══════════════════════════════════════════════
print("\n═══ BLOCK 10: JS-DEPS (script src) ═══")

script_src_pattern = re.compile(r'<script[^>]+src=["\']([^"\']+\.js)["\']', re.IGNORECASE)
all_html = list(BASE.glob('*.html'))
dep_checks = 0

for f in all_html:
    content = read(f)
    for match in script_src_pattern.finditer(content):
        src = match.group(1)
        # Skip CDN scripts
        if src.startswith('http') or src.startswith('//'):
            continue
        dep_path = BASE / src
        dep_checks += 1
        check(f"JS-DEP: {f.name} → {src}", dep_path.exists(),
              f'Script not found: {src}')

# ══════════════════════════════════════════════
# BLOCK 11: LIFECYCLE — Data cleanup
# ══════════════════════════════════════════════
print("\n═══ BLOCK 11: LIFECYCLE ═══")

onboarding_state = read(BASE / 'onboarding-state.js')
check("LC-01: sex→male cleanup", "womens_health" in onboarding_state and "sex" in onboarding_state and "delete" in onboarding_state,
      'Missing auto-cleanup of womens_health on sex change')
check("LC-02: goal cleanup", "target_weight_kg" in onboarding_state and "primary_goal" in onboarding_state and "delete" in onboarding_state,
      'Missing auto-cleanup of O-4 data on goal change')

# ══════════════════════════════════════════════
# BLOCK 12: TRIAL EXPIRY
# ══════════════════════════════════════════════
print("\n═══ BLOCK 12: TRIAL ═══")

api_conn = read(BASE / 'api-connector.js')
check("TRIAL: expiry logic active", 'daysSinceLaunch > 3' in api_conn, 'Trial expiry check missing or commented out')
check("TRIAL: no forced Gold", 'Testing mode: Forced Gold' not in api_conn, 'Forced Gold testing override still active!')
check("TRIAL: trial_active flag", 'aidiet_trial_active' in api_conn, 'Missing trial_active flag')

# ══════════════════════════════════════════════
# BLOCK 13: SLEEP DURATION FIX
# ══════════════════════════════════════════════
print("\n═══ BLOCK 13: SLEEP ═══")

o9 = read(BASE / 'o9-sleep.html')
check("SLEEP: duration in hours", '/ 60' in o9 and 'sleep_duration_hours' in o9,
      'sleep_duration_hours still saves minutes instead of hours')
check("SLEEP: EN key hydration", "prof['sleep_time']" in o9 or 'sleep_time' in o9,
      'O-9 hydration not using English canonical keys')

# ══════════════════════════════════════════════
# BLOCK 14: AGE/GOAL VALIDATION
# ══════════════════════════════════════════════
print("\n═══ BLOCK 14: AGE/GOAL ═══")

o3 = read(BASE / 'o3-profile.html')
check("AGE-GOAL: validation exists", 'age_adaptation' in o3 or '60+' in o3,
      'Missing age/goal mismatch validation on O-3')

# ══════════════════════════════════════════════
# RESULTS
# ══════════════════════════════════════════════
print("\n" + "═" * 60)
print(f"  ✅ PASSED:  {PASS}")
print(f"  ❌ FAILED:  {FAIL}")
print(f"  ⚠️  WARNS:   {WARN}")
total = PASS + FAIL
print(f"  📊 TOTAL:   {total} checks")
print(f"  📈 SCORE:   {PASS}/{total} ({(PASS/total*100):.1f}%)" if total > 0 else "")
print("═" * 60)

if FAIL > 0:
    print(f"\n🔴 {FAIL} FAILURES found. Fix before proceeding!")
    sys.exit(1)
else:
    print("\n🟢 ALL CHECKS PASSED! Ready for next phase.")
    sys.exit(0)
