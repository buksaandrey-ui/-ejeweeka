// chat-engine.js
// Логика работы AI-чата C-1
// ВАЖНО: Ответы должны генерироваться ИСКЛЮЧИТЕЛЬНО на основе RAG-базы знаний врачей (4000+ материалов).
// Использование внешних LLM-весов без контекста из базы знаний запрещено.

document.addEventListener('DOMContentLoaded', () => {
    try {
        const inputField = document.getElementById('chatInput');
        const btnSend = document.getElementById('btnSend');
        const chatArea = document.getElementById('chatArea');
        const typingIndicator = document.getElementById('typingIndicator');
        const suggestionsArea = document.getElementById('suggestionsArea');
        const suggestionChips = document.querySelectorAll('.suggestion-chip');

        const nowHtml = () => {
            const d = new Date();
            const hs = d.getHours().toString().padStart(2,'0');
            const ms = d.getMinutes().toString().padStart(2,'0');
            return `<div class="msg-time">${hs}:${ms}</div>`;
        };

        const appendUserMsg = (text) => {
            const div = document.createElement('div');
            div.className = 'message user';
            div.innerHTML = `<div class="bubble">${text}</div>` + nowHtml();
            chatArea.insertBefore(div, typingIndicator);
            scrollToBottom();
            
            // Если задан вопрос - прячем чипсы 
            if(suggestionsArea) suggestionsArea.style.display = 'none';
        };

        const appendAiMsg = (text) => {
            const div = document.createElement('div');
            div.className = 'message ai';
            div.innerHTML = `<div class="bubble">${text}</div>` + nowHtml();
            chatArea.insertBefore(div, typingIndicator);
            scrollToBottom();
        };

        const scrollToBottom = () => {
            chatArea.scrollTop = chatArea.scrollHeight;
        };

        const generateAiResponse = (userText) => {
            const lower = userText.toLowerCase();
            if (lower.includes('улучшить сон') || lower.includes('сон')) {
                return "Твой Score по сну сейчас 80/100. Это хороший показатель! Но AI рекомендует снизить температуру в спальне на 2 градуса и отказаться от смартфона за час до сна. Также я добавил магний в твой утренний список БАДов.";
            } else if (lower.includes('score упал') || lower.includes('упал')) {
                return "Аналитика показывает дефицит воды (ты выпил 55% от нормы). Это замедляет метаболизм. Попробуй выпивать стакан воды за 30 минут до каждого приема пищи!";
            } else if (lower.includes('ужин') || lower.includes('съесть')) {
                return "Исходя из твоего текущего калоража (осталось 420 ккал), идеальным выбором будет: 'Лосось на пару с брокколи и лимоном'. Добавить в список покупок?";
            } else {
                return "Я проанализировал твой запрос. Как твой личный AI-ассистент, я постоянно обучаюсь. Сейчас я рекомендую придерживаться плана питания и не забывать отмечать стаканы с водой на дашборде!";
            }
        };

        const handleSend = (text) => {
            if (!text.trim()) return;
            appendUserMsg(text);
            inputField.value = '';
            btnSend.classList.remove('active');

            // Показываем лоадер
            typingIndicator.style.display = 'flex';
            scrollToBottom();

            // Имитируем запрос к серверу
            setTimeout(() => {
                typingIndicator.style.display = 'none';
                appendAiMsg(generateAiResponse(text));
            }, 1500 + Math.random() * 1000);
        };

        // Запуск по кнопке
        btnSend.addEventListener('click', () => {
            handleSend(inputField.value);
        });

        // Запуск по Enter
        inputField.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') handleSend(inputField.value);
        });

        // Анимация активации кнопки
        inputField.addEventListener('input', () => {
            if (inputField.value.trim().length > 0) {
                btnSend.classList.add('active');
            } else {
                btnSend.classList.remove('active');
            }
        });

        // Быстрые ответы
        suggestionChips.forEach(chip => {
            chip.addEventListener('click', () => {
                handleSend(chip.innerText);
            });
        });

    } catch (e) {
        console.error("Chat engine error:", e);
    }
});
