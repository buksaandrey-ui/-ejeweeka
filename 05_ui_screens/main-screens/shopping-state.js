// shopping-state.js
// Скрипт интеллектуальной гидратации списка покупок с разбиением по категориям супермаркета
// Версия 2.0 (Умный Агрегатор + Множители дней)

const CATEGORY_MAP = {
    produce: { icon: "ph-leaf", name: "Овощи, фрукты и зелень", keywords: ["огурец", "помидор", "томат", "брокколи", "лук", "чеснок", "авокадо", "яблоко", "банан", "зелень", "петрушка", "укроп", "шпинат", "салат", "морковь", "картофель", "капуста"] },
    meat_fish: { icon: "ph-cooking-pot", name: "Мясо и рыба", keywords: ["кури", "говядина", "свинина", "индейк", "рыба", "лосось", "семга", "форель", "креветки", "морепродукт", "мясо", "фарш", "тунец"] },
    dairy: { icon: "ph-drop", name: "Молочные продукты и яйца", keywords: ["молоко", "сыр", "творог", "кефир", "йогурт", "сметана", "масло сливочное", "яйц"] },
    grains: { icon: "ph-grains", name: "Крупы, макароны и хлеб", keywords: ["рис", "гречк", "овсянк", "макарон", "паста", "хлеб", "лаваш", "булочк", "мука", "киноа", "булгур"] },
    other: { icon: "ph-shopping-bag", name: "Остальное (Бакалея, соусы)", keywords: [] }
};

function determineCategory(productName) {
    const lowerName = productName.toLowerCase();
    for (const [catKey, catData] of Object.entries(CATEGORY_MAP)) {
        if (catKey === 'other') continue;
        for (const kw of catData.keywords) {
            if (lowerName.includes(kw)) {
                return catKey;
            }
        }
    }
    return 'other';
}

