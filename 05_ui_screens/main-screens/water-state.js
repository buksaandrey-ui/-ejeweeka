// water-state.js

document.addEventListener('DOMContentLoaded', () => {
    // 1. Читаем профиль и определяем норму
    const profileRaw = localStorage.getItem('aidiet_profile');
    let targetLiters = 2.5; // База
    
    if (profileRaw) {
        try {
            const profile = JSON.parse(profileRaw);
            const weight = parseFloat(profile['Текущий вес']) || 70;
            targetLiters = (weight * 30) / 1000; // ВОЗ: 30мл на кг веса
            
            // Округляем до 0.1
            targetLiters = Math.round(targetLiters * 10) / 10;
        } catch(e) {}
    }

    // 2. Читаем текущий лог воды
    const todayStr = new Date().toISOString().split('T')[0];
    let waterLog = {};
    const logRaw = localStorage.getItem('aidiet_water_log');
    if (logRaw) {
        try {
            waterLog = JSON.parse(logRaw);
        } catch(e) {}
    }
    
    // Инициализация сегодняшнего дня, если нет
    if (!waterLog[todayStr]) {
        waterLog[todayStr] = 0; // в мл
    }
    
    let TARGET_ML = targetLiters * 1000;

    // 3. UI Элементы
    const ringSvgCircle = document.querySelector('.ring-svg circle:nth-child(2)');
    const ringValEl = document.querySelector('.ring-val');
    const ringLabelEl = document.querySelector('.ring-label');
    const ringPercentEl = document.querySelector('.ring-percent');
    const settingValEl = document.querySelector('.setting-val');
    const sliderEl = document.querySelector('.slider');
    
    // 4. Функция рендера
    function renderWater() {
        const currentMl = waterLog[todayStr];
        const percent = Math.min((currentMl / TARGET_ML) * 100, 100);
        
        // Математика SVG Circle 
        const circumference = 339.29; // для радиуса 54
        const offset = circumference - (percent / 100) * circumference;
        
        if (ringSvgCircle) ringSvgCircle.style.strokeDashoffset = offset;
        
        if (ringValEl) ringValEl.innerText = `${(currentMl / 1000).toFixed(1)} л`;
        if (ringLabelEl) ringLabelEl.innerText = `из ${targetLiters.toFixed(1)} л`;
        if (ringPercentEl) ringPercentEl.innerText = `${Math.round(percent)}%`;
        
        if (settingValEl) settingValEl.innerText = `${targetLiters.toFixed(1)} л`;
        if (sliderEl) sliderEl.value = targetLiters;
    }

    // Первичный рендер
    renderWater();

    // 5. Обработчики кнопок
    const addButtons = document.querySelectorAll('.add-btn');
    addButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const label = btn.querySelector('.add-btn-label').innerText;
            let addedMl = 0;
            
            if (label.includes('150')) addedMl = 150;
            else if (label.includes('250')) addedMl = 250;
            else if (label.includes('500')) addedMl = 500;
            else if (label.includes('Свой')) {
                const userVal = prompt('Введите объем в меллилитрах (например, 300):');
                addedMl = parseInt(userVal) || 0;
            }
            
            if (addedMl > 0) {
                waterLog[todayStr] += addedMl;
                localStorage.setItem('aidiet_water_log', JSON.stringify(waterLog));
                renderWater();
                // Эффект пружинки CSS
                ringValEl.style.transform = 'scale(1.1)';
                setTimeout(() => ringValEl.style.transform = 'scale(1)', 200);
            }
        });
    });

    // 6. Слайдер цели
    if (sliderEl) {
        sliderEl.addEventListener('change', (e) => {
            targetLiters = parseFloat(e.target.value);
            TARGET_ML = targetLiters * 1000;
            renderWater();
        });
    }
});
