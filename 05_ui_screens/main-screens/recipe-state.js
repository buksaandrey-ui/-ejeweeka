// recipe-state.js
// Скрипт гидратации экрана полного рецепта (P-4) данными от AI

document.addEventListener('DOMContentLoaded', () => {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        let mealIdx = parseInt(urlParams.get('meal')) || 0; // По умолчанию берем 1-й прием пищи

        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw) {
            console.warn("[Recipe State] План рецептов не найден в памяти");
            return;
        }

        let plan = JSON.parse(planRaw); if (typeof plan === "string") plan = JSON.parse(plan);
        let day1 = plan.day_1;
        // Поддержка вложенной структуры {meals: [...]}
        if (day1 && !Array.isArray(day1) && day1.meals) day1 = day1.meals;
        if (!day1 || !Array.isArray(day1) || day1.length <= mealIdx) return;

        const meal = day1[mealIdx];

        // 1. Изменяем Заголовок
        const titleEl = document.querySelector('.header-title');
        if (titleEl) {
            titleEl.innerText = `Готовим: ${meal.name || 'AI Блюдо'}`;
        }

        // 2. Рендер Ингредиентов
        const ingCard = document.querySelector('.ing-card');
        if (ingCard && meal.ingredients && meal.ingredients.length > 0) {
            ingCard.innerHTML = ''; // Очищаем старые
            meal.ingredients.forEach(ing => {
                const item = document.createElement('div');
                item.className = 'ing-item';
                const amountVal = ing.amount !== undefined ? ing.amount : '';
                const unitVal = ing.unit !== undefined ? ing.unit : '';
                const fullAmount = `${amountVal} ${unitVal}`.trim();
                
                item.innerHTML = `
                    <div class="ing-checkbox"><i class="ph ph-check-bold"></i></div>
                    <span class="ing-label">${ing.name}</span>
                    <span class="ing-val">${fullAmount}</span>
                `;
                // Чекбоксы интерактивные
                item.addEventListener('click', () => item.classList.toggle('checked'));
                ingCard.appendChild(item);
            });
        }

        // 3. Рендер Этапов приготовления
        const stepsList = document.querySelector('.steps-list');
        if (stepsList && meal.steps && meal.steps.length > 0) {
            stepsList.innerHTML = ''; // Очищаем старые
            meal.steps.forEach((step, idx) => {
                const stepNum = idx + 1;
                const stepText = typeof step === 'string' ? step : (step.text || step.description || `Шаг ${stepNum}`);
                const sCard = document.createElement('div');
                sCard.className = `step-card ${idx === 0 ? 'active' : ''}`;
                
                // Добавим простенькую логику таймера, если в строке есть "минут"
                let timerHtml = '';
                const minMatch = stepText.match(/(\d+)\s*(?:мин|минут)/);
                if (minMatch) {
                    timerHtml = `<button class="timer-btn" onclick="alert('Таймер на ${minMatch[1]} мин запущен!')"><i class="ph ph-timer"></i> ${minMatch[1]}:00</button>`;
                }

                sCard.innerHTML = `
                    <div class="step-number">${stepNum}</div>
                    <div class="step-content">
                        <p class="step-text">${stepText}</p>
                        ${timerHtml}
                    </div>
                `;
                
                // Клик делает шаг активным (окрашивает оранжевым)
                sCard.addEventListener('click', function() {
                    document.querySelectorAll('.step-card').forEach(c => c.classList.remove('active'));
                    this.classList.add('active');
                });
                
                stepsList.appendChild(sCard);
            });
        }

        console.log("[Recipe State] Рецепт успешно загружен");

    } catch (e) {
        console.error("[Recipe State] Ошибка парсинга рецепта:", e);
    }
});
