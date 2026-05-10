// shopping-cart-state.js
// Дополнительная логика списка покупок (S-1)
// Основной UI-рендер — в shopping-state.js

document.addEventListener('DOMContentLoaded', () => {
    try {
        // Кнопка "Поделиться" (Share API)
        const shareBtn = document.querySelector('.btn-share');
        if (shareBtn) {
            shareBtn.addEventListener('click', async () => {
                // Собираем текст списка из DOM
                const items = [];
                document.querySelectorAll('.product-item:not(.checked)').forEach(item => {
                    const name = item.querySelector('.prod-name')?.innerText || '';
                    const qty = item.querySelector('.prod-qty')?.innerText || '';
                    if (name) items.push(`☐ ${name} — ${qty}`);
                });
                const text = '🛒 Мой список покупок (Health Code):\n\n' + items.join('\n');
                
                if (navigator.share) {
                    await navigator.share({ title: 'Health Code — Покупки', text });
                } else {
                    await navigator.clipboard.writeText(text);
                    alert('Список скопирован в буфер обмена!');
                }
            });
        }

        // Кнопка "Заказать всё" — placeholder
        const buyBtn = document.querySelector('.btn-buy');
        if (buyBtn) {
            buyBtn.addEventListener('click', () => {
                alert('Интеграция с сервисами доставки в разработке.');
            });
        }

    } catch (e) {
        console.error("Ошибка корзины:", e);
    }
});
