// recipe-detail-state.js
// Рендер конкретного блюда (P-2) из плана питания

document.addEventListener('DOMContentLoaded', () => {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const dayNum = urlParams.get('day') || 1;
        const mealIdx = urlParams.get('meal') || 0; 

        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw) return;
        let plan = JSON.parse(planRaw);
        if (typeof plan === 'string') plan = JSON.parse(plan);
        
        const dayKey = `day_${dayNum}`;
        let dayData = plan[dayKey];
        // Поддержка вложенной структуры {meals: [...]}
        if (dayData && !Array.isArray(dayData) && dayData.meals) {
            dayData = dayData.meals;
        }
        const meal = dayData && dayData[mealIdx] ? dayData[mealIdx] : null;

        if (!meal) {
            console.error('Блюдо не найдено');
            return;
        }
        
        // Нормализация полей
        const MEAL_MAP = { 'завтрак': 'breakfast', 'обед': 'lunch', 'ужин': 'dinner', 'перекус': 'snack' };
        meal.meal_type = meal.meal_type || MEAL_MAP[(meal.meal || '').toLowerCase()] || 'snack';
        meal.protein = meal.protein ?? meal.proteins ?? 0;
        meal.fat = meal.fat ?? meal.fats ?? 0;
        meal.calories = meal.calories ?? 0;
        meal.carbs = meal.carbs ?? 0;
        meal.fiber = meal.fiber ?? 0;
        meal.prep_time_min = meal.prep_time_min ?? 15;
        meal.serving_g = meal.serving_g ?? 300;
        // Нормализация steps
        if (meal.steps && meal.steps.length > 0 && typeof meal.steps[0] === 'string') {
            meal.steps = meal.steps.map((s, i) => ({ title: `Шаг ${i + 1}`, text: s }));
        }

        // 1. Рендер картинки
        const heroImg = document.querySelector('.food-img');
        let isPlaceholder = false;
        if (heroImg && meal.image_url && meal.image_url.startsWith('http')) {
            heroImg.src = meal.image_url;
        } else if (heroImg && meal.image_url && meal.image_url.startsWith('/')) {
            heroImg.src = (typeof window.AIDiet !== 'undefined' && window.AIDiet.API_BASE ? window.AIDiet.API_BASE : (typeof API_BASE !== 'undefined' ? API_BASE : 'https://aidiet-api.onrender.com')) + meal.image_url;
        } else if (heroImg) {
            heroImg.src = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=400&fit=crop";
            isPlaceholder = true;
        }
        
        if (isPlaceholder && typeof generateRecipeImageAPI === 'function' && meal.name) {
            const ingredientsList = (meal.ingredients || []).map(i => typeof i === 'string' ? i : i.name).filter(Boolean);
            generateRecipeImageAPI(meal.name, ingredientsList).then(url => {
                if (url && heroImg) {
                    heroImg.src = url;
                    meal.image_url = url;
                    localStorage.setItem('aidiet_meal_plan', JSON.stringify(plan));
                }
            });
        }

        // 2. Рендер базовой инфы
        const nameEl = document.querySelector('.meal-name');
        if (nameEl) nameEl.innerText = meal.name || 'AI Блюдо';

        const typeEl = document.querySelector('.meal-type');
        if (typeEl) {
            const t = meal.meal_type || 'snack';
            typeEl.innerText = t === 'breakfast' ? 'Завтрак' : t === 'lunch' ? 'Обед' : t === 'dinner' ? 'Ужин' : 'Перекус';
        }

        // 3. Макронутриенты + P.10 fiber
        const chips = document.querySelectorAll('.chip');
        if (chips.length >= 5) {
            chips[0].innerHTML = `<i class="ph ph-fire"></i> ${meal.calories || 0} ккал`;
            chips[1].innerHTML = `Б: ${meal.protein || 0} г`;
            chips[2].innerHTML = `Ж: ${meal.fat || 0} г`;
            chips[3].innerHTML = `У: ${meal.carbs || 0} г`;
            chips[4].innerHTML = `К: ${meal.fiber || 0} г`;
        }
        
        // Рендер времени и порции
        const infoVals = document.querySelectorAll('.info-val');
        if (infoVals.length >= 3) {
            infoVals[0].innerText = `${meal.prep_time_min || 15} мин`;
            infoVals[1].innerText = 'Средне';
            infoVals[2].innerText = `${meal.serving_g || 300} г`;
        }

        // 4. Ограничения по статусу
        const sub = localStorage.getItem('aidiet_subscription') || 'base';
        
        // 5. Рендер ингредиентов (все статусы видят ингредиенты)
        const ingContainer = document.querySelector('.ingredient-list');
        if (ingContainer && meal.ingredients) {
            ingContainer.innerHTML = '';
            meal.ingredients.forEach(ing => {
                ingContainer.innerHTML += `
                    <div class="ingredient-item">
                        <div class="ing-left"><div class="ing-dot"></div> ${ing.name}</div>
                        <div class="ing-amount">${ing.amount} ${ing.unit}</div>
                    </div>
                `;
            });
        }

        // 6. Блокировка шагов по статусу (P.1: ПРАВИЛЬНОЕ ветвление)
        const stepsContainer = document.querySelector('.recipe-steps');
        const startCookingBtn = document.querySelector('.btn-main');
        const replaceBtn = document.querySelector('.btn-sec'); 
        
        if (replaceBtn) {
            replaceBtn.onclick = () => location.href = `p3-replace-meal.html?day=${dayNum}&meal=${mealIdx}`;
        }

        if (sub === 'base') {
            // FREE: рецепт заблокирован
            if (replaceBtn) {
                replaceBtn.innerHTML = 'Заменить <i class="ph-fill ph-lock-key" style="color:var(--color-primary);"></i>';
                replaceBtn.onclick = () => location.href = 'o17-statuswall.html';
            }
            if (stepsContainer) {
                stepsContainer.innerHTML = `
                    <div style="background:var(--color-surface); border:1px solid var(--color-divider); border-radius:16px; padding:24px; text-align:center; display:flex; flex-direction:column; align-items:center; gap:12px;">
                        <div style="width:48px; height:48px; background:#1A1A1A; border-radius:14px; display:flex; justify-content:center; align-items:center; font-size:24px; color:#FFD700;">
                            <i class="ph-fill ph-lock-key"></i>
                        </div>
                        <div style="font-size:16px; font-weight:700;">Рецепт доступен с Статуса Black</div>
                        <div style="font-size:13px; color:var(--color-text-secondary); line-height:1.4;">Получите пошаговые рецепты, точные граммовки и таймеры с Premium аккаунтом.</div>
                        <button onclick="location.href='o17-statuswall.html'" style="margin-top:8px; padding:12px 24px; border-radius:12px; background:var(--color-primary-gradient); color:#FFF; font-weight:700; border:none; width:100%;">Разблокировать</button>
                    </div>
                `;
            }
            if (startCookingBtn) {
                startCookingBtn.innerHTML = '<i class="ph ph-check-bold"></i> Съел (без рецепта)';
            }
        } else {
            // BLACK / GOLD: рецепт доступен
            if (stepsContainer && meal.steps && meal.steps.length > 0) {
                stepsContainer.innerHTML = '';
                meal.steps.forEach((step, i) => {
                    stepsContainer.innerHTML += `
                        <div class="step-item">
                            <div class="step-number">${String(i + 1).padStart(2, '0')}</div>
                            <div class="step-content">
                                <div class="step-title">${step.title || `Шаг ${i + 1}`}</div>
                                <p class="step-text">${step.text || step.description || ''}</p>
                            </div>
                        </div>
                    `;
                });
            }
            if (startCookingBtn) {
                startCookingBtn.innerHTML = '<i class="ph ph-cooking-pot"></i> Начать готовку';
                startCookingBtn.onclick = () => { location.href = `p4-full-recipe.html?day=${dayNum}&meal=${mealIdx}`; };
            }
        }

    } catch (e) {
        console.error("Ошибка в рендере рецепта:", e);
    }
});
