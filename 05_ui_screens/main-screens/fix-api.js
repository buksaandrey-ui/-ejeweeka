const fs = require('fs');
let content = fs.readFileSync('api-connector.js', 'utf8');

content = content.replace(
    /const gender = \(p\['gender'\] \|\| ''\)\.includes\('Женский'\) \? 'female' : 'male';/,
    "const gender = p['gender'] === 'female' ? 'female' : 'male';"
);

content = content.replace(
    /meal_pattern: p\['Сколько раз в день удобно есть\?'\] \|\| p\['Частота приёмов пищи'\] \|\| '3 приема \(завтрак, обед, ужин\)',/,
    "meal_pattern: p['meals_per_day'] || '3 приема (завтрак, обед, ужин)',"
);

content = content.replace(
    /const fastingStatus = fastingRaw && !fastingRaw.includes\('Нет'\) && fastingRaw !== 'false';/,
    "const fastingStatus = fastingRaw && !fastingRaw.includes('Нет') && fastingRaw !== 'no' && fastingRaw !== 'false';"
);

fs.writeFileSync('api-connector.js', content);
console.log('Fixed api-connector.js logic');
