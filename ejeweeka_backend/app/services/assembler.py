from app.services.vitamin_router import VitaminRouter

from datetime import datetime
from app.services.archetypes import ArchetypePromptFactory

# Lazy DB session for safety table lookups
_db_session_factory = None

def _get_safety_db():
    """Lazy import to avoid circular dependency."""
    global _db_session_factory
    if _db_session_factory is None:
        try:
            from app.db import SessionLocal
            _db_session_factory = SessionLocal
        except Exception:
            return None
    try:
        return _db_session_factory()
    except Exception:
        return None


class PromptAssembler:
    """
    Универсальный и масштабируемый билдер промптов для генерации планов питания ejeweeka.
    Собирает модульный промпт на основе данных профиля, RAG-контекста и вычисленных kCal.
    """

    @staticmethod
    def build_matrix_prompt(profile, context_text: str, bmr: float, tdee: float, target_kcal: float, days: int = 7, meals_per_day: int = 4) -> str:
        """Этап 1: Генерация только названий блюд и медицинского обоснования."""
        # Layer 1: Archetype System Prompt
        system_role, archetype_code = ArchetypePromptFactory.get_system_role(
            goal=profile.goal, gender=profile.gender, age=profile.age,
            womens_health=profile.womens_health, days=days, is_matrix=True,
        )
        prompt_parts = []
        prompt_parts.append(system_role)
        # Layer 2: Personalized data injection
        prompt_parts.append(PromptAssembler._build_biometrics(profile, bmr, tdee, target_kcal))
        prompt_parts.append(PromptAssembler._build_tone_instructions(profile))
        prompt_parts.append(PromptAssembler._build_wellness_guardrails(profile, target_kcal))
        prompt_parts.append(PromptAssembler._build_geo_restrictions(profile))
        # Layer 3: Lifestyle parameters
        prompt_parts.append(PromptAssembler._build_lifestyle(profile))
        prompt_parts.append(PromptAssembler._build_log_correction_rules(profile))
        prompt_parts.append(PromptAssembler._build_rag_context(context_text))
        prompt_parts.append(PromptAssembler._build_matrix_json_schema(days, meals_per_day, profile.tier))
        # Store archetype for logging
        PromptAssembler._last_archetype_code = archetype_code
        return "\n\n".join(prompt_parts)

    @staticmethod
    def _build_tone_instructions(profile) -> str:
        import json
        import os
        tone_id = getattr(profile, 'ai_personality', 'premium')
        json_path = os.path.join(os.path.dirname(__file__), '../core/prompts/ai_personalities.json')
        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            tone_data = data['tones'].get(tone_id, data['tones']['premium'])
            system_prompt = tone_data['system_prompt']
            
            # Select specific blocks based on profile
            blocks = tone_data['blocks']
            selected_words = []
            
            # Gender & Goal logic
            gender_prefix = 'female' if profile.gender == 'female' else 'male'
            
            if profile.age and profile.age < 30:
                selected_words.extend(blocks.get(f"{gender_prefix}_under30", []))
            elif profile.age and 30 <= profile.age < 45:
                selected_words.extend(blocks.get(f"{gender_prefix}_30to50" if gender_prefix == 'male' else f"{gender_prefix}_over30", []))
            elif profile.age and profile.age >= 45:
                selected_words.extend(blocks.get(f"{gender_prefix}_over50" if gender_prefix == 'male' else f"{gender_prefix}_over45", []))
                
            if 'похудение' in profile.goal.lower():
                selected_words.extend(blocks.get(f"{gender_prefix}_weightloss", []))
            elif 'набор' in profile.goal.lower():
                selected_words.extend(blocks.get(f"{gender_prefix}_muscle", []))
            else:
                selected_words.extend(blocks.get(f"{gender_prefix}_health", []))
            
            return f"""[TONE OF VOICE & ПЕРСОНАЛИЗАЦИЯ]
ХАРАКТЕР ИИ: {system_prompt}

ИНСТРУКЦИЯ ПО ОБЩЕНИЮ:
1. Обязательно добавь в план (в поле daily_tip или в описания блюд) мотивирующие обращения, соответствующие твоему характеру.
2. Используй следующие слова/эпитеты при обращении к пользователю: {", ".join(selected_words[:10])}.
3. Приветствия: используй фразы вроде "{", ".join(blocks.get('greetings_morning', [])[:2])}".
4. Оценка прогресса: "{", ".join(blocks.get('progress_0_15', [])[:2])}".
"""
        except Exception as e:
            return f"[TONE OF VOICE] Используй уважительный, премиальный тон общения."

    @staticmethod
    def build_recipe_prompt(profile, missing_meals: list, target_kcal: float) -> str:
        """Этап 3: Генерация полных рецептов только для недостающих блюд."""
        prompt_parts = []
        prompt_parts.append(f"Ты шеф-повар и нутрициолог ejeweeka. Твоя задача сгенерировать точные рецепты, КБЖУ, ингредиенты и пошаговые инструкции ТОЛЬКО для следующих {len(missing_meals)} блюд:\n" + ", ".join(missing_meals))
        prompt_parts.append(f"Учитывай дневную калорийность ~{int(target_kcal)} ккал (раздели примерно на количество приемов пищи).")
        prompt_parts.append(PromptAssembler._build_wellness_guardrails(profile, target_kcal))
        prompt_parts.append(PromptAssembler._build_geo_restrictions(profile))
        prompt_parts.append(PromptAssembler._build_lifestyle(profile))
        prompt_parts.append(PromptAssembler._build_recipe_json_schema(missing_meals))
        return "\n\n".join(prompt_parts)

    # _last_archetype_code — set by build_matrix_prompt for response logging
    _last_archetype_code: str = 'UNKNOWN'

    @staticmethod
    def _build_geo_restrictions(profile) -> str:
        country = getattr(profile, 'country', 'RU')
        return f"""[ЛОКАЛИЗАЦИЯ И ПРОДУКТОВАЯ КОРЗИНА]
Пользователь находится в регионе: {country}.
Ты обязан использовать ТОЛЬКО ту базовую продуктовую корзину (20-40 наименований), которая является легкодоступной и недорогой в этом регионе.
Категорически ЗАПРЕЩЕНО использовать:
- Труднодоступные или дорогие локальные деликатесы.
- Гречку, творог, кефир (если регион не Россия или СНГ).
Вместо этого используй универсальные дешевые локальные аналоги (например, рис, нут, чечевица для Ближнего Востока/Азии).
Цены на рецепты должны быть адекватными для {country}.
"""

    @staticmethod
    def _build_biometrics(profile, bmr: float, tdee: float, target_kcal: float) -> str:
        return f"""[БИОМЕТРИЯ И ЭНЕРГЕТИЧЕСКИЙ БАЛАНС]
- Возраст: {profile.age} лет, Пол: {profile.gender}, Текущий вес: {profile.weight}кг, Рост: {profile.height}см.
{f"- Целевой вес: {profile.target_weight}кг (за {profile.target_timeline_weeks} нед.)" if profile.target_weight else ""}
- Базовый обмен веществ (BMR): ~{int(bmr)} ккал.
- Цель пользователя: {profile.goal}.
- ИТОГОВАЯ ЦЕЛЬ (TARGET): План должен строго укладываться в ~{int(target_kcal)} ккал в день (+/- 5%).
- ЦЕЛЬ ПО КЛЕТЧАТКЕ: Минимум {int(getattr(profile, 'target_daily_fiber', None) or (25 if profile.gender == 'female' else 30))}г клетчатки в день (WHO/AHA). Каждое блюдо должно содержать клетчатку (овощи, цельнозерновые, бобовые, фрукты)."""

    @staticmethod
    def _build_wellness_guardrails(profile, target_kcal: float) -> str:
        guardrails = f"[WELLNESS БЕЗОПАСНОСТЬ И ОГРАНИЧЕНИЯ]\n"
        
        # VLCD Logic
        if target_kcal <= 1300:
            guardrails += f"ВНИМАНИЕ (VLCD ПРОТОКОЛ): Рассчитанная калорийность экстремально низкая ({int(target_kcal)} ккал/день). " \
                          f"Чтобы избежать истощения, ТЫ ОБЯЗАН максимизировать нутритивную плотность: используй печень, рыбу, шпинат, яйца. " \
                          f"Обязательно выписывай мощную витаминную поддержку.\n"

        guardrails += f"- Заболевания: {', '.join(profile.diseases) if profile.diseases else 'Нет'}\n"
        guardrails += f"- Аллергии/Исключения: {', '.join(profile.allergies) if profile.allergies else 'Нет'}\n"
        guardrails += f"- Диетические ограничения: {', '.join(profile.effective_restrictions) if profile.effective_restrictions else 'Нет'}\n"
        guardrails += f"- Текущие симптомы: {', '.join(profile.symptoms) if profile.symptoms else 'Нет'}\n"
        guardrails += f"- Принимаемые лекарства: {profile.medications}\n"
        guardrails += f"- Принимаемые БАД: {profile.supplements}\n"
        guardrails += f"- Отношение к БАДам: {profile.supplement_openness or 'Не указано'}\n"
        
        # Женское здоровье (КРИТИЧНО для безопасности: беременность, СПКЯ, менопауза)
        wh = profile.womens_health
        if wh:
            # Поддерживаем оба формата: список и строка
            wh_str = ', '.join(wh) if isinstance(wh, list) else str(wh)
            guardrails += f"- Женское здоровье: {wh_str}\n"
            wh_lower = wh_str.lower()
            if 'беремен' in wh_lower:
                guardrails += "  ⚠️ БЕРЕМЕННОСТЬ: Запрещены сырая рыба, мягкие сыры, кофеин >200мг, алкоголь. Увеличить фолиевую кислоту, железо, кальций.\n"
            if 'спкя' in wh_lower:
                guardrails += "  ⚠️ СПКЯ: Контроль Инсулина — низкий ГИ, меньше простых углеводов и сахара.\n"
            if 'менопауз' in wh_lower:
                guardrails += "  ⚠️ МЕНОПАУЗА: Критичен кальций (до 1200мг/день) и D3. Увеличить фитоэстрогены: лён, нут, соя.\n"
        
        # Гормональные контрацептивы (влияют на метаболизм, B6, магний)
        if hasattr(profile, 'takes_contraceptives') and profile.takes_contraceptives:
            guardrails += f"- Контрацептивы/КОК: {profile.takes_contraceptives}. Увеличить B6, магний, фолиевую кислоту.\n"
        
        # Кастомный диагноз (свободный текст от пользователя)
        if hasattr(profile, 'custom_condition') and profile.custom_condition:
            guardrails += f"- Дополнительное состояние (от пользователя): {profile.custom_condition}\n"
        
        # Антропометрия (помогает AI точнее настроить план)
        if hasattr(profile, 'bmi') and profile.bmi:
            guardrails += f"- ИМТ: {profile.bmi}"
            if hasattr(profile, 'bmi_class') and profile.bmi_class:
                guardrails += f" ({profile.bmi_class})"
            guardrails += "\n"
        if hasattr(profile, 'waist') and profile.waist:
            guardrails += f"- Обхват талии: {profile.waist} см\n"
        if hasattr(profile, 'fat_distribution') and profile.fat_distribution:
            guardrails += f"- Отложение жира: {profile.fat_distribution}\n"
        if hasattr(profile, 'body_type') and profile.body_type:
            guardrails += f"- Телосложение: {profile.body_type}\n"
        
        # Анализы (для точного подбора питания)
        if hasattr(profile, 'blood_tests') and profile.blood_tests:
            guardrails += f"- Анализы: {profile.blood_tests}\n"
        
        guardrails += "\nКРИТИЧЕСКИЕ ИНСТРУКЦИИ:\n"
        guardrails += "1. КАТЕГОРИЧЕСКИ запрещено включать аллергены или продукты, противопоказанные при состояниях пользователя.\n"
        guardrails += f"2. Обязательно учитывай время приема лекарств ({profile.medications}) относительно пищи (до/после/во время).\n"
        guardrails += "3. ПРЕБИОТИКИ (ОБЯЗАТЕЛЬНО): Каждый ежедневный рацион ДОЛЖЕН содержать минимум 1-2 источника пребиотиков для питания микробиома.\n"
        
        # Drug-food interactions (P-01)
        guardrails += PromptAssembler._build_drug_interactions(profile)
        
        # Vitamin conflict rules (P-02)
        guardrails += PromptAssembler._build_vitamin_rules(profile)
        
        # Disease-specific macro limits (P-03)
        guardrails += PromptAssembler._build_disease_macro_rules(profile)
        
        # Blood test interpretation (P-04)
        guardrails += PromptAssembler._build_blood_test_context(profile)
        
        return guardrails

    @staticmethod
    def _build_log_correction_rules(profile) -> str:
        s = ""
        snacks = getattr(profile, 'extra_snacks', [])
        drinks = getattr(profile, 'beverages', [])
        
        if snacks:
            s += "\n[КОРРЕКТИРОВКА: ВНЕПЛАНОВЫЕ ПЕРЕКУСЫ]\n"
            s += "Пользователь съел вне плана:\n"
            for sn in snacks:
                s += f"  - {sn.get('name')} ({sn.get('calories', 0)} ккал)\n"
            s += "⚠️ ПРАВИЛО: Вычти эти калории из нормы при планировании. Если лимит сильно превышен — мягко адаптируй меню следующего дня (добавь больше клетчатки и легкого белка, сократи углеводы), чтобы компенсировать перебор, не вводя человека в жесткий голод.\n"
            
        if drinks:
            s += "\n[КОРРЕКТИРОВКА: НАПИТКИ И АЛКОГОЛЬ]\n"
            s += "Пользователь выпил:\n"
            has_alcohol = False
            for dr in drinks:
                abv = dr.get('abv')
                abv_str = f", алк: {abv}%" if abv else ""
                s += f"  - {dr.get('name')} ({dr.get('volume_ml', 0)} мл, {dr.get('estimated_kcal', 0)} ккал{abv_str})\n"
                if abv and abv > 0:
                    has_alcohol = True
            if has_alcohol:
                s += "⚠️ ПРАВИЛО (АЛКОГОЛЬ): Пользователь употреблял алкоголь. Обязательно добавь в план на следующий день продукты, поддерживающие печень и водно-солевой баланс (электролиты, продукты с калием, рассол, квашеную капусту, зелень). Учти пустые калории этанола при расчете энергетического баланса.\n"
        
        return s


    @staticmethod
    def _build_geo_cultural_rules(profile) -> str:
        s = ""
        country = (profile.country or '').lower()
        if not country or country == 'не указана':
            return s
            
        s += f"\n[ГЕО-КУЛЬТУРНАЯ АДАПТАЦИЯ: {profile.country.upper()}]\n"
        
        # South-East Asia
        if any(c in country for c in ['таиланд', 'вьетнам', 'индонезия', 'бали', 'малайзия']):
            s += "⚠️ ГЕО-ПАТТЕРН (ЮВА): Исключи труднодоступные продукты: гречку, кефир, творог, квашеную капусту. Замени на рис, рисовую лапшу, тофу, темпе, местные фрукты (манго, папайя) и кокосовое молоко.\n"
        
        # High Sun / Latitudes
        if any(c in country for c in ['аргентина', 'испания', 'италия', 'таиланд', 'индонезия', 'оаэ', 'израиль']):
            s += "⚠️ ГЕО-ПАТТЕРН (ВЫСОКИЙ УФ-ИНДЕКС): Страна с высоким уровнем солнца. Витамин D в виде добавок не является приоритетом (только если есть по анализам). Сделай фокус на гидратацию и электролиты.\n"
            
        # Middle East
        if any(c in country for c in ['оаэ', 'саудовская аравия', 'катар', 'кувейт', 'бахрейн']):
            s += "⚠️ ГЕО-ПАТТЕРН (БЛИЖНИЙ ВОСТОК): Используй локальные продукты: нут, чечевица, финики, баранина, хумус, тахини. Ограничь свинину по умолчанию (учитывай халяль).\n"
            
        return s

    @staticmethod
    def _build_lifestyle(profile) -> str:
        month = datetime.now().strftime('%B %Y')
        s = f"[ЛАЙФСТАЙЛ И ПРИВЫЧКИ]\n"
        s += f"- Локация: {profile.country} {profile.city}. Текущий месяц: {month}. ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО РЕГИОНА: Ты обязан оценивать реальную стоимость и доступность продуктов в обычных супермаркетах масс-маркета указанной страны. Не предлагай экзотику, если она не типична или слишком дорога для этого региона!\n"
        
        s += PromptAssembler._build_geo_cultural_rules(profile)
        
        # Жесткие правила по бюджету
        budget = (profile.budget_level or '').lower()
        if 'эконом' in budget:
            s += f"- Бюджет: Экономный. ⚠️ ЖЕСТКОЕ ПРАВИЛО: ЗАПРЕЩЕНО использовать авокадо, лосось, семгу, форель, спаржу, киноа, креветки, сибас, матчу, дорогую говядину. ИСПОЛЬЗУЙ ТОЛЬКО локальные сверхдешевые продукты масс-маркета: сезонная капуста, свекла, морковь, лук, яблоки, курица, субпродукты (печень, сердечки), дешевая белая рыба (минтай, хек, путассу), яйца, перловка, гречка, овсянка, рис.\n"
        elif 'средний' in budget:
            s += f"- Бюджет: Средний. Адаптируй ингредиенты под средний ценовой сегмент масс-маркета региона '{profile.country}' (например, форель или индейка 1-2 раза в неделю, базовая рыба, оливковое масло, сезонные овощи).\n"
        else:
            s += f"- Бюджет: Без ограничений. Можно использовать свежие морепродукты, авокадо, красную рыбу и экзотику, если они доступны в регионе '{profile.country}'.\n"
            
        restrictions_lower = ' '.join(profile.effective_restrictions or []).lower()
        allergies_lower = ' '.join(profile.allergies or []).lower()
        disliked_lower = ' '.join(profile.disliked_foods or []).lower()

        # ═══════════════════════════════════════════════════════
        # УНИВЕРСАЛЬНЫЙ ЦИКЛ ЗАПРЕТОВ (Allergens + Restrictions + Dislikes)
        # ═══════════════════════════════════════════════════════
        
        # 1. Абсолютные запреты: Аллергены
        for allergen in (profile.allergies or []):
            if allergen and allergen.strip():
                s += f"- ⚠️ АБСОЛЮТНЫЙ ЗАПРЕТ (АЛЛЕРГИЯ): Пользователь указал аллергию «{allergen}». КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО включать {allergen} и любые производные продукты в план питания. Замени на безопасные альтернативы.\n"

        # 2. Абсолютные запреты: Диетические ограничения
        for restriction in (profile.effective_restrictions or []):
            if restriction and restriction.strip():
                s += f"- ⚠️ АБСОЛЮТНЫЙ ЗАПРЕТ (ОГРАНИЧЕНИЕ): Пользователь соблюдает «{restriction}». ЗАПРЕЩЕНО нарушать это ограничение в любом приёме пищи, перекусе или напитке.\n"

        # 3. Мягкие запреты: Нелюбимые продукты (исключить, но не аллергия)
        for disliked in (profile.disliked_foods or []):
            if disliked and disliked.strip():
                s += f"- ЗАПРЕТ (ВКУС): Пользователь не любит «{disliked}». ИСКЛЮЧИ этот продукт из плана полностью.\n"

        # ═══════════════════════════════════════════════════════
        # СПЕЦИАЛИЗИРОВАННЫЕ ГАРДЫ (поверх универсального цикла)
        # ═══════════════════════════════════════════════════════
        
        # Глютен: если НЕТ аллергии — не предлагай безглютеновые спец.продукты
        if 'глютен' not in restrictions_lower and 'глютен' not in allergies_lower and 'gluten' not in restrictions_lower and 'gluten_free' not in restrictions_lower:
            s += f"- ПРАВИЛО (ГЛЮТЕН): У пользователя НЕТ аллергии на глютен. НЕ ПРЕДЛАГАЙ безглютеновый хлеб или другие спец. продукты, используй обычные (цельнозерновой хлеб, макароны из твердых сортов).\n"
            
        # Молочка: полный запрет включая безлактозные
        if 'молоч' in restrictions_lower or 'молоч' in allergies_lower or 'молоч' in disliked_lower or 'dairy' in restrictions_lower or 'dairy' in allergies_lower or 'no_dairy' in restrictions_lower or 'лактоз' in restrictions_lower or 'лактоз' in allergies_lower or 'веган' in restrictions_lower or 'vegan' in restrictions_lower:
            s += f"- ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО (БЕЗ МОЛОЧКИ): КАТЕГОРИЧЕСКИ ЗАПРЕЩАЕТСЯ предлагать любые молочные продукты, ДАЖЕ БЕЗЛАКТОЗНЫЕ (запрещены безлактозный кефир, сыр, творог, молоко). Используй исключительно растительные альтернативы (миндальное, кокосовое, овсяное молоко) или полностью исключай этот тип еды.\n"

        # Веганство: расширенный запрет всего животного
        if 'веган' in restrictions_lower or 'vegan' in restrictions_lower:
            s += f"- ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО (ВЕГАНСТВО): Запрещены ВСЕ продукты животного происхождения: мясо, птица, рыба, морепродукты, яйца, молоко, сыр, творог, кефир, сливочное масло, мёд, желатин. Только растительные продукты.\n"

        # Халяль: запрет свинины, алкоголя, желатина
        if 'халяль' in restrictions_lower or 'halal' in restrictions_lower:
            s += f"- ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО (ХАЛЯЛЬ): Запрещены: свинина и любые свиные производные (бекон, сало, колбаса), алкоголь (в том числе в маринадах и соусах — вино, пиво, коньяк), желатин свиного происхождения. Используй говядину, баранину, курицу, рыбу.\n"

        # Кошерное: базовые правила кашрута
        if 'кошер' in restrictions_lower or 'kosher' in restrictions_lower:
            s += f"- ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО (КАШРУТ): Запрещены: свинина, морепродукты без чешуи (креветки, кальмары, мидии), смешивание мяса и молочных продуктов в одном приёме пищи.\n"

        # Пескетарианство
        if 'пескетариан' in restrictions_lower or 'pescatarian' in restrictions_lower:
            s += f"- ПРАВИЛО (ПЕСКЕТАРИАНСТВО): Запрещены: мясо и птица (курица, говядина, свинина, индейка). Разрешены: рыба, морепродукты, яйца, молочные продукты.\n"

        # Без красного мяса
        if 'красн' in restrictions_lower or 'no_red_meat' in restrictions_lower:
            s += f"- ПРАВИЛО (БЕЗ КРАСНОГО МЯСА): Запрещены: говядина, свинина, баранина, телятина. Разрешены: курица, индейка, рыба, морепродукты.\n"
            
        # Cross-Utilization (Оптимизация корзины)
        s += "- ОПТИМИЗАЦИЯ КОРЗИНЫ (CROSS-UTILIZATION): Продуктовая корзина не должна превышать 15 уникальных базовых позиций (не считая специй). Ингредиенты должны пересекаться! Нельзя назначать 200г курицы на один день, а потом про нее забыть. Если куплена упаковка курицы/рыбы/крупы/овощей — она должна использоваться в 2-3 разных блюдах в течение недели для минимизации остатков.\n"
        
        shop_freq = (getattr(profile, 'shopping_frequency', None) or '').lower()
        if shop_freq == 'weekly' or shop_freq == 'раз в неделю':
            s += "- ЧАСТОТА ПОКУПОК: Раз в неделю. Избегай скоропортящихся нежных ягод, салатных листьев к концу недели. Заменяй их на корнеплоды, капусту, замороженные овощи/ягоды и долгохранящиеся продукты.\n"
            
        cook_style = (getattr(profile, 'cooking_style', None) or '').lower()
        if 'batch_weekly' in cook_style or 'раз в неделю (заготовки)' in cook_style:
            s += "- СТИЛЬ ГОТОВКИ: Заготовки раз в неделю (Batch prep). Предлагай рецепты, которые идеально хранятся в холодильнике до 5 дней или подлежат заморозке (рагу, густые супы, запеканки, котлеты, тушеное мясо). Строго исключи блюда, теряющие текстуру при разогреве.\n"
        
        s += f"- Время на готовку: {profile.cooking_time}.\n"
        if profile.fasting_type == 'daily':
            s += f"- Расписание приемов пищи: ИНТЕРВАЛЬНОЕ ГОЛОДАНИЕ (Ежедневное).\n"
            s += f"  * Формат: {profile.daily_format}\n"
            s += f"  * Окно питания: с {profile.daily_start} до {profile.daily_window_end}.\n"
            s += f"  * ⚠️ ЖЕСТКОЕ ПРАВИЛО: Игнорируй базовый паттерн приемов пищи. Генерируй СТРОГО {profile.daily_meals} приемов пищи ВНУТРИ пищевого окна. Никакой еды вне пищевого окна.\n"
            s += f"  * ⚠️ ЭЛЕКТРОЛИТЫ: Добавь обязательный прием электролитов (натрий, калий, магний) в часы голодания или с первым приемом пищи для профилактики метаболического стресса.\n"
        elif profile.fasting_type == 'periodic':
            s += f"- Расписание приемов пищи: ПЕРИОДИЧЕСКОЕ ГОЛОДАНИЕ.\n"
            s += f"  * Базовый режим в обычные дни: {profile.meal_pattern}\n"
            s += f"  * Формат голодания: {profile.periodic_format} (Частота: {profile.periodic_freq})\n"
            s += f"  * Дни начала голодания (индексы Пн=0..Вс=6): {profile.periodic_days}. Время начала: {profile.periodic_start}.\n"
            s += f"  * ⚠️ ЖЕСТКОЕ ПРАВИЛО: В дни полного голодания рацион должен быть пустым (или только вода/чай). Учитывай время старта и окончания.\n"
            s += f"  * ⚠️ ЭЛЕКТРОЛИТЫ: В дни голодания обязательно назначай минеральную воду с высоким содержанием магния и натрия.\n"
        else:
            s += f"- Расписание приемов пищи: {profile.meal_pattern}.\n"
        # T-01: Muscle gain without training guard
        if profile.fasting_type == 'daily':
            s += f"- ⚠️ ПРАВИЛО ДЛЯ ТРЕНИРОВОК (Интервальное голодание): Избегай высокоинтенсивных тренировок (HIIT) глубоко в голодном окне. Рекомендуй легкое кардио до первого приема пищи ({profile.daily_start}), а силовые — внутри пищевого окна.\n"
        elif profile.fasting_type == 'periodic':
            s += f"- ⚠️ ПРАВИЛО ДЛЯ ТРЕНИРОВОК (Периодическое голодание): В дни полного голодания ставь ТОЛЬКО восстановительные практики (йога, растяжка, легкая ходьба). Тяжелые силовые тренировки планируй ТОЛЬКО на дни полного питания.\n"

        training_str = profile.training_schedule or ''
        goal_str = profile.goal or ''
        activity_types = ', '.join(getattr(profile, 'activity_types', []))
        
        if ('набрать' in goal_str.lower() or 'масс' in goal_str.lower()) and ('без' in training_str.lower() or 'не готов' in training_str.lower() or training_str == ''):
            s += f"- Тренировки: {training_str}. ⚠️ ВНИМАНИЕ: Пользователь хочет набрать массу, но НЕ тренируется. Без силовых нагрузок профицит калорий приведет к набору жира, а не мышц. Сосредоточься на поддержании текущего веса с повышенным белком (1.6-2г/кг), НЕ давай калорийный профицит.\n"
        elif 'без' not in training_str.lower() and training_str != '':
            s += f"- Тренировки: {training_str}. Виды активности: {activity_types}.\n"
            s += f"  * ⚠️ ДИНАМИЧЕСКИЙ КБЖУ: У пользователя есть тренировки. ТЫ ОБЯЗАН распределить калорийность не равномерно на 7 дней, а ДИНАМИЧЕСКИ. В дни тренировок обеспечь профицит +15-20% калорий, закрой 'углеводное окно' после тренировки и дай повышенную порцию белка (от 1.8г/кг). В дни отдыха сделай план более дефицитным и низкоуглеводным.\n"
            if 'силов' in activity_types.lower() or 'тренажер' in activity_types.lower():
                s += f"  * ⚠️ СИЛОВЫЕ ТРЕНИРОВКИ: Учитывай распределение макросов для роста мышц. Белок строго не ниже 1.6г/кг в любой день.\n"
        else:
            s += f"- Тренировки: Нет.\n"
        s += f"- График сна: {profile.sleep_schedule}.\n"
        s += f"- Любимые продукты (включай чаще): {', '.join(profile.liked_foods) if profile.liked_foods else 'Нет'}\n"
        s += f"- Нелюбимые продукты (ИСКЛЮЧИТЬ): {', '.join(profile.disliked_foods) if profile.disliked_foods else 'Нет'}\n"
        s += f"- Диетические течения (Ограничить): {', '.join(profile.excluded_meal_types) if profile.excluded_meal_types else 'Нет'}\n"
        if profile.motivation_barriers:
            s += f"- Барьеры прошлого опыта: {', '.join(profile.motivation_barriers)}. Учитывай эти барьеры при составлении плана — делай его реалистичным и не перегруженным.\n"
        
        s += f"\n⚠️ ПРАВИЛО ПРАКТИЧНЫХ ГРАММОВОК:\n"
        s += f"Никогда не пиши '200г курицы' или '13.5г укропа'. Используй естественные магазинные меры там, где это имеет смысл. Например: 'половина упаковки (200г)', '1 среднее яблоко', '1 пучок укропа', '2 яйца'. Граммовки оставляй для точности в ключе 'amount'.\n"
        return s

    # ═══════════════════════════════════════════════════════
    # P-01: Drug-Food Interaction Matrix
    # ═══════════════════════════════════════════════════════
    DRUG_FOOD_RULES = {
        'варфарин': 'ЗАПРЕЩЕНЫ продукты с высоким витамином K: шпинат, капуста, брокколи, петрушка, руккола. Стабильное потребление зелёных овощей КАЖДЫЙ ДЕНЬ (не скачки).',
        'метформин': 'Обеспечь продукты богатые B12 (печень, рыба, яйца). ИСКЛЮЧИ алкоголь полностью.',
        'л-тироксин': 'Завтрак БЕЗ молочных продуктов и кальция. L-тироксин принимают за 30-60мин до еды НАТОЩАК. Кофе — минимум через 30мин после таблетки.',
        'тироксин': 'Завтрак БЕЗ молочных продуктов и кальция. L-тироксин принимают за 30-60мин до еды НАТОЩАК.',
        'статин': 'ИСКЛЮЧИ грейпфрут и помело (блокируют метаболизм статинов → токсичность).',
        'аторвастатин': 'ИСКЛЮЧИ грейпфрут и помело.',
        'симвастатин': 'ИСКЛЮЧИ грейпфрут и помело.',
        'эналаприл': 'Ограничь продукты с высоким калием: бананы, картофель, курага, шпинат. Риск гиперкалиемии.',
        'лизиноприл': 'Ограничь продукты с высоким калием: бананы, картофель, курага. Риск гиперкалиемии.',
        'литий': 'Стабильное потребление соли и жидкости. Резкие изменения водного баланса опасны.',
        'ингибитор мао': 'ЗАПРЕЩЕНЫ тирамин-содержащие: выдержанные сыры, копчёности, квашеная капуста, соевый соус, красное вино.',
    }

    @staticmethod
    def _build_drug_interactions(profile) -> str:
        meds = (profile.medications or '').lower()
        if not meds or meds == 'нет':
            return ''
        rules = []
        # Try DB first
        db = _get_safety_db()
        if db:
            try:
                from app.models.safety_tables import DrugFoodInteraction
                db_rules = db.query(DrugFoodInteraction).all()
                if db_rules:
                    for r in db_rules:
                        if r.drug_keyword.lower() in meds:
                            rules.append(f"  ⚠️ {r.drug_name.upper()}: {r.rule_text}")
                    db.close()
                    if rules:
                        return "\n[ЛЕКАРСТВЕННЫЕ ВЗАИМОДЕЙСТВИЯ С ПИЩЕЙ (из БД)]\n" + "\n".join(rules) + "\n"
                    return ''
            except Exception:
                pass
            finally:
                try: db.close()
                except: pass
        # Fallback to hardcoded dict
        for drug, rule in PromptAssembler.DRUG_FOOD_RULES.items():
            if drug in meds:
                rules.append(f"  ⚠️ {drug.upper()}: {rule}")
        if not rules:
            return ''
        return "\n[ЛЕКАРСТВЕННЫЕ ВЗАИМОДЕЙСТВИЯ С ПИЩЕЙ]\n" + "\n".join(rules) + "\n"

    # ═══════════════════════════════════════════════════════
    # P-02: Vitamin / Supplement Conflict Rules
    # ═══════════════════════════════════════════════════════
    @staticmethod
    def _build_vitamin_rules(profile) -> str:
        rules = "\n[ПРАВИЛА НАЗНАЧЕНИЯ ВИТАМИНОВ И БАДОВ]\n"
        
        # Инъекция динамических гео- и диетических правил
        country = getattr(profile, 'country', 'RU')
        restrictions = getattr(profile, 'restrictions', []) or []
        rules += VitaminRouter.generate_recommendation_text(country, restrictions) + "\n\n"
        
        rules += "- Жирорастворимые витамины (D, Омега-3) и добавки, требующие приема с пищей, ЗАПРЕЩЕНО ставить на время голодного окна.\n"
        if profile.fasting_type == 'daily':
            rules += f"- У пользователя ИНТЕРВАЛЬНОЕ ГОЛОДАНИЕ. Сдвигай утренние БАДы на {profile.daily_start} (первый прием пищи), а вечерние — до {profile.daily_window_end}.\n"
        elif profile.fasting_type == 'periodic':
            rules += "- У пользователя ПЕРИОДИЧЕСКОЕ ГОЛОДАНИЕ. В дни полного голодания отменяй или переноси прием БАДов, раздражающих пустой желудок (например, цинк, железо).\n"
        
        # Try DB-driven vitamin interaction rules
        db_rules_used = False
        db = _get_safety_db()
        if db:
            try:
                from app.models.safety_tables import VitaminInteraction
                interactions = db.query(VitaminInteraction).all()
                if interactions:
                    db_rules_used = True
                    for vi in interactions:
                        prefix = '⚠️' if vi.severity == 'critical' else '→'
                        if vi.interaction_type == 'conflict':
                            rules += f"- {prefix} КОНФЛИКТ: {vi.substance_a} + {vi.substance_b} — {vi.rule_text}\n"
                        elif vi.interaction_type == 'synergy':
                            rules += f"- ✅ СИНЕРГИЯ: {vi.substance_a} + {vi.substance_b} — {vi.rule_text}\n"
                        elif vi.interaction_type == 'timing':
                            rules += f"- ⏰ ТАЙМИНГ: {vi.substance_a} — {vi.rule_text}\n"
            except Exception:
                pass
            finally:
                try: db.close()
                except: pass
        
        # Fallback to hardcoded rules if DB empty
        if not db_rules_used:
            rules += "- Кальций и Железо — НИКОГДА в один приём пищи (Ca блокирует усвоение Fe). Разнести на 4+ часа.\n"
            rules += "- Цинк и Медь — антагонисты. Разнести на 2+ часа.\n"
            rules += "- Витамин D — ТОЛЬКО с жирной пищей (жирорастворимый).\n"
            rules += "- Витамин C + B12 — C разрушает B12. Разнести по приёмам.\n"
            rules += "- Магний — на ночь (расслабляет мышцы, улучшает сон).\n"
        
        # Allergen-safe supplements
        allergies_lower = ' '.join([a.lower() for a in (profile.allergies or [])])
        if 'орех' in allergies_lower or 'арахис' in allergies_lower:
            rules += "- ⚠️ АЛЛЕРГИЯ НА ОРЕХИ: ЗАПРЕЩЕНО рекомендовать Омега-3 из орехового/арахисового масла. Используй рыбий жир или масло водорослей.\n"
        if 'рыб' in allergies_lower or 'морепродук' in allergies_lower:
            rules += "- ⚠️ АЛЛЕРГИЯ НА РЫБУ: Омега-3 ТОЛЬКО из масла водорослей (algae oil), не из рыбьего жира.\n"
        if 'молоч' in allergies_lower or 'лактоз' in allergies_lower:
            rules += "- ⚠️ НЕПЕРЕНОСИМОСТЬ ЛАКТОЗЫ: Кальций из брокколи, кунжута, тофу. Не из молочных.\n"
        
        return rules

    # ═══════════════════════════════════════════════════════
    # P-03: Disease-Specific Macro Limits
    # ═══════════════════════════════════════════════════════
    @staticmethod
    def _build_disease_macro_rules(profile) -> str:
        diseases_lower = ' '.join([d.lower() for d in (profile.diseases or [])])
        if not diseases_lower:
            return ''
        rules = []
        if any(k in diseases_lower for k in ['почк', 'хпн', 'нефрит', 'почечн']):
            rules.append(f"⚠️ ЗАБОЛЕВАНИЕ ПОЧЕК: Белок строго ≤0.8г/кг массы тела ({int(profile.weight * 0.8)}г/день макс). ИСКЛЮЧИ красное мясо, ограничь фосфор и калий.")
        if 'подагр' in diseases_lower:
            rules.append("⚠️ ПОДАГРА: ИСКЛЮЧИ: красное мясо, субпродукты (печень, почки), морепродукты (мидии, креветки), пиво, бобовые. Белок брать СТРОГО из молочных продуктов, яиц и птицы. Если у пользователя возраст 45+ (саркопения), обеспечь 1.2-1.5 г/кг белка БЕЗ использования мяса.")
        if any(k in diseases_lower for k in ['диабет', 'диабет 2', 'преддиабет']):
            rules.append("⚠️ ДИАБЕТ: Углеводы с низким ГИ (<55). Исключи сахар, белый хлеб, сладкие напитки. Клетчатка ≥25г/день.")
        if any(k in diseases_lower for k in ['крон', 'колит', 'язвенн']):
            rules.append("⚠️ БОЛЕЗНЬ КРОНА/КОЛИТ: ИСКЛЮЧИ грубую клетчатку (сырые овощи, отруби), жареное, острое, молочные при непереносимости. Предпочтительно варёное, тушёное.")
        if 'гипертон' in diseases_lower:
            rules.append("⚠️ ГИПЕРТОНИЯ: Соль ≤5г/день. ИСКЛЮЧИ: соленья, копчёности, консервы, колбасы.")
        if not rules:
            return ''
        return "\n[ОГРАНИЧЕНИЯ ПО ЗАБОЛЕВАНИЯМ]\n" + "\n".join(rules) + "\n"

    # ═══════════════════════════════════════════════════════
    # P-04: Blood Test Interpretation
    # ═══════════════════════════════════════════════════════
    BLOOD_NORMS = {
        'vitamin_d': {'label': 'Витамин D', 'unit': 'нг/мл', 'critical_low': 10, 'low': 20, 'normal': 30, 'high': 80},
        'glucose': {'label': 'Глюкоза', 'unit': 'ммоль/л', 'low': 3.3, 'normal': 5.6, 'prediabetes': 6.1, 'diabetes': 7.0},
        'hemoglobin': {'label': 'Гемоглобин', 'unit': 'г/л', 'critical_low': 70, 'low_f': 120, 'low_m': 130, 'high': 170},
        'ferritin': {'label': 'Ферритин', 'unit': 'мкг/л', 'critical_low': 10, 'low': 30, 'normal': 100},
        'b12': {'label': 'Витамин B12', 'unit': 'пг/мл', 'low': 200, 'normal': 300},
        'cholesterol': {'label': 'Холестерин', 'unit': 'ммоль/л', 'normal': 5.2, 'high': 6.2},
    }

    @staticmethod
    def _build_blood_test_context(profile) -> str:
        if not hasattr(profile, 'blood_tests') or not profile.blood_tests:
            return ''
        import json
        try:
            tests = json.loads(profile.blood_tests) if isinstance(profile.blood_tests, str) else profile.blood_tests
        except (json.JSONDecodeError, TypeError):
            return f"- Анализы (сырые данные): {profile.blood_tests}\n"
        
        if not isinstance(tests, dict) or not tests:
            return ''
        
        interpretations = []
        for key, value in tests.items():
            norm = PromptAssembler.BLOOD_NORMS.get(key)
            if not norm:
                interpretations.append(f"  - {key}: {value}")
                continue
            try:
                v = float(value)
            except (ValueError, TypeError):
                interpretations.append(f"  - {norm['label']}: {value} {norm['unit']}")
                continue
            
            status = ''
            if key == 'vitamin_d':
                if v < norm['critical_low']:
                    status = 'Уровень ниже оптимума — поддержать D3'
                elif v < norm['low']:
                    status = 'Уровень ниже оптимума — добавить жирную рыбу'
                else:
                    status = 'Оптимально'
            elif key == 'glucose':
                if v >= norm['diabetes']:
                    status = 'Высокий уровень — фокус на низкий гликемический индекс, без простых углеводов'
                elif v >= norm['prediabetes']:
                    status = 'Повышенный уровень — контроль углеводов'
                else:
                    status = 'Оптимально'
            elif key == 'ferritin':
                if v < norm['critical_low']:
                    status = 'Уровень ниже оптимума — фокус на продукты с железом'
                elif v < norm['low']:
                    status = 'Уровень ниже оптимума — добавить железосодержащие продукты'
                else:
                    status = 'Оптимально'
            
            interpretations.append(f"  - {norm['label']}: {v} {norm['unit']} → {status}")
        
        if not interpretations:
            return ''
        return "\n[РЕЗУЛЬТАТЫ БИОМАРКЕРОВ]\n" + "\n".join(interpretations) + "\n"

    @staticmethod
    def _build_rag_context(context_text: str) -> str:
        if not context_text or "Специфических медицинских рекомендаций не найдено" in context_text:
            return ""
        return f"[ЭКСПЕРТНЫЕ НУТРИЦИОЛОГИЧЕСКИЕ РЕКОМЕНДАЦИИ ИЗ RAG БАЗЫ ejeweeka]\n{context_text}\nУчитывай эти рекомендации при составлении меню."

    @staticmethod
    def _build_matrix_json_schema(days: int, meals_per_day: int = 4, tier: str = "T1") -> str:
        day_keys = ", ".join([f'"day_{i}"' for i in range(1, days + 1)])
        meal_types = '"Завтрак", "Обед", "Ужин"' if meals_per_day <= 3 else '"Завтрак", "Обед", "Перекус", "Ужин"'
        
        tier_lower = tier.lower()
        if 't3' in tier_lower or 'gold' in tier_lower or 'family_gold' in tier_lower:
            variant_count = 3
        elif 't2' in tier_lower or 'black' in tier_lower:
            variant_count = 2
        else:
            variant_count = 1

        variant_instruction = ""
        if variant_count > 1:
            variant_instruction = f"""
ВАЖНОЕ ПРАВИЛО МУЛЬТИ-ВАРИАНТНОСТИ:
У пользователя премиум-статус ({tier}). Для КАЖДОГО типа приема пищи (например, Завтрак) ты ДОЛЖЕН сгенерировать ровно {variant_count} альтернативных варианта.
Каждый вариант должен быть отдельным объектом в массиве `meals` с ОДИНАКОВЫМ значением поля `meal` (например, {variant_count} объекта с `"meal": "Завтрак"` подряд).
ОБЯЗАТЕЛЬНО добавь поле `variant_name`, описывающее суть альтернативы (например, "Классика", "Больше белка", "Бюджетно", "Быстро").
"""
        else:
            variant_instruction = """
Для каждого типа приема пищи сгенерируй ровно 1 вариант.
Добавь поле `"variant_name": "Основной"`.
"""

        return f"""[СТРОГИЙ ФОРМАТ ОТВЕТА (JSON)]
Ты должен вернуть ТОЛЬКО валидный JSON, без маркдауна, без комментариев.
Структура должна содержать ключи дней с массивами приемов пищи: {day_keys}.
Каждый день содержит приемы пищи: {meal_types}.
{variant_instruction}

ОБЯЗАТЕЛЬНЫЕ ПОЛЯ для каждого блюда в массиве meals:
- "meal": тип приема (Завтрак/Обед/Перекус/Ужин)
- "variant_name": название варианта (например, "Классика", "Больше белка")
- "name": название блюда на русском
- "wellness_rationale": краткое обоснование выбора блюда для ЭТОГО пользователя (1 предложение)

Шаблон ответа:
{{
  "day_1": {{
    "meals": [
      {{
        "meal": "Завтрак",
        "variant_name": "Основной",
        "name": "Яичница со шпинатом",
        "wellness_rationale": "Шпинат богат железом, что отлично подходит для твоей диеты"
      }}
    ]
  }}
}}"""

    @staticmethod
    def _build_recipe_json_schema(missing_meals: list) -> str:
        return f"""[СТРОГИЙ ФОРМАТ ОТВЕТА (JSON)]
Ты должен вернуть ТОЛЬКО валидный JSON, без маркдауна, без комментариев.
Верни объект, где ключами являются точные названия блюд, а значениями - их полные рецепты.

ОБЯЗАТЕЛЬНЫЕ ПОЛЯ для каждого блюда:
- "calories": общая калорийность порции (число, ккал)
- "proteins": белки (число, г)
- "fats": жиры (число, г)
- "carbs": углеводы (число, г)
- "fiber": клетчатка (число, г)
- "has_probiotics": содержит ли блюдо ферментированные/пробиотические продукты (true/false). Пробиотические продукты: кефир, йогурт, квашеная капуста, кимчи, мисо, темпе, комбуча, натто.
- "prep_time_min": время приготовления (число, минут)
- "ingredients": массив ингредиентов [{{"name": "...", "amount": число, "unit": "г/мл/шт"}}]
- "steps": массив шагов приготовления (строки)

Шаблон ответа:
{{
  "Яичница со шпинатом": {{
    "calories": 320,
    "proteins": 22,
    "fats": 18,
    "carbs": 12,
    "fiber": 4,
    "prep_time_min": 10,
    "ingredients": [
      {{"name": "Яйцо", "amount": 2, "unit": "шт"}},
      {{"name": "Шпинат", "amount": 50, "unit": "г"}}
    ],
    "steps": ["Шаг 1", "Шаг 2"]
  }}
}}"""
