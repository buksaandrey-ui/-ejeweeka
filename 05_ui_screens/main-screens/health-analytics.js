// health-analytics.js
// Расчет и рендер Индекса Здоровья (PR-1 Health Score) и параметров Прогресса

document.addEventListener('DOMContentLoaded', () => {
    try {
        const isHealthPage = window.location.pathname.includes('health-score');
        const isProgressPage = window.location.pathname.includes('progress');

        const profileRaw = localStorage.getItem('aidiet_profile');
        const profile = profileRaw ? JSON.parse(profileRaw) : null;
        
        const waterRaw = localStorage.getItem('aidiet_water_log');
        const waterLog = waterRaw ? JSON.parse(waterRaw) : { val: 0, target: 2000 };

        // Базовые расчеты (Mock AI Algorithm)
        let bmiScore = 85; 
        if (profile && profile['Текущий вес'] && profile['Рост']) {
            const hRaw = parseFloat(profile['Рост']) / 100;
            const wRaw = parseFloat(profile['Текущий вес']);
            const bmi = wRaw / (hRaw * hRaw);
            // Если ИМТ 22 - идеал (100). Отклонение штрафуется
            const diff = Math.abs(bmi - 22);
            bmiScore = Math.max(10, 100 - (diff * 5));
        }

        let waterScore = Math.min(100, Math.round((waterLog.val / waterLog.target) * 100));
        let activityScore = 60; // Mock 
        let sleepScore = 80;    // Mock

        // Влияние напитков (AI Penalty для алкоголя и сахара)
        let drinkPenalty = 0;
        const drinksRaw = localStorage.getItem('aidiet_drink_logs');
        if (drinksRaw) {
            const drinks = JSON.parse(drinksRaw);
            drinks.forEach(d => {
                if (d.abv > 0) {
                    // Формула: Объем * Крепость / 100 (мл чистого спирта)
                    const pureAlcohol = (d.volume * d.abv) / 100;
                    drinkPenalty += (pureAlcohol / 5); // Каждые 5мл чистого спирта = -1 балл
                } else {
                    // Сладкие напитки (Mock detection по имени)
                    const sugaryNames = ['кола', 'cola', 'сок', 'juice', 'компот', 'лимонад'];
                    if (sugaryNames.some(n => d.name.toLowerCase().includes(n))) {
                        drinkPenalty += 2; // -2 балла за сладкий напиток
                    }
                }
            });
        }

        let overallScore = Math.round((bmiScore * 1.5 + waterScore + activityScore + sleepScore - drinkPenalty) / 4.5);
        overallScore = Math.max(10, Math.min(100, overallScore));

        // --- ЛОГИКА ДЛЯ ЭКРАНА HEALTH SCORE ---
        if (isHealthPage) {
            const valEl = document.querySelector('.score-val');
            if (valEl) valEl.innerText = overallScore;

            // Рендер кольца
            const circle = document.querySelector('.score-svg circle:nth-child(2)');
            if (circle) {
                // 339.29 - полная окружность.
                const offset = 339.29 - (339.29 * (overallScore / 100));
                circle.style.strokeDashoffset = offset;
                circle.style.stroke = overallScore >= 80 ? 'var(--color-success)' : overallScore >= 60 ? 'var(--color-warning)' : 'var(--color-danger)';
            }

            // Рендер шкал (надо обновить innerText и width)
            // В HTML захардкожены 6 шкал: ИМТ, Талия, Питание, Вода, Актив, Сон
            const scComp = document.querySelectorAll('.comp-score');
            const bars = document.querySelectorAll('.comp-fill');
            
            if (scComp.length >= 6) {
                // ИМТ
                scComp[0].innerText = `${Math.round(bmiScore)}/100`;
                bars[0].style.width = `${Math.round(bmiScore)}%`;

                // Талия (Mock)
                scComp[1].innerText = `70/100`;
                bars[1].style.width = `70%`;

                // Питание (Mock)
                scComp[2].innerText = `90/100`;
                bars[2].style.width = `90%`;

                // Вода
                scComp[3].innerText = `${waterScore}/100`;
                bars[3].style.width = `${waterScore}%`;
                bars[3].style.backgroundColor = waterScore < 60 ? 'var(--color-warning)' : 'var(--color-success)';

                // Актив
                scComp[4].innerText = `${activityScore}/100`;
                bars[4].style.width = `${activityScore}%`;

                // Сон
                scComp[5].innerText = `${sleepScore}/100`;
                bars[5].style.width = `${sleepScore}%`;
            }
        }

        // --- ЛОГИКА ДЛЯ ЭКРАНА PROGRESS ---
        if (isProgressPage) {
            const weightMeta = document.querySelector('.card-meta');
            if (weightMeta && profile && profile['Текущий вес']) {
                weightMeta.innerText = profile['Текущий вес'] + ' кг';
            }
            // Генерация графиков в pr1-progress (если нужно)
        }

    } catch(e) {
        console.error("Health Analytics Error:", e);
    }
});
