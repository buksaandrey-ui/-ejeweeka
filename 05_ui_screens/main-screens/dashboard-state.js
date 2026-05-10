function calculateTargets(profile) {
    if (!profile) return { cals: 1500, p: 100, f: 60, c: 150, fiber: 30 };
    
    // D9: Сначала пробуем target_kcal из ответа плана (если план уже сгенерирован)
    try {
        const plan = JSON.parse(localStorage.getItem('aidiet_meal_plan') || '{}');
        if (plan.target_kcal && plan.target_kcal > 800) {
            const cals = Math.round(plan.target_kcal);
            return { cals, p: Math.round((cals * 0.30) / 4), f: Math.round((cals * 0.30) / 9), c: Math.round((cals * 0.40) / 4), fiber: 30 };
        }
    } catch (e) { /* ignore */ }

    // D9b: Пробуем использовать уже рассчитанный при онбординге target_daily_calories
    const savedTDEE = parseFloat(profile['target_daily_calories']);
    if (savedTDEE && savedTDEE > 800) {
        const cals = Math.round(savedTDEE);
        return { cals, p: Math.round((cals * 0.30) / 4), f: Math.round((cals * 0.30) / 9), c: Math.round((cals * 0.40) / 4), fiber: 30 };
    }

    // Fallback: рассчитываем сами (canonical keys from state-contract.js v3)
    const weight = parseFloat(profile['weight_kg']) || 70;
    const height = parseFloat(profile['height_cm']) || 170;
    const age = parseInt(profile['age']) || 30;
    const sexRaw = profile['sex'] || '';
    const gender = (sexRaw === 'female') ? 'female' : 'male';
    
    let bmr = 0;
    let floor_calories = 1000;
    if (gender === 'female') {
        bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    } else {
        bmr = 10 * weight + 6.25 * height - 5 * age + 5;
        floor_calories = 1300;
    }
    
    let baseline_multiplier = parseFloat(profile['activity_multiplier']) || 1.375;
    let tdee = bmr * baseline_multiplier;
    if (tdee < floor_calories) tdee = floor_calories;

    const goal = profile['primary_goal'] || '';
    if (goal.includes('weight_loss') || goal.includes('Снизить вес')) tdee -= 400;
    if (goal.includes('muscle_gain') || goal.includes('Набрать')) tdee += 300;
    
    const cals = Math.round(tdee);
    return {
        cals,
        p: Math.round((cals * 0.30) / 4),
        f: Math.round((cals * 0.30) / 9),
        c: Math.round((cals * 0.40) / 4),
        fiber: 30
    };
}

/**
 * Умные медицинские напоминания (Vitamin Alerts)
 */
function renderVitaminAlerts(profile) {
    const alertsContainer = document.querySelector('.vitamin-alerts');
    if (!alertsContainer) return;
    
    alertsContainer.innerHTML = ''; // Очистка старых хардкодов
    
    let meds = [];
    const conditions = profile?.['Хронические заболевания'] || '';
    const hasDisease = conditions && !conditions.includes('Нет');
    
    if (hasDisease) {
        if (conditions.includes('Диабет')) {
            meds.push({ icon: 'ph-first-aid', color: '#EF4444', bg: '#FEF2F2', text: 'Метформин / Замер глюкозы — через 30 мин' });
        }
        if (conditions.includes('Гипертония') || conditions.includes('давлени')) {
            meds.push({ icon: 'ph-heartbeat', color: '#EF4444', bg: '#FEF2F2', text: 'Контроль АД / Таблетка — Пора!' });
        }
    }
    
    // Базовые витамины для всех
    meds.push({ icon: 'ph-pill', color: 'var(--color-primary)', bg: '#FFF7ED', text: 'Витамин D3 (5000 ME) — Утром' });
    meds.push({ icon: 'ph-pill', color: 'var(--color-primary)', bg: '#FFF7ED', text: 'Омега-3 — В обед' });
    
    meds.forEach(m => {
        const el = document.createElement('div');
        el.className = 'vitamin-alert';
        el.innerHTML = `
            <div class="vitamin-alert-icon" style="background-color: ${m.bg}; color: ${m.color};"><i class="ph ${m.icon}"></i></div>
            <span>${m.text}</span>
        `;
        alertsContainer.appendChild(el);
    });
}

/**
 * Персонализированное приветствие
 */
