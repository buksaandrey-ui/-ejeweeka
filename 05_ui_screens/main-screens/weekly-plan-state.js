// weekly-plan-state.js
// Скрипт гидратации еженедельного плана (P-1)

    document.addEventListener('DOMContentLoaded', () => {
    try {
        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw) {
            console.warn("[Weekly Plan State] План не найден в localStorage");
            return;
        }

        let plan = JSON.parse(planRaw);
        // Защита от двойной сериализации
        if (typeof plan === 'string') plan = JSON.parse(plan);
        
        // --- Нормализация структуры (поддержка обоих форматов) ---
        const MEAL_MAP = { 'завтрак': 'breakfast', 'обед': 'lunch', 'ужин': 'dinner', 'перекус': 'snack' };
        for (let i = 1; i <= 7; i++) {
            const key = `day_${i}`;
            if (!plan[key]) continue;
            // Если day_N — объект с meals, распаковать
            if (!Array.isArray(plan[key]) && plan[key].meals) {
                plan[key] = plan[key].meals;
            }
            if (!Array.isArray(plan[key])) continue;
            // Нормализация полей каждого блюда
            plan[key] = plan[key].map(m => ({
                ...m,
                meal_type: m.meal_type || MEAL_MAP[(m.meal || '').toLowerCase()] || 'snack',
                protein: m.protein ?? m.proteins ?? 0,
                fat: m.fat ?? m.fats ?? 0,
                calories: m.calories ?? 0,
                carbs: m.carbs ?? 0,
                fiber: m.fiber ?? 0,
                prep_time_min: m.prep_time_min ?? 15,
                image_url: m.image_url || '',
            }));
        }

        if (!plan.day_1 || plan.day_1.length === 0) return;
        
        // Получаем статус
        const sub = localStorage.getItem('aidiet_subscription') || 'base';
        
        // P.3: Dynamic day selector rendering
        const daySelector = document.getElementById('daySelector');
        const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        const now = new Date();
        const currentDayOfWeek = now.getDay(); // 0=Sun..6=Sat
        const mondayOffset = currentDayOfWeek === 0 ? -6 : 1 - currentDayOfWeek;
        const monday = new Date(now);
        monday.setDate(now.getDate() + mondayOffset);

        const dayItems = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(monday);
            d.setDate(monday.getDate() + i);
            const dayNum = d.getDate();
            const isToday = dayNum === now.getDate() && d.getMonth() === now.getMonth();
            
            const item = document.createElement('div');
            item.className = 'day-item' + (isToday ? ' active' : '');
            item.innerHTML = `${dayNames[i]}<span>${dayNum}</span>`;
            item.dataset.dayIndex = i + 1; // 1-indexed for plan keys
            
            if (daySelector) daySelector.appendChild(item);
            dayItems.push(item);
        }

        // P.11: Vitamin link tier guard
        const vitaminLink = document.getElementById('vitaminLink');
        if (vitaminLink && sub === 'base') {
            vitaminLink.style.opacity = '0.6';
            vitaminLink.innerHTML = `
                <span class="vitamin-link-text"><i class="ph ph-pill"></i> Витамины на сегодня</span>
                <i class="ph-fill ph-lock-key" style="color: var(--color-primary);"></i>
            `;
            vitaminLink.href = 'o17-statuswall.html';
        }

        dayItems.forEach((item, index) => {
            const dayNum = index + 1;
            
            // Если статус Base, блокируем дни с 3 по 7
            if (sub === 'base' && dayNum > 2) {
                item.style.opacity = '0.5';
                item.innerHTML = `<i class="ph-fill ph-lock-key" style="margin-bottom:2px; color:var(--color-primary);"></i><span>🔒</span>`;
                item.addEventListener('click', () => {
                    location.href = 'o17-statuswall.html';
                });
            } else {
                item.addEventListener('click', () => {
                    // Update active class
                    dayItems.forEach(d => d.classList.remove('active'));
                    item.classList.add('active');
                    // Rerender plan
                    renderDay(dayNum);
                });
            }
        });

        const contentContainer = document.querySelector('.content');

        // Словарь эмодзи и времени для приемов пищи
        const mealMeta = {
            'breakfast': { name: 'Завтрак', emoji: '🍳', time: '08:00' },
            'lunch': { name: 'Обед', emoji: '🍲', time: '13:30' },
            'dinner': { name: 'Ужин', emoji: '🥗', time: '19:00' },
            'snack': { name: 'Перекус', emoji: '🥪', time: '16:00' }
        };

        // Главная функция рендера дня
        function renderDay(dayNum) {
            // Очистка старых секций
            const mealSections = document.querySelectorAll('.meal-section');
            mealSections.forEach(sec => sec.remove());
            
            // Удалим хардкодное окно Meal Swap Sheet (мы встроим простое для MVP)
            const swapSheet = document.getElementById('mealSwapSheet');
            if (swapSheet && swapSheet.parentNode === contentContainer) {
                // Keep it where it is, or move it out
            }

            const dayKey = `day_${dayNum}`;
            const dayMeals = plan[dayKey];
            
            if (!dayMeals || dayMeals.length === 0) {
                const emptyMsg = document.createElement('div');
                emptyMsg.className = 'meal-section';
                emptyMsg.innerHTML = '<div style="text-align:center; padding: 40px 20px; color: var(--color-text-secondary);">План на этот день не найден</div>';
                
                // Вставляем пустой день *до* ссылки на витамины или swapSheet
                const insertBeforeNode = document.getElementById('mealSwapSheet') || null;
                contentContainer.insertBefore(emptyMsg, insertBeforeNode);
                return;
            }

            // Рендер блюд
            dayMeals.forEach((meal, idx) => {
                const mType = meal.meal_type || 'snack';
                const meta = mealMeta[mType] || mealMeta['snack'];

                const newSection = document.createElement('section');
                newSection.className = 'meal-section';
                
                let imgUrl = meal.image_url;
                let isPlaceholder = false;
                if (!imgUrl || imgUrl === "") {
                    imgUrl = "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=200&h=200&fit=crop";
                    isPlaceholder = true;
                } else if (imgUrl.startsWith('/')) {
                    imgUrl = (typeof window.AIDiet !== 'undefined' && window.AIDiet.API_BASE ? window.AIDiet.API_BASE : (typeof API_BASE !== 'undefined' ? API_BASE : 'https://aidiet-api.onrender.com')) + imgUrl;
                }
                
                const imgId = `img-day${dayNum}-meal${idx}`;

                newSection.innerHTML = `
                    <div class="section-header">
                        <span class="section-name">${meta.emoji} ${meta.name}</span>
                        <span class="section-time">${meta.time}</span>
                    </div>
                    <div class="meal-card action-card" style="flex-direction: column; gap: 12px; padding-bottom: 12px; cursor: default;">
                        <div style="display: flex; gap: 12px;" onclick="location.href='p2-recipe-detail.html?day=${dayNum}&meal=${idx}'" class="meal-click-area">
                            <img src="${imgUrl}" id="${imgId}" class="meal-img" style="cursor: pointer;" alt="${meta.name}">
                            <div class="meal-info" style="cursor: pointer;">
                                <div class="meal-name">${meal.name}</div>
                                <div class="meal-stats"><span>${meal.calories || 0} ккал</span><span>•</span><span>${meal.prep_time_min || 15} мин</span></div>
                            </div>
                        </div>
                        <div style="display: flex; gap: 8px;">
                            <button class="btn-eat-plan btn-spring" style="flex: 1; padding: 10px; border-radius: 12px; background: #E8F5E2; color: #52B044; font-weight: 700; border: none; font-size: 13px; cursor: pointer; display: flex; justify-content: center; align-items: center; gap: 6px;"><i class="ph ph-check-bold" style="font-size: 16px;"></i> Съел план</button>
                            <button class="btn-eat-other btn-spring" style="flex: 1; padding: 10px; border-radius: 12px; background: #F3F4F6; color: #6B7280; font-weight: 700; border: none; font-size: 13px; cursor: pointer; display: flex; justify-content: center; align-items: center; gap: 6px; position:relative;">
                                <i class="ph ph-swap" style="font-size: 16px;"></i> Съел другое
                            </button>
                        </div>
                    </div>
                `;

                // Insert before the swap sheet so the sheet stays at the bottom
                const insertBeforeNode = document.getElementById('mealSwapSheet');
                if (insertBeforeNode) {
                    contentContainer.insertBefore(newSection, insertBeforeNode);
                } else {
                    contentContainer.appendChild(newSection);
                }
                
                if (isPlaceholder && typeof generateRecipeImageAPI === 'function' && meal.name) {
                    const ingredientsList = (meal.ingredients || []).map(i => typeof i === 'string' ? i : i.name).filter(Boolean);
                    generateRecipeImageAPI(meal.name, ingredientsList).then(url => {
                        if (url) {
                            const imgEl = document.getElementById(imgId);
                            if (imgEl) imgEl.src = url;
                            meal.image_url = url;
                            localStorage.setItem('aidiet_meal_plan', JSON.stringify(plan));
                        }
                    });
                }

                // Интерактив для кнопок
                const btnEatPlan = newSection.querySelector('.btn-eat-plan');
                btnEatPlan.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const isEaten = newSection.querySelector('.meal-card').classList.toggle('eaten');
                    if (isEaten) {
                        btnEatPlan.innerHTML = '<i class="ph ph-check-bold" style="font-size: 16px;"></i> Съедено';
                    } else {
                        btnEatPlan.innerHTML = '<i class="ph ph-check-bold" style="font-size: 16px;"></i> Съел план';
                    }
                });

                const btnEatOther = newSection.querySelector('.btn-eat-other');
                btnEatOther.addEventListener('click', (e) => {
                    e.stopPropagation();
                    
                    // Сохраняем индексы в шторке, чтобы знать что мы меняем 
                    const swapSheet = document.getElementById('mealSwapSheet');
                    if (swapSheet) {
                        swapSheet.dataset.day = dayNum;
                        swapSheet.dataset.meal = idx;
                        swapSheet.style.transform = 'translateY(0)';
                    }
                });
            });
            
            // Re-bind haptics via the global function if exists
            if (window.hapticImpact) {
               // Nothing needed here because the global listener captures clicks on .btn-spring
            }
        } // end renderDay

        // Инициализация логики внутри шторки
        const initSwapSheetLogic = () => {
            const swapSheet = document.getElementById('mealSwapSheet');
            if (!swapSheet) return;

            const sheetBtns = swapSheet.querySelectorAll('button:not(:first-child)');
            if (sheetBtns.length >= 2) {
                const manualBtn = sheetBtns[0];
                const photoBtn = sheetBtns[1];

                manualBtn.addEventListener('click', () => {
                    // Переход на экран P-3 (Замена) с передачей параметров
                    const dayNum = swapSheet.dataset.day || 1;
                    const mealIdx = swapSheet.dataset.meal || 0;
                    location.href = `p3-replace-meal.html?day=${dayNum}&meal=${mealIdx}`;
                });

                photoBtn.onclick = null;
                
                if (sub !== 'gold') {
                    photoBtn.style.opacity = '0.8';
                    const goldBadge = photoBtn.querySelector('div:last-child');
                    if (goldBadge) goldBadge.innerHTML = '<i class="ph-fill ph-lock-key"></i> Gold';
                    
                    photoBtn.addEventListener('click', () => {
                        location.href = 'o17-statuswall.html';
                    });
                } else {
                    photoBtn.addEventListener('click', () => {
                        location.href = 'ph1-photo-analysis.html';
                    });
                }
            }
        };

        initSwapSheetLogic();

        // P.4: Auto-select current day
        const todayDayOfWeek = new Date().getDay();
        let defaultDayIndex = todayDayOfWeek === 0 ? 6 : todayDayOfWeek - 1; // 0=Mon..6=Sun
        if (dayItems[defaultDayIndex]) {
           dayItems[defaultDayIndex].click();
        }

        console.log("[Weekly Plan State] План питания успешно загружен");

    } catch (e) {
        console.error("[Weekly Plan State] Ошибка отображения плана:", e);
    }
});
