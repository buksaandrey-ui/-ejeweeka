// weight-state.js

document.addEventListener('DOMContentLoaded', () => {
    const profile = (window.AIDiet && window.AIDiet.getProfile)
        ? window.AIDiet.getProfile()
        : JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
    let startWeight = 75.0; // Дефолт
    let goalWeight = 65.0;
    
    if (profile['Текущий вес']) startWeight = parseFloat(profile['Текущий вес']);
    if (profile['Целевой вес']) goalWeight = parseFloat(profile['Целевой вес']);

    // 2. Инициализируем или загружаем лог
    const todayStr = new Date().toISOString().split('T')[0];
    let weightLog = [];
    const logRaw = localStorage.getItem('aidiet_weight_log');
    if (logRaw) {
        try {
            weightLog = JSON.parse(logRaw);
            // Если массив, все ок.
        } catch(e) {}
    }
    
    if (weightLog.length === 0) {
        // Создадим дефолтную запись со стартовым весом
        weightLog.push({ date: todayStr, weight: startWeight });
        localStorage.setItem('aidiet_weight_log', JSON.stringify(weightLog));
    }
    
    // Сортируем записи по новизне
    weightLog.sort((a, b) => new Date(b.date) - new Date(a.date));

    // 3. UI элементы
    const bigNumberEl = document.querySelector('.big-number');
    const deltaEl = document.querySelector('.delta');
    const goalTextEl = document.querySelector('.goal-text');
    const historyList = document.querySelector('.history-list');
    const fabBtn = document.querySelector('.fab');

    function renderWeight() {
        const currentWeight = weightLog[0].weight;
        const delta = currentWeight - startWeight;
        
        // Рендерим шапку
        if (bigNumberEl) bigNumberEl.innerText = currentWeight.toFixed(1);
        if (goalTextEl) goalTextEl.innerText = `Цель: ${goalWeight} кг`;
        
        if (deltaEl) {
            deltaEl.className = 'delta'; // Сбрасываем
            if (delta > 0) {
                deltaEl.classList.add('up');
                deltaEl.innerHTML = `<i class="ph ph-arrow-up"></i> +${delta.toFixed(1)} кг от старта`;
            } else if (delta < 0) {
                deltaEl.classList.add('down');
                deltaEl.innerHTML = `<i class="ph ph-arrow-down"></i> ${delta.toFixed(1)} кг от старта`;
            } else {
                deltaEl.innerHTML = `— вес не изменился`;
            }
        }
        
        // Рендерим историю
        if (historyList) {
            historyList.innerHTML = ''; // Чистим
            for (let i = 0; i < weightLog.length; i++) {
                const entry = weightLog[i];
                const d = new Date(entry.date);
                const dateStr = d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' }); // "17 апреля"
                
                let deltaHtml = '';
                if (i < weightLog.length - 1) {
                    const prevEntry = weightLog[i+1];
                    const diff = entry.weight - prevEntry.weight;
                    if (diff > 0) deltaHtml = `<span class="history-delta pos">+${diff.toFixed(1)}</span>`;
                    else if (diff < 0) deltaHtml = `<span class="history-delta neg">${diff.toFixed(1)}</span>`;
                    else deltaHtml = `<span class="history-delta">0.0</span>`;
                }

                historyList.innerHTML += `
                    <div class="history-item">
                        <span class="history-date">${dateStr}</span>
                        <span class="history-val">${entry.weight.toFixed(1)} кг</span>
                        ${deltaHtml}
                    </div>
                `;
            }
        }
    }
    
    renderWeight();

    // 4. Добавление нового веса через FAB
    if (fabBtn) {
        fabBtn.addEventListener('click', () => {
            const currentWeight = weightLog[0].weight;
            const userVal = prompt('Укажи текущий вес (кг):', currentWeight);
            if (!userVal) return;
            
            const newWeight = parseFloat(userVal.replace(',', '.'));
            if (isNaN(newWeight) || newWeight < 30 || newWeight > 300) {
                alert('Укажи корректный вес (от 30 до 300 кг).');
                return;
            }
            
            // Проверяем, есть ли уже запись за сегодня
            const todayStrLocal = new Date().toLocaleDateString('ru-RU');
            const newDateStr = new Date().toISOString(); 
            
            // Чтобы упростить, всегда пишем новую запись (как новое взвешивание)
            weightLog.unshift({ date: newDateStr, weight: newWeight });
            localStorage.setItem('aidiet_weight_log', JSON.stringify(weightLog));
            
            renderWeight();
            
            // Обновляем профиль (чтобы дашборды и расчеты БЖУ подхватили новый вес)
            if (window.AIDiet && window.AIDiet.saveField) {
                window.AIDiet.saveField('weight_kg', String(newWeight));
            }
        });
    }
});
