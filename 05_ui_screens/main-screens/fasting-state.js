// fasting-state.js
// Скрипт таймера и фаз голодания

document.addEventListener('DOMContentLoaded', () => {
    try {
        const DOM = {
            btnToggle: document.getElementById('btnToggleFast'),
            ringProgress: document.querySelector('.ring-progress'),
            ringGlow: document.querySelector('.ring-glow'),
            timerValue: document.querySelector('.timer-value'),
            timerStatus: document.querySelector('.timer-status'),
            timerEnd: document.querySelector('.timer-end'),
            phases: {
                sugar: document.getElementById('phase-sugar'),
                fat: document.getElementById('phase-fat'),
                auto: document.getElementById('phase-auto')
            }
        };

        if (!DOM.btnToggle || !DOM.ringProgress) return;

        // Константы
        const TOTAL_DASH = 653; // Длина окружности SVG (r=104)
        const GOAL_HOURS = 16;
        const GOAL_MS = GOAL_HOURS * 3600000;

        let intervalId = null;

        // Данные стейта
        let fastingState = JSON.parse(localStorage.getItem('aidiet_fasting')) || {
            isActive: true, // Для MVP стартуем как активное
            startTime: new Date(Date.now() - (4.5 * 3600000)).toISOString() // Имитируем 4.5 часа голодания
        };
        localStorage.setItem('aidiet_fasting', JSON.stringify(fastingState));

        const updateUI = () => {
            if (!fastingState.isActive) {
                DOM.timerStatus.innerText = 'Окно питания';
                DOM.timerStatus.style.color = 'var(--color-eating)';
                DOM.timerValue.innerText = '--:--:--';
                DOM.timerEnd.innerText = 'Нажмите старт, чтобы начать';
                DOM.ringProgress.style.strokeDashoffset = TOTAL_DASH;
                DOM.ringProgress.style.stroke = 'var(--color-eating)';
                if(DOM.ringGlow) DOM.ringGlow.style.stroke = 'var(--color-eating)';
                
                DOM.btnToggle.innerText = 'Начать голодание';
                DOM.btnToggle.className = 'btn-main btn-start';
                DOM.btnToggle.style.display = 'flex';
                
                // Сброс фаз
                Object.values(DOM.phases).forEach(el => {
                    el.classList.remove('active');
                    const fill = el.querySelector('.phase-progress');
                    if (fill) fill.style.width = '0%';
                });

                clearInterval(intervalId);
                return;
            }

            // Активное голодание
            DOM.btnToggle.innerText = 'Завершить досрочно';
            DOM.btnToggle.className = 'btn-main btn-end';
            DOM.btnToggle.style.display = 'flex';

            const start = new Date(fastingState.startTime);
            const now = new Date();
            const elapsed = now - start;

            // Расчет времени
            let remaining = GOAL_MS - elapsed;
            let isOvertime = false;
            if (remaining < 0) {
                isOvertime = true;
                remaining = Math.abs(remaining);
                DOM.timerStatus.innerText = 'Сверх цели';
                DOM.timerStatus.style.color = 'var(--color-autophagy)';
                DOM.ringProgress.style.stroke = 'var(--color-autophagy)';
                if(DOM.ringGlow) DOM.ringGlow.style.stroke = 'var(--color-autophagy)';
            } else {
                DOM.timerStatus.innerText = 'Голодание';
                DOM.timerStatus.style.color = 'var(--color-text-secondary)';
                DOM.ringProgress.style.stroke = 'var(--color-fasting)';
                if(DOM.ringGlow) DOM.ringGlow.style.stroke = 'var(--color-fasting)';
            }

            // Форматирование часов : минут : секунд
            const h = Math.floor(remaining / 3600000);
            const m = Math.floor((remaining % 3600000) / 60000);
            const s = Math.floor((remaining % 60000) / 1000);
            
            DOM.timerValue.innerText = `${isOvertime ? '+' : ''}${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;

            // Рассчет кольца (от 0 до 100% == от 653 до 0)
            let percent = Math.min(elapsed / GOAL_MS, 1);
            let offset = TOTAL_DASH - (TOTAL_DASH * percent);
            DOM.ringProgress.style.strokeDashoffset = offset;
            if (isOvertime) DOM.ringProgress.style.strokeDashoffset = 0; // Полный круг

            // Фазы
            const elapsedHours = elapsed / 3600000;
            
            // 1. Падение сахара (2 - 12 часов)
            if (elapsedHours >= 2) {
                DOM.phases.sugar.classList.add('active');
                let p = Math.min(((elapsedHours - 2) / 10) * 100, 100);
                DOM.phases.sugar.querySelector('.phase-progress').style.width = p + '%';
            }
            
            // 2. Сжигание жира (12 - 16 часов)
            if (elapsedHours >= 12) {
                DOM.phases.fat.classList.add('active');
                let p = Math.min(((elapsedHours - 12) / 4) * 100, 100);
                DOM.phases.fat.querySelector('.phase-progress').style.width = p + '%';
            }

            // 3. Аутофагия (16+ часов)
            if (elapsedHours >= 16) {
                DOM.phases.auto.classList.add('active');
                let p = Math.min(((elapsedHours - 16) / 8) * 100, 100); // демо макс на сутки
                DOM.phases.auto.querySelector('.phase-progress').style.width = p + '%';
            }
        };

        const loop = () => {
            updateUI();
            intervalId = setInterval(updateUI, 1000);
        };

        DOM.btnToggle.addEventListener('click', () => {
            if (fastingState.isActive) {
                // Завершение
                if(confirm("Уверен(а), что хочешь прервать голодание?")) {
                    fastingState.isActive = false;
                    localStorage.setItem('aidiet_fasting', JSON.stringify(fastingState));
                    loop();
                }
            } else {
                // Старт
                fastingState.isActive = true;
                fastingState.startTime = new Date().toISOString();
                localStorage.setItem('aidiet_fasting', JSON.stringify(fastingState));
                loop();
            }
        });

        // Запуск
        loop();

    } catch (e) {
        console.error("Ошибка в трекере голодания:", e);
    }
});
