// status-wall.js
// Логика блокировки премиум-фичей

const TIERS = {
    'base': 0,
    'black': 1,
    'gold': 2,
    'gold_trial': 2 // Триал приравниваем к gold
};

function getCurrentTier() {
    return localStorage.getItem('aidiet_subscription') || 'base';
}

function hasAccess(requiredLevel) {
    const current = getCurrentTier();
    return TIERS[current] >= TIERS[requiredLevel];
}

/**
 * Проверка доступа к странице с блокировкой.
 * Показывает TG Bridge Modal вместо редиректа на статус экран.
 */
function requireAccessRedirect(requiredLevel, featureName) {
    if (!hasAccess(requiredLevel)) {
        if (window.TGBridge) {
            window.TGBridge.show(featureName);
        } else {
            let targetTier = requiredLevel.charAt(0).toUpperCase() + requiredLevel.slice(1);
            let msg = featureName
                ? `${featureName} доступно при статусе ${targetTier}. Управляй статусом через Telegram-ассистент Health Code.`
                : `Эта функция доступна при статусе ${targetTier}`;
            alert(msg);
        }
    }
}

/**
 * Накладывает визуальный замок на HTML элемент.
 * При клике — открывает TG Bridge Modal.
 */
function applyLockOverlay(elementSelector, requiredLevelName) {
    const el = document.querySelector(elementSelector);
    if (!el) return;
    
    if (!hasAccess(requiredLevelName)) {
        el.style.position = 'relative';
        el.style.overflow = 'hidden';
        
        // Размываем содержимое
        const children = el.children;
        for (let i=0; i<children.length; i++) {
            children[i].style.filter = 'blur(6px)';
            children[i].style.pointerEvents = 'none';
            children[i].style.userSelect = 'none';
        }
        
        // Создаем оверлей с замком
        const overlay = document.createElement('div');
        overlay.style.position = 'absolute';
        overlay.style.top = '0';
        overlay.style.left = '0';
        overlay.style.right = '0';
        overlay.style.bottom = '0';
        overlay.style.background = 'rgba(255,255,255,0.4)';
        overlay.style.display = 'flex';
        overlay.style.flexDirection = 'column';
        overlay.style.alignItems = 'center';
        overlay.style.justifyContent = 'center';
        overlay.style.zIndex = '10';
        overlay.style.padding = '20px';
        overlay.style.textAlign = 'center';
        
        let targetTierLabel = 'Black';
        let iconHtml = '<i class="ph ph-shield-check" style="font-size:32px; color:#1A1A1A;"></i>';
        
        if (requiredLevelName === 'gold') {
            targetTierLabel = 'Gold';
            iconHtml = '<i class="ph ph-crown" style="font-size:32px; color:#F5922B;"></i>';
        }

        overlay.innerHTML = `
            <div style="background:#fff; border:1px solid #E5E7EB; border-radius:16px; padding:20px; box-shadow:0 10px 25px rgba(0,0,0,0.1); width:100%; max-width:280px;">
                ${iconHtml}
                <div style="font-size:16px; font-weight:700; color:#1A1A1A; margin-top:12px;">Доступно при статусе ${targetTierLabel}</div>
                <div style="font-size:12px; color:#6B7280; font-weight:500; margin-top:6px; margin-bottom:16px;">
                    Управляй статусом через Telegram-ассистент
                </div>
                <button onclick="if(window.TGBridge){TGBridge.show()}else{window.location.href='o17-statuswall.html'}" style="width:100%; padding:14px; background:linear-gradient(135deg, #2AABEE, #229ED9); color:#fff; border:none; border-radius:12px; font-weight:700; cursor:pointer; display:flex; align-items:center; justify-content:center; gap:6px;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M20.665 3.717l-17.73 6.837c-1.21.486-1.203 1.161-.222 1.462l4.552 1.42 10.532-6.645c.498-.303.953-.14.579.192l-8.533 7.701h-.002l.002.001-.314 4.692c.46 0 .663-.211.921-.46l2.211-2.15 4.599 3.397c.848.467 1.457.227 1.668-.787l3.019-14.228c.309-1.239-.473-1.8-1.282-1.432z" fill="white"/></svg>
                    Открыть Telegram
                </button>
            </div>
        `;
        
        el.appendChild(overlay);
    }
}
