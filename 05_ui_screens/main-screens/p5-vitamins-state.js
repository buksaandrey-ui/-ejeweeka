// p5-vitamins-state.js
// Гидратация экрана P-5 (Витамины и лекарства) из aidiet_meal_plan + aidiet_profile
//
// Источники данных:
// 1. aidiet_meal_plan → vitamins[] массив из текущего дня плана
// 2. aidiet_profile['БАД'] → пользовательские добавки
// 3. aidiet_profile['Принимает лекарства'] → лекарства
//
// Если план содержит витамины в структуре:
//   { vitamins: [ { name: "Vitamin D3", dosage: "2000 ME", time: "morning", note: "После еды" } ] }
// Иначе — показываем базовый набор на основе профиля.

document.addEventListener('DOMContentLoaded', () => {
    try {
        const planRaw = localStorage.getItem('aidiet_meal_plan');
        const profileRaw = localStorage.getItem('aidiet_profile');
        const profile = profileRaw ? JSON.parse(profileRaw) : {};
        
        let vitamins = [];
        let medications = [];
        let warnings = [];
        
        // 1. Попытка извлечь витамины из плана
        if (planRaw) {
            let plan = JSON.parse(planRaw); if (typeof plan === "string") plan = JSON.parse(plan);
            
            // Ищем витамины в разных местах структуры плана
            if (plan.vitamins && Array.isArray(plan.vitamins)) {
                vitamins = plan.vitamins;
            } else if (plan.vitamin_schedule && Array.isArray(plan.vitamin_schedule)) {
                vitamins = plan.vitamin_schedule;
            } else {
                // Определяем текущий день недели
                const dow = new Date().getDay();
                const dayIdx = dow === 0 ? 7 : dow;
                
                // Проверяем нормализованный ключ vitamins_day_N
                const vitKey = `vitamins_day_${dayIdx}`;
                if (plan[vitKey] && Array.isArray(plan[vitKey])) {
                    vitamins = plan[vitKey].map(v => ({
                        name: v.name,
                        dosage: v.dose || v.dosage || '',
                        time: (v.when || 'morning').toLowerCase().includes('завтрак') ? 'morning' 
                            : (v.when || '').toLowerCase().includes('обед') ? 'lunch' 
                            : (v.when || '').toLowerCase().includes('вечер') || (v.when || '').toLowerCase().includes('сон') ? 'evening' 
                            : 'morning',
                        note: v.why || v.note || ''
                    }));
                }
                
                // Fallback: ищем в day_1 (вложенная структура)
                if (vitamins.length === 0) {
                    const day1 = plan.day_1;
                    if (day1 && !Array.isArray(day1) && day1.vitamins) {
                        // Новый формат: day_1: { meals: [...], vitamins: [...] }
                        vitamins = (day1.vitamins || []).map(v => ({
                            name: v.name,
                            dosage: v.dose || v.dosage || '',
                            time: (v.when || 'morning').toLowerCase().includes('завтрак') ? 'morning'
                                : (v.when || '').toLowerCase().includes('обед') ? 'lunch'
                                : (v.when || '').toLowerCase().includes('вечер') || (v.when || '').toLowerCase().includes('сон') ? 'evening'
                                : 'morning',
                            note: v.why || v.note || ''
                        }));
                    } else if (day1 && Array.isArray(day1)) {
                        // Старый формат: витамины внутри meals
                        day1.forEach(meal => {
                            if (meal.vitamins && Array.isArray(meal.vitamins)) {
                                vitamins = vitamins.concat(meal.vitamins);
                            }
                        });
                    }
                }
            }
            
            // Совместимость
            if (plan.vitamin_warnings && Array.isArray(plan.vitamin_warnings)) {
                warnings = plan.vitamin_warnings;
            }
        }
        
        // 2. Извлечь лекарства из профиля
        const medsText = profile['Принимает лекарства'] || '';
        if (medsText && medsText !== 'Нет') {
            medsText.split(',').map(s => s.trim()).filter(Boolean).forEach(med => {
                medications.push({
                    name: med,
                    dosage: '',
                    time: 'morning',
                    note: 'По назначению врача'
                });
            });
        }
        
        // 3. Извлечь БАДы из профиля (если нет данных из плана)
        if (vitamins.length === 0) {
            const bads = profile['БАД'] || '';
            if (bads && bads !== 'Нет') {
                bads.split(',').map(s => s.trim()).filter(Boolean).forEach(supp => {
                    vitamins.push({
                        name: supp,
                        dosage: '',
                        time: 'morning',
                        note: ''
                    });
                });
            }
        }
        
        // Если нет данных — оставляем хардкоженный UI как есть
        if (vitamins.length === 0 && medications.length === 0) {
            console.log('[P5 State] Нет витаминов в плане или профиле, используем дефолт');
            initCheckboxes();
            return;
        }
        
        // 4. Рендер
        const content = document.querySelector('.content');
        if (!content) return;
        
        // Очищаем хардкоженные секции
        const existingBlocks = content.querySelectorAll('.time-block, .warning-card');
        existingBlocks.forEach(el => el.remove());
        
        // Рендерим предупреждения
        if (warnings.length > 0) {
            warnings.forEach(w => {
                const warningEl = document.createElement('section');
                warningEl.className = 'warning-card';
                warningEl.innerHTML = `
                    <div class="warning-icon"><i class="ph ph-warning-circle"></i></div>
                    <div class="warning-content">
                        <div class="warning-title">Совместимость</div>
                        <div class="warning-text">${w.text || w}</div>
                    </div>
                `;
                content.insertBefore(warningEl, content.firstChild);
            });
        }
        
        // Группировка по времени
        const timeGroups = {
            morning: { label: 'Утро (с завтраком)', icon: 'ph-sun', items: [] },
            lunch:   { label: 'День (с обедом)', icon: 'ph-cloud-sun', items: [] },
            evening: { label: 'Вечер (перед сном)', icon: 'ph-moon', items: [] }
        };
        
        const timeMap = {
            'morning': 'morning', 'утро': 'morning', 'завтрак': 'morning',
            'lunch': 'lunch', 'день': 'lunch', 'обед': 'lunch',
            'evening': 'evening', 'вечер': 'evening', 'сон': 'evening', 'ночь': 'evening'
        };
        
        vitamins.forEach(v => {
            const timeKey = timeMap[(v.time || 'morning').toLowerCase()] || 'morning';
            timeGroups[timeKey].items.push({ ...v, isMed: false });
        });
        
        medications.forEach(m => {
            const timeKey = timeMap[(m.time || 'morning').toLowerCase()] || 'morning';
            timeGroups[timeKey].items.push({ ...m, isMed: true });
        });
        
        // Рендерим секции
        Object.entries(timeGroups).forEach(([key, group]) => {
            if (group.items.length === 0) return;
            
            const section = document.createElement('section');
            section.className = 'time-block';
            
            let cardsHTML = '';
            group.items.forEach(item => {
                const iconClass = item.isMed ? 'med-icon' : 'pill-icon';
                const iconInner = item.isMed 
                    ? '<i class="ph ph-first-aid"></i>' 
                    : '<i class="ph ph-pill"></i>';
                const cardClass = item.isMed ? 'pill-card med' : 'pill-card';
                const desc = [item.dosage, item.note].filter(Boolean).join(' • ') || 'По расписанию';
                
                cardsHTML += `
                    <div class="${cardClass}">
                        <div class="${iconClass}">${iconInner}</div>
                        <div class="pill-info">
                            <div class="pill-name">${item.name}</div>
                            <div class="pill-desc">${desc}</div>
                        </div>
                        <div class="pill-check"><i class="ph ph-check"></i></div>
                    </div>
                `;
            });
            
            section.innerHTML = `
                <h2 class="section-title"><i class="ph ${group.icon}"></i> ${group.label}</h2>
                ${cardsHTML}
            `;
            
            content.appendChild(section);
        });
        
        // 5. Инициализация чекбоксов
        initCheckboxes();
        
        console.log(`[P5 State] Загружено: ${vitamins.length} витаминов, ${medications.length} лекарств`);
        
    } catch (e) {
        console.error('[P5 State] Ошибка:', e);
        initCheckboxes();
    }
});

function initCheckboxes() {
    // Клик по карточке витамина = чекбокс "принято"
    document.querySelectorAll('.pill-card').forEach(card => {
        card.addEventListener('click', () => {
            card.classList.toggle('taken');
            
            // Сохраняем состояние в localStorage
            const today = new Date().toISOString().split('T')[0];
            const name = card.querySelector('.pill-name')?.innerText;
            if (name) {
                const logKey = 'aidiet_vitamin_log';
                const log = JSON.parse(localStorage.getItem(logKey) || '{}');
                if (!log[today]) log[today] = {};
                log[today][name] = card.classList.contains('taken');
                localStorage.setItem(logKey, JSON.stringify(log));
            }
        });
        
        // Восстановление состояния
        const today = new Date().toISOString().split('T')[0];
        const name = card.querySelector('.pill-name')?.innerText;
        if (name) {
            const log = JSON.parse(localStorage.getItem('aidiet_vitamin_log') || '{}');
            if (log[today]?.[name]) {
                card.classList.add('taken');
            }
        }
    });
}
