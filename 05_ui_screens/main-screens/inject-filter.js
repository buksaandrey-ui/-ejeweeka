const fs = require('fs');
const path = require('path');

const files = fs.readdirSync(__dirname).filter(f => f.startsWith('o17') && f.endsWith('.html'));

const scriptStr = `
<script>
// Универсальный фильтр фичей статуса
document.addEventListener('DOMContentLoaded', () => {
    try {
        const raw = localStorage.getItem('aidiet_profile');
        if (!raw) return;
        const p = JSON.parse(raw);
        
        const meds = p['takes_medications'] || p['takes_medication'];
        const noMeds = (!meds || meds === 'Нет' || meds === 'false');
        const supps = p['currently_takes_supplements'] || p['takes_supplements'];
        const noSupps = (!supps || supps === 'Нет' || supps === 'false');
        const actFreq = p['activity_frequency'];
        const noTrain = (!actFreq || actFreq === 'Не готов(а) сейчас' || actFreq === 'Не готов сейчас');

        const walkDOM = (node, func) => {
            func(node);
            node = node.firstChild;
            while (node) {
                walkDOM(node, func);
                node = node.nextSibling;
            }
        };

        walkDOM(document.body, (node) => {
            if (node.nodeType === 3) { // Text node
                const text = node.nodeValue.toLowerCase();
                
                // Лекарства -> заменяем
                if (noMeds && text.includes('лекарств') && text.includes('совместимость')) {
                    node.nodeValue = 'Интеграция с Health Connect и трекерами активности';
                }
                
                // Витамины -> скрываем родителя
                if (noSupps && (text.includes('витаминов') || text.includes('бадов')) && !node.parentElement.closest('#dynamicPlanBullet')) {
                    // Ищем ближайший контейнер-строку (обычно div)
                    const row = node.parentElement.closest('div');
                    if (row && row.children.length > 0 && row.innerText.length < 100) {
                        row.style.display = 'none';
                    }
                }
                
                // Тренировки -> скрываем родителя
                if (noTrain && text.includes('тренировк') && !node.parentElement.closest('#dynamicPlanBullet')) {
                    const row = node.parentElement.closest('div');
                    if (row && row.children.length > 0 && row.innerText.length < 100) {
                        row.style.display = 'none';
                    }
                }
            }
        });
    } catch(e) {
        console.warn('Error in status feature filter', e);
    }
});
</script>
</body>`;

files.forEach(f => {
    let content = fs.readFileSync(path.join(__dirname, f), 'utf8');
    if (!content.includes('Универсальный фильтр фичей статуса')) {
        content = content.replace('</body>', scriptStr);
        fs.writeFileSync(path.join(__dirname, f), content, 'utf8');
        console.log('Injected filter into', f);
    }
});
