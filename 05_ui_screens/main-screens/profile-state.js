// profile-state.js
// Скрипт гидратации экрана профиля (U-1) данными из кэша

document.addEventListener('DOMContentLoaded', () => {
    try {
        // 1. Обновление Имени
        const profile = (window.AIDiet && window.AIDiet.getProfile)
            ? window.AIDiet.getProfile()
            : JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
        const userNameEl = document.querySelector('.user-name');
        if (userNameEl) {
            userNameEl.innerText = profile['Имя'] || "Пользователь";
        }

        // 2. Обновление текущего Статуса
        const sub = localStorage.getItem('aidiet_subscription') || 'base';
        const planBadgeEl = document.querySelector('.plan-badge');

        if (planBadgeEl) {
            if (sub === 'gold_trial') {
                planBadgeEl.innerHTML = '<i class="ph ph-crown-fill"></i> Gold Триал';
                planBadgeEl.style.color = '#CC7000';
                planBadgeEl.style.background = '#FFF7ED';
            } else if (sub === 'gold') {
                planBadgeEl.innerHTML = '<i class="ph ph-crown-fill"></i> Gold План';
                planBadgeEl.style.color = '#CC7000';
                planBadgeEl.style.background = '#FFF7ED';
            } else if (sub === 'black') {
                planBadgeEl.innerHTML = '<i class="ph ph-shield-check-fill"></i> Black План';
                planBadgeEl.style.color = '#FFFFFF';
                planBadgeEl.style.background = '#1A1A1A';
            } else {
                // Base
                planBadgeEl.innerHTML = '<i class="ph ph-leaf-fill"></i> Base План';
                planBadgeEl.style.color = '#15803D';
                planBadgeEl.style.background = '#F0FDF4';
            }
        }

        console.log("[Profile State] Профиль успешно загружен");

    } catch (e) {
        console.error("[Profile State] Ошибка загрузки профиля:", e);
    }
});