function renderGreeting(profile) {
    const greeting1 = document.getElementById('greetingLine1');
    const greeting2 = document.getElementById('greetingLine2');
    if (!greeting1 || !greeting2) return;

    if (window.getDynamicGreeting) {
        // Добавляем искусственный прогресс для тестов, если его нет
        if (typeof profile.progress_percent === 'undefined') {
            profile.progress_percent = 10; // тестовое значение
        }
        
        const g = window.getDynamicGreeting(profile);
        greeting1.innerText = g.line1;
        greeting2.innerText = g.line2;
        
        // Сохраняем выданный эпитет, чтобы в следующий раз был другой
        if (g._newEpithet) {
            profile.last_greeting_epithet = g._newEpithet;
            if (window.AIDiet && window.AIDiet.saveProfile) {
                // Избегаем бесконечных циклов
                localStorage.setItem('aidiet_profile', JSON.stringify(profile));
            }
        }
    } else {
        // Фолбек, если движок не загрузился
        const hour = new Date().getHours();
        let timeGreeting = "Доброе утро";
        if (hour >= 12 && hour < 18) timeGreeting = "Добрый день";
        else if (hour >= 18) timeGreeting = "Добрый вечер";

        const name = profile?.['first_name'] || profile?.['Имя'] || profile?.name || 'Пользователь';
        greeting1.innerText = `${timeGreeting},`;
        greeting2.innerText = name + ' 👋';
    }
}


/**
 * D4: Динамический Week Switcher — текущая неделя
 */
