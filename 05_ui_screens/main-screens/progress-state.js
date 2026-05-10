// progress-state.js
// Скрипт гидратации экрана прогресса (PR-1) и аналитики

document.addEventListener('DOMContentLoaded', () => {
    try {
        const profileRaw = localStorage.getItem('aidiet_profile');
        const planRaw = localStorage.getItem('aidiet_meal_plan');
        
        let currentWeight = "Не указан";
        let targetCalories = 0;

        // 1. Получаем вес из профиля
        if (profileRaw) {
            const profile = JSON.parse(profileRaw);
            if (profile['Текущий вес']) {
                currentWeight = `${profile['Текущий вес']} кг`;
            }
        }

        // 2. Получаем план калорий из ИИ рациона
        if (planRaw) {
            let plan = JSON.parse(planRaw); if (typeof plan === "string") plan = JSON.parse(plan);
            let day1 = plan.day_1;
            // Поддержка вложенной структуры {meals: [...]}
            if (day1 && !Array.isArray(day1) && day1.meals) day1 = day1.meals;
            if (day1 && Array.isArray(day1) && day1.length > 0) {
                day1.forEach(meal => {
                    targetCalories += (meal.calories || 0);
                });
            }
        }

        // 3. Подмена данных на экране
        const cards = document.querySelectorAll('.card');
        cards.forEach(card => {
            const titleEl = card.querySelector('.card-title');
            const metaEl = card.querySelector('.card-meta');
            
            if (titleEl && metaEl) {
                const titleText = titleEl.innerText;
                
                // Карточка Веса
                if (titleText.includes("Вес тела")) {
                    metaEl.innerText = currentWeight;
                }
                
                // Карточка Калорий
                if (titleText.includes("Калории")) {
                    if (targetCalories > 0) {
                        metaEl.innerText = `План: ${targetCalories} ккал`;
                        metaEl.style.fontSize = '16px'; // немного уменьшим шрифт, чтобы влезло слово "План"
                    }
                }
            }
        });

        console.log("[Progress State] Экран прогресса успешно обновлен");

    } catch (e) {
        console.error("[Progress State] Ошибка загрузки прогресса:", e);
    }
});
