const fs = require('fs');
let content = fs.readFileSync('greeting_variants.md', 'utf8');

// Block 3
content = content.replace('ваше упорство', 'твое упорство');
content = content.replace('Приветствую, **[Имя]**! Вы —', 'Привет, **[Имя]**! Ты —');
content = content.replace('каждый ваш шаг', 'каждый твой шаг');
content = content.replace('Вы феноменальны и находитесь', 'Ты феноменальна и находишься');
content = content.replace('ваш результат', 'твой результат');

// Block 12
content = content.replace('Приветствую, **[Имя]**! Вы живая', 'Привет, **[Имя]**! Ты живая');
content = content.replace('ваша форма', 'твоя форма');
content = content.replace('Вы бывалый', 'Ты бывалый');

// Block 11
content = content.replace('Приветствую, **[Имя]**!', 'Привет, **[Имя]**!');

// Let's do a general pass for "Приветствую" just in case
content = content.replace(/Приветствую,/g, 'Привет,');
content = content.replace(/Добрый день, \*\*\[Имя\]\*\*! Вы/g, 'Добрый день, **[Имя]**! Ты');

fs.writeFileSync('greeting_variants.md', content);
console.log('Fixed formal language');