function renderWeekSwitcher() {
    const dateLabel = document.getElementById('dateLabel');
    const weekRow = document.getElementById('weekRow');
    if (!dateLabel || !weekRow) return;

    const now = new Date();
    const today = now.getDate();
    const currentDayOfWeek = now.getDay(); // 0=Sun..6=Sat

    // Определяем понедельник текущей недели
    const mondayOffset = currentDayOfWeek === 0 ? -6 : 1 - currentDayOfWeek;
    const monday = new Date(now);
    monday.setDate(today + mondayOffset);

    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const monthNames = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
                        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    const fullDayNames = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];

    dateLabel.innerText = `${today} ${monthNames[now.getMonth()]}, ${fullDayNames[now.getDay()]}`;

    weekRow.innerHTML = '';
    for (let i = 0; i < 7; i++) {
        const d = new Date(monday);
        d.setDate(monday.getDate() + i);
        const dayNum = d.getDate();
        const isToday = dayNum === today && d.getMonth() === now.getMonth();
        
        const circle = document.createElement('div');
        circle.className = 'day-circle' + (isToday ? ' active' : '');
        circle.innerHTML = `<span>${dayNum}</span>${dayNames[i]}`;
        weekRow.appendChild(circle);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    try {
        const profile = (window.AIDiet && window.AIDiet.getProfile)
            ? window.AIDiet.getProfile()
            : JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
        
        // 1. Приветствие
        renderGreeting(profile);
        
        // 1.5 Week Switcher
        renderWeekSwitcher();
        
        // 2. Витамины
        renderVitaminAlerts(profile);

        // ── ПРОВЕРКА ДОСТИЖЕНИЯ ЦЕЛИ ──────────────────────────────────
        // Запускается 1 раз за сессию, чтобы не раздражать
        const goalShown = sessionStorage.getItem('aidiet_goal_achieved_shown');
        if (!goalShown && profile) {
            const targetWeight = parseFloat(profile['Целевой вес']);
            const goalType = profile['Главная цель'] || profile['Какая у тебя сейчас главная цель?'] || '';
            const weightLogs = JSON.parse(localStorage.getItem('aidiet_weight_logs') || '[]');
            
            if (targetWeight && weightLogs.length > 0) {
                const latestWeight = weightLogs[weightLogs.length - 1].value;
                const isWeightLoss = goalType.includes('Снизить вес');
                const isMassGain  = goalType.includes('Набрать');

                const goalReached =
                    (isWeightLoss && latestWeight <= targetWeight) ||
                    (isMassGain  && latestWeight >= targetWeight);

                if (goalReached) {
                    sessionStorage.setItem('aidiet_goal_achieved_shown', 'true');
                    location.href = 'pr1-goal-achieved.html';
                    return;
                }
            }
        }
        // ─────────────────────────────────────────────────────────────

        // 3. План питания
        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw) return; // План еще не сгенерирован

        let plan = JSON.parse(planRaw); if (typeof plan === "string") plan = JSON.parse(plan);
        if (!plan.day_1 || plan.day_1.length === 0) return;

        const targets = calculateTargets(profile);

        // Расчет съеденных калорий (из трекера aidiet_eaten_today)
        const eatenRaw = localStorage.getItem('aidiet_eaten_today');
        let eaten = { cals: 0, p: 0, f: 0, c: 0 };
        if (eatenRaw) {
            try { eaten = JSON.parse(eatenRaw); } catch(e) {}
        }

        // D6: Обновляем кольцо калорий
        const ringValueEl = document.getElementById('ringValue');
        if (ringValueEl) ringValueEl.innerText = targets.cals;

        const ringLabelEl = document.getElementById('ringLabel');
        if (ringLabelEl) ringLabelEl.innerText = eaten.cals > 0 ? `из ${targets.cals}` : 'ккал/день';

        const svgCircle = document.querySelector('.ring-svg circle:nth-child(2)');
        if (svgCircle) {
            const percent = eaten.cals > 0 ? Math.min((eaten.cals / targets.cals) * 100, 100) : 0;
            const offset = 339.29 - (percent / 100) * 339.29;
            svgCircle.style.strokeDashoffset = offset;
        }

        // 5. Обновляем БЖУ бары (факт / цель) + D7: клетчатка
        const macroItems = document.querySelectorAll('.macro-item');
        const macroData = [
            { name: 'Белки', actual: eaten.p, target: targets.p },
            { name: 'Жиры', actual: eaten.f, target: targets.f },
            { name: 'Углеводы', actual: eaten.c, target: targets.c },
            { name: 'Клетчатка', actual: eaten.fiber || 0, target: targets.fiber }
        ];
        macroItems.forEach((item, i) => {
            if (i >= macroData.length) return;
            const d = macroData[i];
            const infoEl = item.querySelector('.macro-info span:nth-child(2)');
            const fillEl = item.querySelector('.macro-fill');
            if (infoEl) infoEl.innerText = `${Math.round(d.actual)}/${d.target} г`;
            if (fillEl) fillEl.style.width = `${Math.min((d.actual / d.target) * 100, 100)}%`;
        });

        // D5: Smart Next Meal — определяем текущий день и первое несъеденное блюдо
        const dayOfWeek = new Date().getDay(); // 0=Sun..6=Sat
        const dayIndex = dayOfWeek === 0 ? 7 : dayOfWeek; // 1=Mon..7=Sun
        const dayKey = `day_${dayIndex}`;
        let dayMealsRaw = plan[dayKey] || plan.day_1;
        // Поддержка вложенной структуры {meals: [...]}
        if (dayMealsRaw && !Array.isArray(dayMealsRaw) && dayMealsRaw.meals) dayMealsRaw = dayMealsRaw.meals;
        const dayMeals = Array.isArray(dayMealsRaw) ? dayMealsRaw : [];
        
        // Ищем завершенные и предстоящие блюда (Timeline)
        const eatenMeals = JSON.parse(localStorage.getItem('aidiet_eaten_meals') || '[]');
        
        let allMeals = [];
        
        // Сканируем вчера, сегодня и завтра
        const daysToScan = [
            dayIndex - 1 < 1 ? 7 : dayIndex - 1, // Вчера
            dayIndex,                            // Сегодня
            dayIndex + 1 > 7 ? 1 : dayIndex + 1  // Завтра
        ];
        
        daysToScan.forEach(scanIdx => {
            const tempDayKey = `day_${scanIdx}`;
            let tempMealsRaw = plan[tempDayKey];
            if (tempMealsRaw && tempMealsRaw.meals) tempMealsRaw = tempMealsRaw.meals;
            const tempMeals = Array.isArray(tempMealsRaw) ? tempMealsRaw : [];
            
            tempMeals.forEach((m, idx) => {
                const isPast = eatenMeals.includes(`${tempDayKey}_${idx}`);
                allMeals.push({
                    meal: m,
                    dayKey: tempDayKey,
                    idx: idx,
                    dayNum: scanIdx,
                    isPast: isPast
                });
            });
        });

        // Отбираем до 2 прошедших и до 3 предстоящих
        const pastMeals = allMeals.filter(m => m.isPast).slice(-2);
        const futureMeals = allMeals.filter(m => !m.isPast).slice(0, 3);
        const displayMeals = [...pastMeals, ...futureMeals];

        const upcomingContainer = document.getElementById('upcoming-meals-container');
        if (upcomingContainer) {
            upcomingContainer.innerHTML = '';
            
            if (displayMeals.length === 0) {
                upcomingContainer.innerHTML = '<div style="padding: 20px; text-align: center; color: var(--color-text-secondary); width: 100%; font-size: 14px; font-weight: 500;">План питания пуст или все приёмы завершены</div>';
            } else {
                displayMeals.forEach((item, i) => {
                  try {
                    const m = item.meal;
                    if (!m) return; // Защита от null
                    const card = document.createElement('div');
                    card.className = 'meal-card action-card';
                    card.style.cssText = 'flex: 0 0 85vw; flex-direction: column; gap: 12px; padding-bottom: 12px; scroll-snap-align: center; margin: 0; display: flex; transition: all 0.3s ease;';
                    
                    if (item.isPast) {
                        card.style.opacity = '0.75';
                        card.style.filter = 'grayscale(15%)';
                    }
                    if (!item.isPast && futureMeals.length > 0 && item === futureMeals[0]) {
                        card.id = 'first-future-meal';
                    }
                    
                    let mealTypeRu = m.meal || m.meal_type || 'Прием пищи';
                    let dayPrefix = '';
                    if (item.dayNum === (dayIndex - 1 < 1 ? 7 : dayIndex - 1)) dayPrefix = '(Вчера) ';
                    else if (item.dayNum === (dayIndex + 1 > 7 ? 1 : dayIndex + 1)) dayPrefix = '(Завтра) ';
                    
                    let imgUrl = m.image_url;
                    let isPlaceholder = false;
                    if (imgUrl && (imgUrl.startsWith('http') || imgUrl.startsWith('/images/'))) {
                        if (imgUrl.startsWith('/') && window.AIDiet && window.AIDiet.API_BASE) imgUrl = window.AIDiet.API_BASE + imgUrl;
                        else if (imgUrl.startsWith('/')) imgUrl = (typeof API_BASE !== 'undefined' ? API_BASE : 'https://aidiet-api.onrender.com') + imgUrl;
                    } else {
                        imgUrl = "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=200&h=200&fit=crop";
                        isPlaceholder = true;
                    }
                    
                    const imgId = `dash-img-${item.dayKey}-${item.idx}`;

                    card.innerHTML = `
                        <div style="display: flex; gap: 16px; cursor: pointer;" onclick="location.href='p2-recipe-detail.html?day=${item.dayNum}&meal=${item.idx}'">
                          <img src="${imgUrl}" id="${imgId}" alt="Meal" class="meal-img" style="width: 80px; height: 80px; border-radius: 12px; object-fit: cover;">
                          <div class="meal-content" style="flex: 1; display: flex; flex-direction: column; justify-content: center;">
                            <div>
                              <div class="meal-meta" style="font-size: 12px; font-weight: 600; color: var(--color-primary); text-transform: uppercase;">${dayPrefix}${mealTypeRu}</div>
                              <div class="meal-name" style="font-size: 16px; font-weight: 700; color: var(--color-text-primary); margin: 2px 0;">${m.name || "AI Блюдо"}</div>
                              <div class="meal-stats" style="display: flex; gap: 12px; font-size: 13px; color: var(--color-text-secondary); font-weight: 500;">
                                <span>🔥 ${m.calories || 0} ккал</span>
                                <span>🕒 ${m.prep_time_min || 15} мин</span>
                              </div>
                            </div>
                          </div>
                        </div>
                        ${item.isPast ? `
                        <div style="flex: 1; padding: 10px; border-radius: 12px; background: #F3F4F6; color: #4B5563; font-weight: 700; font-size: 14px; display: flex; justify-content: center; align-items: center; gap: 6px; cursor: default;">
                          <i class="ph-fill ph-check-circle" style="font-size: 18px; color: #52B044;"></i> Завершено
                        </div>
                        ` : `
                        <div style="display: flex; gap: 8px;">
                          <button onclick="eatMealPlanDashboard('${item.dayKey}', ${item.idx}, ${m.calories||0})" style="flex: 1; padding: 10px; border-radius: 12px; background: #E8F5E2; color: #52B044; font-weight: 700; border: none; font-size: 14px; cursor: pointer; display: flex; justify-content: center; align-items: center; gap: 6px;"><i class="ph ph-check" style="font-size: 16px;"></i> Съел план</button>
                          <button onclick="var s=document.getElementById('mealSwapSheet');s.style.visibility='visible';s.style.transform='translateY(0)'" style="flex: 1; padding: 10px; border-radius: 12px; background: #F3F4F6; color: #6B7280; font-weight: 700; border: none; font-size: 14px; cursor: pointer; display: flex; justify-content: center; align-items: center; gap: 6px;"><i class="ph ph-swap" style="font-size: 16px;"></i> Съел другое</button>
                        </div>
                        `}
                    `;
                    
                    if (m.wellness_rationale && i === 0) {
                        const rationaleEl = document.createElement('div');
                        rationaleEl.style.fontSize = '11px';
                        rationaleEl.style.color = '#F5922B';
                        rationaleEl.style.marginTop = '4px';
                        rationaleEl.style.lineHeight = '1.3';
                        rationaleEl.innerHTML = `<b>AI:</b> ${m.wellness_rationale}`;
                        card.querySelector('.meal-content').appendChild(rationaleEl);
                    }
                    
                    upcomingContainer.appendChild(card);
                    
                    if (isPlaceholder && typeof generateRecipeImageAPI === 'function' && m.name) {
                        const ingredientsList = (m.ingredients || []).map(ing => typeof ing === 'string' ? ing : ing.name).filter(Boolean);
                        generateRecipeImageAPI(m.name, ingredientsList).then(url => {
                            if (url) {
                                const el = document.getElementById(imgId);
                                if (el) el.src = url;
                                m.image_url = url;
                                localStorage.setItem('aidiet_meal_plan', JSON.stringify(plan));
                            }
                        });
                    }

                  } catch(e) {
                      console.error("Ошибка рендера карточки:", e);
                  }
                });
                
                // Auto-scroll to the first future meal with a slight delay
                setTimeout(() => {
                    const firstFuture = document.getElementById('first-future-meal');
                    if (firstFuture && upcomingContainer) {
                        firstFuture.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
                    }
                }, 100);
            }
        }
        
        applyTierLocks();

        console.log("[Dashboard State] Успешно загружен план AI и профиль");

    } catch (e) {
        console.error("[Dashboard State] Ошибка парсинга:", e);
    }
});