function renderShoppingList(amountMultiplier = 7) {
    try {
        const planRaw = localStorage.getItem('aidiet_meal_plan');
        if (!planRaw) return;

        let plan = JSON.parse(planRaw); if (typeof plan === "string") plan = JSON.parse(plan);
        // Нормализация: поддержка вложенной структуры
        let d1 = plan.day_1;
        if (d1 && !Array.isArray(d1) && d1.meals) d1 = d1.meals;
        if (!d1 || !Array.isArray(d1) || d1.length === 0) return;

        // 1. Агрегация всех ингредиентов
        // Ключ: {имя}|{категория}|{юнит}
        const ingredientsMap = new Map();

        for (let i = 1; i <= amountMultiplier; i++) {
            const dayKey = `day_${i}`;
            let dayData = plan[dayKey];
            // Поддержка вложенной структуры {meals: [...]}
            if (dayData && !Array.isArray(dayData) && dayData.meals) dayData = dayData.meals;
            if (dayData && Array.isArray(dayData)) {
                dayData.forEach(meal => {
                    if (meal.ingredients && Array.isArray(meal.ingredients)) {
                        meal.ingredients.forEach(ing => {
                            const name = ing.name ? ing.name.trim() : "Неизвестный продукт";
                            
                            // Parse numeric amount
                            let baseAmount = parseFloat(ing.amount) || 0;
                            if (baseAmount === 0 && ing.amount) {
                                 // Fallback if AI returned string like "200г" in amount
                                 const match = String(ing.amount).match(/([\d\.]+)/);
                                 if (match) baseAmount = parseFloat(match[1]);
                            }
                            
                            // Парсим юнит
                            let unitStr = ing.unit ? ing.unit.trim() : "";
                            
                            const catKey = determineCategory(name);
                            const mapKey = `${name}::${catKey}::${unitStr}`;

                            if (ingredientsMap.has(mapKey)) {
                                ingredientsMap.set(mapKey, ingredientsMap.get(mapKey) + baseAmount);
                            } else {
                                ingredientsMap.set(mapKey, baseAmount);
                            }
                        });
                    }
                });
            }
        }

        // 2. Очистка UI от старых секций
        const contentContainer = document.querySelector('.content');
        const existingSections = document.querySelectorAll('.category-section');
        existingSections.forEach(sec => sec.remove());

        // 3. Группировка распарсенных ингредиентов по категориям
        const groupedData = {
            produce: [], meat_fish: [], dairy: [], grains: [], other: []
        };
        
        ingredientsMap.forEach((totalAmount, mapKey) => {
            const [name, catKey, unitStr] = mapKey.split("::");
            
            // Красивое форматирование: если вес в граммах и > 1000, переводим в кг
            let displayAmountStr = "";
            let displayUnit = unitStr;
            if (unitStr === "г" && totalAmount >= 1000) {
                totalAmount = totalAmount / 1000;
                displayUnit = "кг";
            }
            // Форматируем до 1 знака если нужно
            displayAmountStr = Number.isInteger(totalAmount) ? totalAmount.toString() : totalAmount.toFixed(1);
            if (displayUnit) displayAmountStr += ` ${displayUnit}`;
            
            if (groupedData[catKey]) {
                groupedData[catKey].push({ name, displayAmountStr });
            }
        });

        // 4. Отрисовка секций
        const summaryCard = document.querySelector('.summary-card');
        
        // Порядок вывода секций
        const orderedKeys = ["produce", "meat_fish", "dairy", "grains", "other"];
        
        orderedKeys.forEach(catKey => {
            if (groupedData[catKey].length > 0) {
                const secDef = CATEGORY_MAP[catKey];
                
                const section = document.createElement('section');
                section.className = 'category-section';
                section.innerHTML = `
                    <div class="category-header">
                        <i class="ph ${secDef.icon} category-icon"></i>
                        <span>${secDef.name}</span>
                    </div>
                    <div class="product-list"></div>
                `;
                
                const pList = section.querySelector('.product-list');
                
                groupedData[catKey].forEach(prod => {
                    const item = document.createElement('div');
                    item.className = 'product-item';
                    item.innerHTML = `
                        <div class="prod-left">
                            <div class="prod-checkbox"><i class="ph ph-check-bold"></i></div>
                            <span class="prod-name">${prod.name}</span>
                        </div>
                        <span class="prod-qty">${prod.displayAmountStr}</span>
                    `;
                    item.addEventListener('click', function() { this.classList.toggle('checked'); });
                    pList.appendChild(item);
                });
                
                if (summaryCard) {
                    contentContainer.insertBefore(section, summaryCard);
                } else {
                    contentContainer.appendChild(section);
                }
            }
        });

        // 5. Расчет цены-плейсхолдера
        const summaryVal = document.querySelector('.summary-val');
        if (summaryVal) {
            // Фейковый расчет цены (300 руб за каждый день * кол-во продуктов)
            const price = amountMultiplier * 350 + (groupedData.produce.length * 150);
            summaryVal.innerText = `~ ${price} ₽`;
        }

    } catch (e) {
        console.error("[Shopping State] Ошибка генерации списка покупок:", e);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const sub = localStorage.getItem('aidiet_subscription') || 'base';
    
    // 1. Инициализируем рендер со стартовым множителем
    // Если Base, изначально рендерим на 3 дня и переключаем тумблер визуально
    const periodToggles = document.querySelectorAll('.toggle-item');
    let currentMultiplier = sub === 'base' ? 3 : 7;
    
    if (sub === 'base' && periodToggles.length === 2) {
        periodToggles[0].classList.add('active'); // 3 дня
        periodToggles[1].classList.remove('active'); // 7 дней
        // Добавляем замочек для базового статуса
        periodToggles[1].innerHTML += ' <i class="ph-fill ph-lock-key"></i>';
        periodToggles[1].style.color = '#F5922B';
    }

    renderShoppingList(currentMultiplier);
    
    // 2. Навешиваем слушатели на переключатель периода
    if (periodToggles.length === 2) {
        periodToggles.forEach((t) => {
            t.addEventListener('click', (e) => {
                const isSevenDays = t.innerText.includes('неделю');
                
                if (isSevenDays && sub === 'base') {
                    // Status redirect
                    location.href = 'o17-statuswall.html';
                    return;
                }

                // Убираем у всех
                periodToggles.forEach(tt => tt.classList.remove('active'));
                // Добавляем текущему
                t.classList.add('active');
                
                if (isSevenDays) {
                    currentMultiplier = 7;
                } else {
                    currentMultiplier = 3;
                }
                renderShoppingList(currentMultiplier);
            });
        });
    }
});
