// replace-meal-state.js
// Логика выбора альтернативного блюда (P-3)

document.addEventListener('DOMContentLoaded', () => {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const dayNum = urlParams.get('day') || 1;
        const mealIdx = urlParams.get('meal');

        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw || mealIdx === null) return;
        
        let plan = JSON.parse(planRaw); if (typeof plan === "string") plan = JSON.parse(plan);
        const dayKey = `day_${dayNum}`;
        const currentMeal = plan[dayKey] && plan[dayKey][mealIdx] ? plan[dayKey][mealIdx] : null;

        if (!currentMeal) return;

        // 1. Отобразить текущее блюдо
        const currentImg = document.querySelector('.current-meal-card .meal-img');
        if (currentImg) {
            currentImg.src = currentMeal.image_url && currentMeal.image_url.startsWith('http') 
                           ? currentMeal.image_url 
                           : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&h=100&fit=crop";
        }
        
        const currentName = document.querySelector('.current-meal-card .meal-name');
        if (currentName) currentName.innerText = currentMeal.name || "Исходное блюдо";

        const currentMeta = document.querySelector('.current-meal-card .meal-meta');
        if (currentMeta) currentMeta.innerText = `${currentMeal.calories || 0} ккал • ${currentMeal.prep_time_min || 15} мин`;

        // 2. Генерация моковых альтернатив на основе статуса
        const sub = localStorage.getItem('aidiet_subscription') || 'base';
        let altCount = 0;
        if (sub === 'black') altCount = 3;
        else if (sub === 'gold') altCount = 5;
        else altCount = 1;

        const altContainer = document.querySelector('.alt-list');
        if (!altContainer) return;
        altContainer.innerHTML = ''; // Очистка хардкода

        // Демонстрационный набор альтернатив
        const mockAlts = [
            { name: 'Лосось с овощами гриль', cal: 480, time: 20, img: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288' },
            { name: 'Чечевичный суп с беконом', cal: 390, time: 35, img: 'https://images.unsplash.com/photo-1547592166-23ac45744acd' },
            { name: 'Боул с тофу и киноа', cal: 420, time: 15, img: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd' },
            { name: 'Паста с креветками (ЦЗ)', cal: 510, time: 25, img: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141' },
            { name: 'Куриный ролл', cal: 400, time: 10, img: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af' }
        ];

        let selectedAlt = null;

        for(let i=0; i<altCount; i++) {
            const alt = mockAlts[i];
            const card = document.createElement('div');
            card.className = i === 0 && sub !== 'base' ? 'alt-card selected' : 'alt-card';
            
            if (i === 0 && sub !== 'base') selectedAlt = alt;

            const isLocked = sub === 'base';
            
            card.innerHTML = `
                <div class="alt-header">
                    <img src="${alt.img}?w=200&h=200&fit=crop" class="alt-img" alt="${alt.name}">
                    <div class="alt-content">
                        <div class="alt-name">${alt.name} <span style="font-size:10px; color:#F5922B;"></span></div>
                        <div class="alt-stats">
                            <span>🔥 ${alt.cal} ккал</span>
                            <span>🕒 ${alt.time} мин</span>
                        </div>
                    </div>
                    <div class="alt-selection">
                        ${isLocked ? '<i class="ph-fill ph-lock-key" style="color:var(--color-primary); font-size:24px;"></i>' : '<div class="btn-select-ring"></div>'}
                    </div>
                </div>
            `;
            
            if (!isLocked) {
                card.addEventListener('click', () => {
                    document.querySelectorAll('.alt-card').forEach(c => c.classList.remove('selected'));
                    card.classList.add('selected');
                    selectedAlt = alt;
                });
            } else {
                card.style.opacity = 0.7;
                card.addEventListener('click', () => location.href='o17-statuswall.html');
            }

            altContainer.appendChild(card);
        }

        // 3. Подтверждение замены
        const confirmBtn = document.querySelector('.btn-confirm');
        if (confirmBtn) {
            confirmBtn.addEventListener('click', () => {
                if (sub === 'base') {
                    location.href = 'o17-statuswall.html';
                    return;
                }
                
                if (selectedAlt) {
                    // Мутируем план — копируем все поля
                    plan[dayKey][mealIdx].name = selectedAlt.name;
                    plan[dayKey][mealIdx].calories = selectedAlt.cal;
                    plan[dayKey][mealIdx].prep_time_min = selectedAlt.time;
                    plan[dayKey][mealIdx].image_url = selectedAlt.img + '?w=400&h=400&fit=crop';
                    // P.7: Копируем макро-данные (если доступны)
                    if (selectedAlt.protein !== undefined) plan[dayKey][mealIdx].protein = selectedAlt.protein;
                    if (selectedAlt.fat !== undefined) plan[dayKey][mealIdx].fat = selectedAlt.fat;
                    if (selectedAlt.carbs !== undefined) plan[dayKey][mealIdx].carbs = selectedAlt.carbs;
                    if (selectedAlt.fiber !== undefined) plan[dayKey][mealIdx].fiber = selectedAlt.fiber;
                    if (selectedAlt.ingredients) plan[dayKey][mealIdx].ingredients = selectedAlt.ingredients;
                    
                    localStorage.setItem('aidiet_meal_plan', JSON.stringify(plan));
                    location.href = 'p1-weekly-plan.html';
                }
            });
        }

    } catch (e) {
        console.error("Ошибка замены блюда:", e);
    }
});
