const fs = require('fs');
const path = require('path');

const dirsToSearch = [
    __dirname, // main-screens
    path.join(__dirname, '..') // 05_ui_screens (for md files)
];

const getFiles = (dir) => {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory() && !file.includes('_archive') && !file.includes('.vercel')) {
            results = results.concat(getFiles(file));
        } else if (file.endsWith('.js') || file.endsWith('.html') || file.endsWith('.md')) {
            results.push(file);
        }
    });
    return results;
};

const allFiles = dirsToSearch.reduce((acc, dir) => acc.concat(getFiles(dir)), []);
const uniqueFiles = [...new Set(allFiles)]; // remove duplicates

const replacements = [
    { search: /paywall-state\.js/g, replace: 'status-wall.js' },
    { search: /status-lock/g, replace: 'status-lock' },
    { search: /applyStatusWall/g, replace: 'applyStatusWall' },
    { search: /goToStatusWall/g, replace: 'goToStatusWall' },
    { search: /Paywall \/ U-12/g, replace: 'Экран статусов / U-12' },
    { search: /status screen/g, replace: 'status screen' },
    { search: /вместо экрана статуса/g, replace: 'вместо экрана статуса' },
    { search: /фильтр фичей статуса/g, replace: 'фильтр фичей статуса' },
    { search: /status feature filter/g, replace: 'status feature filter' },
    { search: /Экран статусов O-19/g, replace: 'Экран статусов O-19' },
    { search: /Paywall \(O-19\)/g, replace: 'Экран статусов O-19' },
    { search: /экран статусов/g, replace: 'экран статусов' },
    { search: /экран статусов/g, replace: 'Экран статусов' },
    { search: /<div class="badge onboard">O17<\/div>Paywall<\/a>/g, replace: '<div class="badge onboard">O17</div>Статусы</a>' },
    { search: /O-17 Экран статусов/g, replace: 'O-17 Экран статусов' },
    { search: /O-17\. Paywall/g, replace: 'O-17. Экран статусов' },
    { search: /кроме онбординга и экрана статусов/g, replace: 'кроме онбординга и экрана статусов' },
    { search: /Показываем экран статусов/g, replace: 'Показываем экран статусов' },
    { search: /Status redirect/g, replace: 'Status redirect' }
];

uniqueFiles.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let changed = false;
    
    replacements.forEach(({ search, replace }) => {
        if (content.match(search)) {
            content = content.replace(search, replace);
            changed = true;
        }
    });

    if (changed) {
        fs.writeFileSync(file, content, 'utf8');
        console.log(`Scrubbed: ${path.basename(file)}`);
    }
});

console.log('Scrubbing complete.');