/**
 * Логика применения замочков и апселлов на дашборде
 */
function applyTierLocks() {
    const currentTier = localStorage.getItem('aidiet_subscription') || 'base';
    
    // Quick Action Buttons
    const btnTraining = document.getElementById('btn-training');
    const btnVitamins = document.getElementById('btn-vitamins');
    const btnDrinks = document.getElementById('btn-drinks');
    const btnPhoto = document.getElementById('btn-photo');
    
    const drinkSheet = document.getElementById('drinkEntrySheet');
    const btnSaveDrink = document.getElementById('btnSaveDrink');
    
    // Вспомогательная функция для добавления иконки-замочка
    const addLock = (element) => {
        if (!element) return;
        element.style.position = 'relative';
        const lockHtml = `<div style="position:absolute; top:-4px; right:-4px; background:#1A1A1A; color:#FFD700; border-radius:50%; width:18px; height:18px; display:flex; justify-content:center; align-items:center; font-size:10px; border:2px solid #FFF;"><i class="ph-fill ph-lock-key"></i></div>`;
        element.querySelector('.action-icon').innerHTML += lockHtml;
    };

    // Тренировка: Base/Black -> замок, Gold -> Открыто
    if (btnTraining) {
        if (currentTier === 'base' || currentTier === 'black') {
            addLock(btnTraining);
            btnTraining.addEventListener('click', () => { location.href = 'u12-subscription.html'; }); // Временный линк на апселл (Экран статусов / U-12)
        } else {
            btnTraining.addEventListener('click', () => { location.href = 'pr1-activity-detail.html'; });
        }
    }

    // Витамины: Base -> замок, Black/Gold -> Открыто
    if (btnVitamins) {
        if (currentTier === 'base') {
            addLock(btnVitamins);
            btnVitamins.addEventListener('click', () => { location.href = 'u12-subscription.html'; }); 
        } else {
            btnVitamins.addEventListener('click', () => { location.href = 'p5-vitamins.html'; });
        }
    }

    // Фото: Base/Black -> замок, Gold -> Открыто
    if (btnPhoto) {
        if (currentTier === 'base' || currentTier === 'black') {
            addLock(btnPhoto);
            btnPhoto.addEventListener('click', () => { location.href = 'u12-subscription.html'; }); 
        } else {
            btnPhoto.addEventListener('click', () => { location.href = 'ph1-photo-analysis.html'; });
        }
    }

    // Напитки: Base -> замок, Black/Gold -> Открыто
    if (btnDrinks) {
        if (currentTier === 'base') {
            addLock(btnDrinks);
            btnDrinks.addEventListener('click', () => { location.href = 'u12-subscription.html'; });
        } else {
            btnDrinks.addEventListener('click', () => {
                if (drinkSheet) {
                    drinkSheet.style.visibility = 'visible';
                    drinkSheet.style.transform = 'translateY(0)';
                }
            });
        }
    }

    // Логика сохранения напитка
    if (btnSaveDrink) {
        btnSaveDrink.addEventListener('click', () => {
            const name = document.getElementById('drinkName').value;
            const volume = document.getElementById('drinkVolume').value;
            const abv = document.getElementById('drinkABV').value || 0;

            if (!name || !volume) {
                alert("Укажи название и объём напитка");
                return;
            }

            const kCal = Math.round(parseInt(volume) * (parseFloat(abv||0) * 0.07));

            const existingLogs = JSON.parse(localStorage.getItem('aidiet_drink_logs') || '[]');
            existingLogs.push({ name, volume: parseInt(volume), abv: parseFloat(abv||0), calories: kCal, timestamp: new Date().toISOString() });
            localStorage.setItem('aidiet_drink_logs', JSON.stringify(existingLogs));
            
            if (typeof window.adjustRemainingPlan === 'function' && kCal > 0) {
                window.adjustRemainingPlan(kCal);
            }

            if (drinkSheet) drinkSheet.style.transform = 'translateY(100%)';
            setTimeout(() => location.reload(), 300);
        });
    }

    const btnSaveSnack = document.getElementById('btnSaveSnack');
    if (btnSaveSnack) {
        btnSaveSnack.addEventListener('click', () => {
            const name = document.getElementById('snackName').value;
            const cals = parseInt(document.getElementById('snackCalories').value || '0');
            
            if (!name || cals <= 0) {
                alert("Укажи название и калорийность перекуса");
                return;
            }

            const existingLogs = JSON.parse(localStorage.getItem('aidiet_snack_logs') || '[]');
            existingLogs.push({ name, calories: cals, timestamp: new Date().toISOString() });
            localStorage.setItem('aidiet_snack_logs', JSON.stringify(existingLogs));

            if (typeof window.adjustRemainingPlan === 'function') {
                window.adjustRemainingPlan(cals);
            }
            
            const snackSheet = document.getElementById('snackEntrySheet');
            if (snackSheet) snackSheet.style.transform = 'translateY(100%)';
            setTimeout(() => location.reload(), 300);
        });
    }
    
    // Глобальная функция отметки о съеденном (для кнопки из JS)
    window.eatMealPlanDashboard = function(dayKey, idx, cals) {
        const eM = JSON.parse(localStorage.getItem('aidiet_eaten_meals') || '[]');
        if (!eM.includes(`${dayKey}_${idx}`)) {
            eM.push(`${dayKey}_${idx}`);
            localStorage.setItem('aidiet_eaten_meals', JSON.stringify(eM));
            // Log calories so the ring updates
            const l = JSON.parse(localStorage.getItem('aidiet_food_log') || '{"days":{}}');
            const tDate = new Date().toISOString().split('T')[0];
            if (!l.days[tDate]) l.days[tDate] = [];
            l.days[tDate].push({ name: `Блюдо по плану`, calories: cals || 0 });
            localStorage.setItem('aidiet_food_log', JSON.stringify(l));
            
            // Re-render
            location.reload();
        }
    };

    // Upsell Banner скрывается для Black и Gold
    const upsellBanner = document.querySelector('.upsell-banner');
    if (upsellBanner) {
        if (currentTier !== 'base') {
            upsellBanner.style.display = 'none';
        } else {
            upsellBanner.addEventListener('click', () => { location.href = 'o17-statuswall.html'; }); // Апселл-экран
        }
    }
}
