// full-recipe-state.js
// Пошаговая готовка (P-4)

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
        if (dayData && !Array.isArray(dayData) && dayData.meals) dayData = dayData.meals;
        const meal = dayData && dayData[mealIdx] ? dayData[mealIdx] : null;

        if (!meal) return;

        // Header Title
        const titleEl = document.querySelector('.header-title');
        if (titleEl) titleEl.innerText = meal.name || 'Процесс готовки';

        // 1. Чекбоксы ингредиентов
        const ingContainer = document.querySelector('.ing-card');
        if (ingContainer && meal.ingredients) {
            ingContainer.innerHTML = '';
            meal.ingredients.forEach(ing => {
                const row = document.createElement('div');
                row.className = 'ing-item';
                row.innerHTML = `
                    <div class="ing-checkbox"><i class="ph ph-check"></i></div>
                    <span class="ing-label">${ing.name}</span>
                    <span class="ing-val">${ing.amount} ${ing.unit}</span>
                `;
                // Интерактив
                row.addEventListener('click', () => {
                    row.classList.toggle('checked');
                });
                ingContainer.appendChild(row);
            });
        }

        // 2. Шаги готовки — из реальных данных плана
        const stepsContainer = document.querySelector('.steps-list');
        if (stepsContainer) {
            stepsContainer.innerHTML = '';
            const rawSteps = meal.steps || [];
            rawSteps.forEach((step, i) => {
                const stepText = typeof step === 'string' ? step : (step.text || step.description || '');
                const stepTitle = typeof step === 'object' ? (step.title || `Шаг ${i + 1}`) : `Шаг ${i + 1}`;
                const card = document.createElement('div');
                card.className = 'step-card' + (i === 0 ? ' active' : '');
                card.innerHTML = `
                    <div class="step-number">${i + 1}</div>
                    <div class="step-content">
                        <div class="step-text">${stepText}</div>
                    </div>
                `;
                card.addEventListener('click', () => {
                    stepsContainer.querySelectorAll('.step-card').forEach(c => c.classList.remove('active'));
                    card.classList.add('active');
                });
                stepsContainer.appendChild(card);
            });

            // Если шагов нет, fallback
            if (rawSteps.length === 0) {
                stepsContainer.innerHTML = `
                    <div class="step-card active">
                        <div class="step-number">1</div>
                        <div class="step-content">
                            <div class="step-text">Подготовьте все ингредиенты. ${meal.wellness_rationale || ''}</div>
                        </div>
                    </div>
                `;
            }
        }

        // 3. Кнопка "Приготовил и съел"
        const finishBtn = document.querySelector('.btn-done');
        if (finishBtn) {
            finishBtn.addEventListener('click', () => {
                alert('Отлично! Дневной план обновлен.');
                location.href = 'p1-weekly-plan.html';
            });
        }

    } catch (e) {
        console.error("Ошибка P-4 State:", e);
    }
});
