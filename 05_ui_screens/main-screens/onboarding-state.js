
// ==========================================
// i18n Adapter: Russian to CANONICAL English keys/values
// Keys must match state-contract.js PROFILE_SCHEMA exactly.
// ==========================================
const DICT_KEYS = {
    'Страна': 'user_country',
    'Город': 'user_city',
    'Главная цель': 'primary_goal',
    'Имя': 'first_name',
    'Пол': 'sex',
    'Возраст': 'age',
    'Рост': 'height_cm',
    'Текущий вес': 'weight_kg',
    'Телосложение': 'body_type',
    'Обхват талии': 'waist_cm',
    'Распределение жира': 'fat_distribution',
    'Доп. Снижение веса': 'also_wants_weight_loss',
    'ИМТ': 'bmi',
    'Класс ИМТ': 'bmi_class',
    'BMR': 'bmr_kcal',
    'Талия/Рост': 'waist_to_height',
    'Целевой вес': 'target_weight_kg',
    'Срок (недель)': 'target_timeline_weeks',
    'Выбранные диеты/ограничения': 'diet_restrictions',
    'Тип питания': 'diet_restrictions',
    'Ограничение_другое': 'diet_restrictions_other',
    'Аллергии': 'allergies',
    'Есть аллергия': 'has_allergies',
    'Аллергены': 'allergies',
    'Аллергия_другое': 'allergies_other',
    'Симптомы': 'symptoms',
    'Хронические заболевания': 'chronic_conditions',
    'Принимает лекарства': 'takes_medications',
    'Женское здоровье': 'womens_health',
    'Принимает гормональные (КОК)': 'takes_contraceptives',
    'Интерес к голоданию': 'fasting_interest',
    'Голодание': 'fasting_status',
    'Сколько раз в день удобно есть?': 'meal_pattern',
    'Отбой': 'sleep_time',
    'Подъем': 'sleep_waketime',
    'Режим сна': 'sleep_type',
    'Длительность сна (мин)': 'sleep_duration_hours',
    'Тип смен': 'shift_type',
    'Средний сон (ч)': 'avg_sleep_hours',
    'Частота активности': 'activity_frequency',
    'Виды активности': 'activity_types',
    'Длительность тренировки': 'activity_duration',
    'Бюджет': 'budget_level',
    'Время на готовку': 'cooking_time',
    'Анализы': 'blood_tests',
    'БАД': 'currently_takes_supplements',
    'Принимаемые витамины': 'current_supplements_text',
    'Отношение к БАДам': 'supplement_openness',
    'Главные барьеры прошлого': 'motivation_barriers',
    'Исключённые категории': 'excluded_meal_types',
    'Любимые продукты': 'liked_foods',
    'Нелюбимые продукты': 'disliked_foods',
    // Screen titles mapping for choice cards
    'Привычки': 'fasting_status',
    'Активность': 'activity_frequency'
};

const DICT_VALS = {
    'Снизить вес': 'weight_loss',
    'Набрать мышечную массу': 'muscle_gain',
    'Поддерживать форму': 'maintenance',
    'Больше энергии и фокуса': 'energy',
    'Улучшить кожу и волосы': 'skin_health',
    'Наладить пищеварение': 'digestion',
    'Здоровье и долголетие': 'longevity',
    'Мужской': 'male',
    'Женский': 'female',
    'Худощавое': 'thin',
    'Среднее': 'average',
    'Крепкое': 'strong',
    'Спортивное': 'athletic',
    'Есть лишний вес': 'overweight',
    'Да': 'yes',
    'Нет': 'no',
    'Вегетарианство': 'vegetarian',
    'Веганство': 'vegan',
    'Пескатарианство': 'pescatarian',
    'Кето-диета': 'keto',
    'Палео-диета': 'paleo',
    'Халяль': 'halal',
    'Эконом': 'economy',
    'Средний': 'medium',
    'Премиум': 'premium'
};

const REVERSE_KEYS = Object.fromEntries(Object.entries(DICT_KEYS).map(([k, v]) => [v, k]));
const REVERSE_VALS = Object.fromEntries(Object.entries(DICT_VALS).map(([k, v]) => [v, k]));

