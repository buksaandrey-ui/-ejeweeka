const fs = require('fs');
const path = require('path');

const replaceInFile = (file, replacements) => {
    const filePath = path.join(__dirname, file);
    if (!fs.existsSync(filePath)) return;
    let content = fs.readFileSync(filePath, 'utf8');
    let changed = false;
    
    replacements.forEach(({ search, replace }) => {
        if (content.includes(search)) {
            content = content.split(search).join(replace);
            changed = true;
        }
    });

    if (changed) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${file}`);
    }
};

// 1. o16-5-plan-explanation.html
replaceInFile('o16-5-plan-explanation.html', [
    { search: 'Ты указали барьеры:', replace: 'Ты указал(а) барьеры:' },
    { search: 'При стабильном следовании плану, ты можешь достичь', replace: 'При стабильном следовании плану ты можешь достичь' }
]);

// 2. o17-5-disclaimer.html
replaceInFile('o17-5-disclaimer.html', [
    { search: 'При наличии заболеваний проконсультируйтесь со специалистом.', replace: 'При наличии заболеваний проконсультируйся со специалистом.' }
]);

// 3. fasting-state.js
replaceInFile('fasting-state.js', [
    { search: 'Вы уверены, что хотите прервать голодание?', replace: 'Уверен(а), что хочешь прервать голодание?' }
]);

// 4. o17-statuswall.html and o17-var10-accordion.html
replaceInFile('o17-statuswall.html', [
    { search: 'План питания, приема витаминов и лекарств, и тренировок на неделю', replace: 'План питания, приёма витаминов, лекарств и тренировок на неделю' }
]);
replaceInFile('o17-var10-accordion.html', [
    { search: 'План питания, приема витаминов и лекарств, и тренировок на неделю', replace: 'План питания, приёма витаминов, лекарств и тренировок на неделю' }
]);

// 5. o17-var6.html
replaceInFile('o17-var6.html', [
    { search: 'У вас активирован Статус Gold', replace: 'У тебя активирован Статус Gold' }
]);

// 6. o17-var1.html
replaceInFile('o17-var1.html', [
    { search: 'Тебе активирован Status Gold', replace: 'У тебя активирован Status Gold' }
]);

console.log('Text fixes complete.');
