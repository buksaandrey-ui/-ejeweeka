const fs = require('fs');
const path = require('path');

const filesToUpdate = fs.readdirSync(__dirname).filter(f => f.endsWith('.html'));

filesToUpdate.forEach(file => {
    let content = fs.readFileSync(path.join(__dirname, file), 'utf8');
    
    const searchValues = [
        { search: 'Статус Base', replace: 'Статус Base' },
        { search: 'Status Black', replace: 'Статус Black' },
        { search: 'Status Gold', replace: 'Статус Gold' },
        { search: 'status Gold', replace: 'Статус Gold' }, // lowercase 's'
        { search: 'Status Gold Family', replace: 'Статус Gold Family' }
    ];
    
    let changed = false;
    searchValues.forEach(({ search, replace }) => {
        // use regex with global flag to replace all occurrences
        const regex = new RegExp(search, 'g');
        if (regex.test(content)) {
            content = content.replace(regex, replace);
            changed = true;
        }
    });

    if (changed) {
        fs.writeFileSync(path.join(__dirname, file), content, 'utf8');
        console.log(`Updated ${file}`);
    }
});
console.log('Status wording fixed.');