window.i18n = {
    toEnKey: (k) => DICT_KEYS[k] || k,
    toEnVal: (v) => {
        if (typeof v !== 'string') return v;
        return v.split(', ').map(p => DICT_VALS[p.trim()] || p.trim()).join(', ');
    },
    toRuKey: (k) => REVERSE_KEYS[k] || k,
    toRuVal: (v) => {
        if (typeof v !== 'string') return v;
        return v.split(', ').map(p => REVERSE_VALS[p.trim()] || p.trim()).join(', ');
    }
};
// ==========================================

// onboarding-state.js
// Глобальный скрипт управления состоянием онбординга Health Code (Zero-Knowledge)

(function() {
  window.AIDiet = window.AIDiet || {};

  // ═══ Summary Edit Mode ═══
  // When user clicks "Изменить" on O-16, we add ?from=summary
  // This rewrites buttons and redirects back to summary after save
  const _urlParams = new URLSearchParams(window.location.search);
  window.AIDiet._fromSummary = _urlParams.get('from') === 'summary';

  // Navigation helper: redirects to summary if in edit mode
  window.AIDiet.goNext = function(defaultUrl) {
    const target = window.AIDiet._fromSummary ? 'o16-summary-analysis.html' : defaultUrl;
    if (window.smoothNavigate) {
      window.smoothNavigate(target);
    } else {
      window.location.href = target;
    }
  };

  if (window.AIDiet._fromSummary) {
    document.addEventListener('DOMContentLoaded', () => {
      // Rewrite "← Назад" → "← Отмена" → goes to summary
      const backBtn = document.querySelector('.btn-back');
      if (backBtn) {
        backBtn.textContent = '← Отмена';
        backBtn.removeAttribute('onclick');
        backBtn.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation();
          window.location.href = 'o16-summary-analysis.html';
        });
      } else {
        // Screen has no back button (e.g. O-1) — inject one
        const cta = document.querySelector('.bottom-cta');
        if (cta) {
          const cancelBtn = document.createElement('button');
          cancelBtn.className = 'btn-back';
          cancelBtn.textContent = '← Отмена';
          cancelBtn.addEventListener('click', () => {
            window.location.href = 'o16-summary-analysis.html';
          });
          cta.insertBefore(cancelBtn, cta.firstChild);
        }
      }
      // Rewrite "Далее →" → "✓ Сохранить"
      const nextBtn = document.getElementById('btnNext');
      if (nextBtn) {
        nextBtn.innerHTML = '✓ Сохранить';
      }
    });
  }

  // ═══ Schema Migration ═══
  // One-time migration: renames legacy keys to canonical names.
  // v2: Russian label renames (Пищевые ограничения → Выбранные диеты/ограничения)
  // v3: English key normalization (gender → sex, weight → weight_kg, etc.)
  (function migrateProfile() {
    const raw = localStorage.getItem('aidiet_profile');
    if (!raw) return;
    try {
      const p = JSON.parse(raw);
      if (p._schema_version >= 3) return; // already migrated

      let changed = false;

      // v2 renames (Russian label cleanup)
      if (!p._schema_version || p._schema_version < 2) {
        const v2renames = {
          'Пищевые ограничения': 'Выбранные диеты/ограничения',
          'Пищевые аллергии': 'Аллергии',
          'Лекарства': 'Принимает лекарства',
          'Особенности цикла': 'Женское здоровье',
          'Барьеры мотивации': 'Главные барьеры прошлого',
          'Какие типы блюд исключить?': 'Исключённые категории',
          'Какая у тебя сейчас главная цель?': 'Главная цель',
          'Частота приёмов пищи': 'Сколько раз в день удобно есть?',
        };
        Object.entries(v2renames).forEach(([oldKey, newKey]) => {
          if (p[oldKey] !== undefined && p[newKey] === undefined) {
            p[newKey] = p[oldKey]; delete p[oldKey]; changed = true;
          } else if (p[oldKey] !== undefined) {
            delete p[oldKey]; changed = true;
          }
        });
      }

      // v3 renames: old English keys → canonical PROFILE_SCHEMA keys
      const v3renames = {
        'gender': 'sex',
        'weight': 'weight_kg',
        'height': 'height_cm',
        'goal': 'primary_goal',
        'country': 'user_country',
        'city': 'user_city',
        'waist': 'waist_cm',
        'bmr': 'bmr_kcal',
        'target_weight': 'target_weight_kg',
        'wants_weight_loss': 'also_wants_weight_loss',
        'chronic_diseases': 'chronic_conditions',
        'takes_medication': 'takes_medications',
        'fasting_pattern': 'fasting_status',
        'meals_per_day': 'meal_pattern',
        'sleep_bedtime': 'sleep_time',
        'sleep_duration_mins': 'sleep_duration_hours',
        'budget': 'budget_level',
        'takes_supplements': 'currently_takes_supplements',
        'supplement_details': 'current_supplements_text',
        'past_barriers': 'motivation_barriers',
        'excluded_categories': 'excluded_meal_types',
      };
      Object.entries(v3renames).forEach(([oldKey, newKey]) => {
        if (p[oldKey] !== undefined && p[newKey] === undefined) {
          p[newKey] = p[oldKey]; delete p[oldKey]; changed = true;
        } else if (p[oldKey] !== undefined && p[newKey] !== undefined) {
          delete p[oldKey]; changed = true;
        }
      });

      // Clean junk keys
      if (p['Значение'] !== undefined) { delete p['Значение']; changed = true; }

      if (changed || !p._schema_version || p._schema_version < 3) {
        p._schema_version = 3;
        localStorage.setItem('aidiet_profile', JSON.stringify(p));
        console.log('[Health Code] Profile migrated to schema v3 (canonical keys)');
      }
    } catch (e) { console.warn('[Health Code] Migration failed:', e); }
  })();

  // ═══ GLOBAL FIX: Bilingual Profile Access ═══
  // saveField() stores English keys. But hydration code reads Russian keys.
  // Solution: getProfile() returns a MERGED view with BOTH EN and RU keys.
  // saveField() writes ONLY to raw storage (English keys) via _getRawProfile().

  window.AIDiet._getRawProfile = function() {
    return JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
  };

  window.AIDiet.getProfile = function() {
    const raw = window.AIDiet._getRawProfile();
    const merged = {...raw};
    Object.entries(raw).forEach(([storedKey, storedValue]) => {
      // English key → add Russian alias with reverse-translated value
      const ruKey = REVERSE_KEYS[storedKey];
      if (ruKey && merged[ruKey] === undefined) {
        merged[ruKey] = (typeof storedValue === 'string' && storedValue)
          ? window.i18n.toRuVal(storedValue)
          : storedValue;
      }
      // Russian key (legacy) → add English alias with translated value
      const enKey = DICT_KEYS[storedKey];
      if (enKey && merged[enKey] === undefined) {
        merged[enKey] = (typeof storedValue === 'string' && storedValue)
          ? window.i18n.toEnVal(storedValue)
          : storedValue;
      }
    });
    return merged;
  };

  window.AIDiet.saveField = function(key, value) {
    // GUARD: never save under empty or generic junk keys
    if (!key || key === 'Значение' || key.length < 2) return;

    // ═══ LAW: ALL KEYS MUST BE ENGLISH. NO EXCEPTIONS. ═══
    // Use the DICT_KEYS mapping from i18n.js to ensure canonical naming.
    const canonicalKey = window.i18n.toEnKey(key);
    if (canonicalKey !== key) {
      console.warn(`[Auto-Fix] saveField('${key}') → mapped to canonical '${canonicalKey}'`);
      key = canonicalKey;
    }

    // FINAL GUARD: If still has Cyrillic, it's a new unmapped key. Block it.
    if (/[А-Яа-яЁё]/.test(key)) {
      console.error(`[CRITICAL VIOLATION] saveField('${key}') — Unknown Cyrillic key! Add it to DICT_KEYS in i18n.js.`);
      return;
    }

    const profile = window.AIDiet._getRawProfile(); // Read RAW, not merged
    // Clean up legacy junk key if present
    if (profile['Значение'] !== undefined) delete profile['Значение'];
    profile[key] = window.i18n.toEnVal(value);

    // ═══ LC-01/LC-02: Auto-cleanup dependent data on critical field change ═══
    const cleanVal = (typeof value === 'string') ? value.toLowerCase() : value;
    if (key === 'gender' && (cleanVal === 'male' || cleanVal === 'мужской')) {
      // Male users cannot have women's health data
      delete profile['womens_health'];
      delete profile['takes_contraceptives'];
      console.log('[State] ♻️ Cleared womens_health data (gender → male)');
    }
    if (key === 'goal' && (cleanVal === 'keep_fit' || cleanVal === 'maintain_weight' || cleanVal === 'поддерживать форму')) {
      // Target weight/timeline is only for weight loss goals
      delete profile['target_weight'];
      delete profile['target_timeline_weeks'];
      console.log('[State] ♻️ Cleared weight loss targets (goal → maintain)');
    }
      const goalLower = String(value).toLowerCase();
      const isWeightLoss = goalLower.includes('снизить вес') || goalLower === 'weight_loss';
      if (!isWeightLoss) {
        // Non weight-loss goal: clear O-4 branch data
        delete profile['target_weight_kg'];
        delete profile['target_timeline_weeks'];
        delete profile['speed_priority'];
        delete profile['target_date'];
        delete profile['pace_classification'];
        delete profile['target_daily_calories'];
        delete profile['also_wants_weight_loss'];
        console.log('[State] ♻️ Cleared O-4 weight-loss data (goal ≠ weight_loss)');
      }
    }

    localStorage.setItem('aidiet_profile', JSON.stringify(profile));
    console.log(`[State] ${key} = ${value}`);
  };
  window.AIDiet.hydrateUI = function() {
    const p = window.AIDiet.getProfile();
    const currentUrl = window.location.pathname;

    console.log("[Health Code Hydrate] Запуск гидратации с профилем:", p);

    // 0. Авто-заполнение прогресс-бара по тексту "Шаг X из Y"
    const stepEl = document.querySelector('.step-counter');
    const fillEl = document.querySelector('.progress-fill');
    if (stepEl && fillEl) {
        const text = stepEl.textContent;
        const match = text.match(/(\d+)\s*из\s*(\d+)/i);
        if (match) {
            const step = parseInt(match[1]);
            const total = parseInt(match[2]);
            setTimeout(() => { fillEl.style.width = (step / total * 100) + '%'; }, 50);
        }
    }

    // 1. Восстановление инпутов
    document.querySelectorAll('input:not([type="radio"]):not([type="checkbox"]):not([data-hydrate="no"])').forEach(input => {
        let labelName = 'Значение';
        if (input.hasAttribute('data-question')) {
            labelName = input.getAttribute('data-question');
        } else {
            const parent = input.parentElement;
            if (parent && parent.classList.contains('input-wrapper') && parent.previousElementSibling && parent.previousElementSibling.tagName === 'LABEL') {
                labelName = parent.previousElementSibling.innerText.trim();
            } else if (input.previousElementSibling && (input.previousElementSibling.tagName === 'LABEL' || input.previousElementSibling.tagName === 'DIV')) {
                labelName = input.previousElementSibling.innerText.trim();
            }
        }
        
        // Исключения перезаписи для кастомных полей
        if (input.id === 'likedFoods') labelName = 'Любимые продукты';
        if (input.id === 'dislikedFoods') labelName = 'Нелюбимые продукты';
        if (input.id === 'otherConditionText') labelName = 'Свой диагноз';
        if (input.id === 'medsInput') labelName = 'Принимает лекарства';
        if (input.id === 'hormonesInput') labelName = 'Принимает гормональные (КОК)';

        if (p[labelName] !== undefined && p[labelName] !== '' && p[labelName] !== 'Нет' && p[labelName] !== 'Да (не указано)') {
            input.value = window.i18n.toRuVal(p[window.i18n.toEnKey(labelName)]);
        }
    });

    // Текстовые арены O-15
    const likedArea = document.getElementById('likedFoods');
    if (likedArea && p['Любимые продукты'] && p['Любимые продукты'] !== 'Не указано') likedArea.value = p['Любимые продукты'];
    
    const dislikedArea = document.getElementById('dislikedFoods');
    if (dislikedArea && p['Нелюбимые продукты'] && p['Нелюбимые продукты'] !== 'Не указано') dislikedArea.value = p['Нелюбимые продукты'];

    // 2. Восстановление стандартных choice-card (O-2, O-5, O-8, O-9, etc)
    // АРХИТЕКТУРНОЕ РЕШЕНИЕ: O-2 обрабатывает гидратацию самостоятельно в своём inline-скрипте.
    // Экраны O-10–O-15 управляют состоянием через _oXXuiState в inline-скриптах.
    // Если inline-скрипт уже отработал — пропускаем глобальную гидратацию choice-card.
    if (window.__inlineHydrated) {
        console.log('[Health Code Hydrate] Inline hydration already performed, skipping global choice-card restore.');
        return;
    }
    const isO2 = currentUrl.includes('o2-goal');
    
    let screenQuestionRaw = document.querySelector('.question-title, h1')?.innerText.trim();
    let screenQuestion = window.i18n.toEnKey(screenQuestionRaw);
    if (!screenQuestion) screenQuestion = document.title;
    
    // Для O-2 данные лежат под каноническим ключом 'Главная цель', 
    // для остальных — под текстом заголовка экрана
    const savedCardValuesStr = isO2 ? '' : (p[screenQuestion] || '');
    
    if (savedCardValuesStr) {
        const savedCardValues = savedCardValuesStr.split(', ');
        
        // Очищаем все active перед гидратацией
        document.querySelectorAll('.choice-card, .radio-box').forEach(card => {
            card.classList.remove('active');
        });
        
        document.querySelectorAll('.choice-card, .radio-box').forEach(card => {
            const label = card.querySelector('.choice-label, .option-title')?.innerText.trim() || card.innerText.trim();
            if (savedCardValues.includes(window.i18n.toEnVal(label))) {
                card.classList.add('active');
            }
        });
    }
    
    // 3. Восстановление O-3 Пол (canonical key: 'sex')
    if (currentUrl.includes('o3-')) {
        const savedGender = p['sex'] || p['gender'] || p['Пол'] || '';
        if (savedGender) {
            const isFemale = savedGender === 'female' || savedGender === 'Женский';
            const isMale = savedGender === 'male' || savedGender === 'Мужской';
            document.querySelectorAll('.gender-btn').forEach(btn => {
                btn.classList.remove('active');
                if (isFemale && btn.innerText.includes('Женщина')) btn.classList.add('active');
                if (isMale && btn.innerText.includes('Мужчина')) btn.classList.add('active');
            });
        }
        // Если пол не сохранён — ничего не выбрано (нет предвыбора)
    }

    // 4. Восстановление O-6 и O-7 (.check-item) - Симптомы и Состояния
    // ВАЖНО: восстанавливаем только если пользователь уже ПРОХОДИЛ этот экран (вернулся кнопкой "Назад")
    if (currentUrl.includes('o6-')) {
        const alreadyVisited = p['o6_visited'] === 'true';
        if (alreadyVisited) {
            const symptomsRaw = p['symptoms'] || p['Симптомы'] || '';
            const conditionsRaw = p['chronic_conditions'] || p['chronic_diseases'] || p['Хронические заболевания'] || '';
            const symptomsArr = symptomsRaw.split(', ').map(s => window.i18n ? window.i18n.toRuVal(s) : s);
            const conditionsArr = conditionsRaw.split(', ').map(s => window.i18n ? window.i18n.toRuVal(s) : s);
            
            // Симптомы
            document.querySelectorAll('.check-list:first-of-type .check-item').forEach(item => {
                const lbl = item.querySelector('.check-label')?.innerText.trim();
                if (symptomsArr.includes(lbl)) item.classList.add('active');
            });
            
            // Состояния
            document.querySelectorAll('#conditionsList .check-item').forEach(item => {
                const lbl = item.querySelector('.check-label')?.innerText.trim();
                if (conditionsArr.includes(lbl)) {
                    item.classList.add('active');
                    
                    // Триггеры для подменю
                    if (item.id === 'diabetesOption') document.getElementById('diabetesNested').style.display = 'block';
                    if (item.id === 'thyroidOption') document.getElementById('thyroidNested').style.display = 'block';
                    if (item.id === 'giOption') document.getElementById('giNested').style.display = 'block';
                    if (item.id === 'otherConditionItem') document.getElementById('otherConditionWrap').style.display = 'flex';
                }
            });
        } else {
            // Первый проход — убеждаемся что ничего не активно (защита от stale-данных)
            document.querySelectorAll('.check-item').forEach(i => i.classList.remove('active'));
        }
    }

    if (currentUrl.includes('o7-')) {
        const womenHealthRaw = p['womens_health'] || p['Женское здоровье'] || '';
        const womenHealth = womenHealthRaw.split(', ').map(s => window.i18n ? window.i18n.toRuVal(s) : s);
        document.querySelectorAll('.option-card').forEach(card => {
            const lbl = card.querySelector('.option-title')?.innerText.trim();
            if (womenHealth.includes(lbl)) card.classList.add('active');
        });
    }

    // 5. Восстановление фишек O-15 (.chip) и сводки O-16
    if (currentUrl.includes('o16-')) {
        // Проверка: Была ли цель изменена из-за беременности/ГВ
        const health = p['womens_health'] || p['Женское здоровье'] || '';
        const goal = p['primary_goal'] || p['Главная цель'] || p['Какая у тебя сейчас главная цель?'] || '';
        if ((health.includes('Беременность') || health.includes('Кормление грудью')) && goal.includes('Питание для кожи')) {
            // Находим спан или див с целью и вешаем бейдж
            setTimeout(() => {
                const summaryItems = document.querySelectorAll('.summary-item');
                summaryItems.forEach(item => {
                    if (item.innerText.includes('Питание для кожи')) {
                        const valNode = item.querySelector('.summary-val');
                        if (valNode && !valNode.innerHTML.includes('Скорректирован')) {
                            valNode.innerHTML += ' <br><span style="display:inline-block; margin-top:4px; font-size:10px; color:#E3342F; background:#FCE4E4; padding:2px 6px; border-radius:4px;">План скорректирован с учетом показаний</span>';
                        }
                    }
                });
            }, 100);
        }
    }

    if (currentUrl.includes('o15-')) {
        const excludedKey = p['excluded_meal_types'] || p['Исключённые категории'] || '';
        const excluded = excludedKey.split(', ');
        document.querySelectorAll('#excludeChips .chip').forEach(chip => {
            const val = chip.dataset.val;
            const text = chip.innerText.trim();
            if (val === 'none' && excludedKey === 'Нет') {
                chip.classList.add('active');
                if (typeof excludeSelected !== 'undefined') excludeSelected.add('none');
            } else if (excluded.includes(text)) {
                chip.classList.add('active');
                if (typeof excludeSelected !== 'undefined') excludeSelected.add(val);
            } else if (val === 'other' && excludedKey && excludedKey !== 'Нет') {
                const std = ['Супы', 'Каши', 'Салаты', 'Смузи или коктейли', 'Блюда из субпродуктов'];
                const custom = excluded.filter(e => !std.includes(e));
                if (custom.length > 0) {
                    chip.classList.add('active');
                    if (typeof excludeSelected !== 'undefined') excludeSelected.add('other');
                    document.getElementById('otherExcludeInputWrap').style.display = 'flex';
                    document.getElementById('otherExcludeInput').value = custom.join(', ');
                }
            }
        });
    }

    // 6. Восстановление тумблеров (.toggle-switch)
    document.querySelectorAll('.toggle-switch').forEach(toggle => {
        let shouldActive = false;
        if (toggle.id === 'weightLossToggle' && (p['also_wants_weight_loss'] === 'Да' || p['Доп. Снижение веса'] === 'Да')) shouldActive = true;
        if (toggle.id === 'medsToggle' && (p['takes_medications'] || p['Принимает лекарства']) && (p['takes_medications'] || p['Принимает лекарства']) !== 'Нет') {
            shouldActive = true;
            document.getElementById('medsInputWrap').style.display = 'flex';
        }
        if (toggle.id === 'hormonesToggle' && (p['takes_contraceptives'] || p['Принимает гормональные (КОК)']) && (p['takes_contraceptives'] || p['Принимает гормональные (КОК)']) !== 'Нет') {
            shouldActive = true;
            document.getElementById('hormonesInputWrap').style.display = 'flex';
        }
        
        if (shouldActive) toggle.classList.add('active');
    });
  };



  // REMOVED: AIDiet.generatePlan() — dead code. See api-connector.js.
  // MOVED: AIDiet.devFill() → aidiet-dev.js (dev-only module)

  // Авто-сборщик событий при загрузке страницы
  document.addEventListener('DOMContentLoaded', () => {

    // CSS moved to global.css (spin keyframe, number input cleanup)

    // 1. Определяем "тему" текущего экрана (вопрос)
    let screenQuestion = document.querySelector('.question-title, h1')?.innerText.trim();
    if (!screenQuestion) screenQuestion = document.title;

    // REMOVED: Dynamic Back button insertion (BUG-F2-21)
    // All screens now have inline HTML <button class="btn-back"> with proper routing.
    // The dynamic generation was causing DOUBLE back buttons on every screen.

    // === BUG-F2-25: Dynamic step counter ===
    (function updateStepCounter() {
      const stepEl = document.querySelector('.step-counter');
      if (!stepEl) return;
      const p = window.location.pathname;
      const prof = window.AIDiet ? window.AIDiet.getProfile() : {};
      const goal = (prof['Главная цель'] || '').toLowerCase();
      const dopLoss = prof['Доп. Снижение веса'] === 'Да';
      const sex = prof['Пол'] || '';

      // Determine which conditional screens are in path
      const hasO4 = goal.includes('снизить вес') || dopLoss;
      const hasO7 = sex === 'Женский' || sex === 'Женщина';

      // Build ordered screen list
      const screens = ['o2-goal','o3-profile'];
      if (hasO4) screens.push('o4-weight-loss');
      screens.push('o5-restrictions','o6-health-core');
      if (hasO7) screens.push('o7-health-women');
      screens.push('o8-habits','o9-sleep','o10-activity','o11-budget','o12-blood','o13-supplements','o14-motivation','o15-preferences');

      const total = screens.length;
      const current = screens.findIndex(s => p.includes(s));
      if (current >= 0) {
        stepEl.textContent = `Шаг ${current + 1} из ${total}`;
        // Update progress bar width
        const fill = document.querySelector('.progress-fill');
        if (fill) fill.style.width = `${((current + 1) / total) * 100}%`;
      }
    })();

    // BUG-F2-22: Only wipe dependent data when goal CHANGES, not on every return
    if (window.location.pathname.includes('o2-goal')) {
      const p = window.AIDiet.getProfile();
      // Store current goal for change detection on next visit
      window.__o2PreviousGoal = p['Главная цель'] || '';
    }

    // ВАЛИДАТОР O-4: УДАЛЁН (Находка №4 аудита)
    // Причина: o4-weight-loss.html содержит собственный визуальный валидатор (calculatePace)
    // с цветовыми карточками и кнопками подтверждения. Этот alert-based валидатор
    // КОНФЛИКТОВАЛ с ним — блокировал переход даже после подтверждения пользователем.
    // Глобальная блокировка кнопки «Далее» (строка ~687) использует window.paceConfirmed
    // и остаётся работать корректно.

    
    // МЕДИЦИНСКИЕ ВАЛИДАТОРЫ O-6, O-7, O-8
    // УДАЛЕНЫ (S-06, S-07, S-08): Конфликтовали с inline handlers.
    // O-6: inline handler сохраняет данные и роутит. Medical check в medical-safety.js.
    // O-7: inline handler покрывает routing + беременность/ГВ проверка.
    // O-8: валидация голодание/приёмы перенесена в inline handler.
    
    // 2. Ловим клики по карточкам с выбором (choice-card)
    const choiceCards = document.querySelectorAll('.choice-card');
    choiceCards.forEach(card => {
      card.addEventListener('click', function() {
        // Убираем active у всех (если это радио-кнопки по логике UI)
        // Но не будем ломать логику множественного выбора, если она есть
        // Просто возьмём текст
        const label = this.querySelector('.choice-label')?.innerText.trim() || this.innerText.trim();
        
        // Читаем, как UI ведет себя с active классом (много или один?)
        setTimeout(() => { 
          // если после клика этот элемент стал active, сохраняем его
          if (this.classList.contains('active')) {
            // Если на экране несколько active, собираем их в массив
            const activeCards = document.querySelectorAll('.choice-card.active');
            if (activeCards.length > 1) {
              const values = Array.from(activeCards).map(c => c.querySelector('.choice-label')?.innerText.trim() || c.innerText.trim());
              window.AIDiet.saveField(screenQuestion, values.join(', '));
            } else {
              window.AIDiet.saveField(screenQuestion, label);
            }
          } else {
            // Если его отключили в множественном выборе
            const activeCards = document.querySelectorAll('.choice-card.active');
            const values = Array.from(activeCards).map(c => c.querySelector('.choice-label')?.innerText.trim() || c.innerText.trim());
            window.AIDiet.saveField(screenQuestion, values.length ? values.join(', ') : 'Не выбрано');
          }
        }, 50); // небольшая задержка, чтобы оригинальный JS интерфейса усвоил клик
      });
    });

    // 3. Ловим ввод в текстовые/числовые поля (ТЕПЕРЬ НА КАЖДОЕ НАЖАТИЕ, мгновенное сохранение)
    const inputs = document.querySelectorAll('input:not([type="radio"]):not([type="checkbox"]):not([type="hidden"]):not([data-hydrate="no"]), textarea');
    inputs.forEach(input => {
      input.addEventListener('input', function() {
        // Skip search fields, filter fields, and unidentified inputs
        if (this.getAttribute('data-hydrate') === 'no') return;
        if (this.type === 'search') return;
        if (this.getAttribute('role') === 'search') return;

        let labelName = '';
        
        if (this.hasAttribute('data-question')) {
            labelName = this.getAttribute('data-question');
        } else {
            const parent = this.parentElement;
            if (parent && parent.classList.contains('input-wrapper') && parent.previousElementSibling && parent.previousElementSibling.tagName === 'LABEL') {
                labelName = parent.previousElementSibling.innerText.trim();
            } else if (this.previousElementSibling && (this.previousElementSibling.tagName === 'LABEL' || this.previousElementSibling.tagName === 'DIV')) {
                labelName = this.previousElementSibling.innerText.trim();
            }
        }
        
        // Кастомные ключи
        if (this.id === 'likedFoods') labelName = 'Любимые продукты';
        if (this.id === 'dislikedFoods') labelName = 'Нелюбимые продукты';
        if (this.id === 'otherConditionText') labelName = 'Свой диагноз';
        if (this.id === 'medsInput') labelName = 'Принимает лекарства';
        if (this.id === 'hormonesInput') labelName = 'Принимает гормональные (КОК)';
        
        // GUARD: Never save under empty or generic label
        if (!labelName || labelName === 'Значение') return;

        let val = this.value;
        window.AIDiet.saveField(labelName, val);
      });
      
      // Валидация вынесена обратно в blur, чтобы не прерывать пользователя пока он печатает цифры (например, "1" из "180")
      input.addEventListener('blur', function() {
        let labelName = 'Значение';
        if (this.hasAttribute('data-question')) { labelName = this.getAttribute('data-question'); } 
        else {
            const parent = this.parentElement;
            if (parent && parent.classList.contains('input-wrapper') && parent.previousElementSibling && parent.previousElementSibling.tagName === 'LABEL') {
                labelName = parent.previousElementSibling.innerText.trim();
            } else if (this.previousElementSibling && (this.previousElementSibling.tagName === 'LABEL' || this.previousElementSibling.tagName === 'DIV')) {
                labelName = this.previousElementSibling.innerText.trim();
            }
        }
        let val = this.value;
        if (labelName.toLowerCase().includes('рост') && val) {
            val = parseFloat(val);
            if (val < 100 || val > 250) { alert('Укажи реальный рост (от 100 до 250 см), иначе ИМТ будет рассчитан неверно.'); this.value = ''; return; }
        }
        if (labelName.toLowerCase().includes('вес') && val && !labelName.toLowerCase().includes('целевой')) {
            val = parseFloat(val);
            if (val < 30 || val > 300) { alert('Укажи реальный вес (от 30 до 300 кг).'); this.value = ''; return; }
        }
      });
    });
    
    // REMOVED (S-09): Empty O-16 button interceptor was dead code.

    // ГЛОБАЛЬНАЯ ВАЛИДАЦИЯ ФОРМ — ОТКЛЮЧЕНА
    // Причина: каждый экран (O-3, O-4, O-5, O-6...) имеет собственную валидацию.
    // Глобальная validateForm ломала кнопки, считая опциональные поля
    // («Другое ограничение», «Лекарства», «Обхват талии») обязательными.
    // Если нужна валидация — добавляй её в конкретный экран.
    function validateForm() { /* disabled */ }

    // Bind to input events instead of polling
    document.querySelectorAll('.input-field, .custom-input').forEach(input => {
        input.addEventListener('input', validateForm);
        input.addEventListener('change', validateForm);
    });
    // Initial validation on page load
    validateForm();

    window.AIDiet.hydrateUI();

    // ══════════════════════════════════════════════
    // iOS AutoFill KILLER (глобальный)
    // Safari автозаполняет text-inputs данными контактов/временем.
    // Стратегия: через 150ms после загрузки проверяем ВСЕ text-inputs
    // и очищаем значения, которые выглядят как время (HH:MM).
    // ══════════════════════════════════════════════
    setTimeout(() => {
      document.querySelectorAll('input[type="text"], input:not([type])').forEach(input => {
        // Добавляем anti-autofill атрибуты
        input.setAttribute('autocomplete', 'off');
        input.setAttribute('data-form-type', 'other');
        input.setAttribute('data-lpignore', 'true');

        // Если значение выглядит как время (HH:MM) и input НЕ помечен как гидратированный
        const val = input.value.trim();
        if (/^\d{1,2}:\d{2}$/.test(val) && !input.dataset.hydrated) {
          console.warn(`[Health Code] iOS AutoFill killed: "${val}" in #${input.id || input.name}`);
          input.value = '';
        }
      });
    }, 150);
  });

})();
