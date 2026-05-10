const fs = require('fs');
const path = require('path');

const filesToUpdate = ['o17-statuswall.html', 'o17-var10-accordion.html'];

filesToUpdate.forEach(file => {
    let content = fs.readFileSync(path.join(__dirname, file), 'utf8');
    
    // Replace the static bullet
    const staticBullet = '<div><i class="ph ph-calendar-check"></i> План питания, сна, приёма витаминов, лекарств и тренировок на неделю</div>';
    const dynamicBullet = '<div id="dynamicPlanBullet"><i class="ph ph-calendar-check"></i> <span>План питания, сна, приёма витаминов, лекарств и тренировок на неделю</span></div>';
    content = content.replace(staticBullet, dynamicBullet);

    // Prepare the script
    const scriptStr = `
<script>
document.addEventListener('DOMContentLoaded', () => {
    try {
        const raw = localStorage.getItem('aidiet_profile');
        if (!raw) return;
        const p = JSON.parse(raw);
        
        let parts = ['План питания', 'сна'];
        
        // Витамины
        if ((p['currently_takes_supplements'] || p['takes_supplements']) && (p['currently_takes_supplements'] || p['takes_supplements']) !== 'Нет' && (p['currently_takes_supplements'] || p['takes_supplements']) !== 'false') {
            parts.push('приёма витаминов');
        }
        
        // Лекарства
        if ((p['takes_medications'] || p['takes_medication']) && (p['takes_medications'] || p['takes_medication']) !== 'Нет' && (p['takes_medications'] || p['takes_medication']) !== 'false') {
            parts.push('лекарств');
        }
        
        // Тренировки
        const actFreq = p['activity_frequency'];
        if (actFreq && actFreq !== 'Не готов(а) сейчас' && actFreq !== 'Не готов сейчас') {
            parts.push('тренировок');
        }
        
        let finalStr = '';
        if (parts.length > 2) {
            const last = parts.pop();
            finalStr = parts.join(', ') + ' и ' + last;
        } else {
            finalStr = parts.join(' и ');
        }
        
        const bulletEl = document.querySelector('#dynamicPlanBullet span');
        if (bulletEl) {
            bulletEl.innerText = finalStr + ' на неделю';
        }
    } catch(e) {
        console.warn('Error building dynamic plan bullet', e);
    }
});
</script>
</body>`;

    // Append script before </body>
    if (!content.includes('dynamicPlanBullet span')) {
        content = content.replace('</body>', scriptStr);
    }

    fs.writeFileSync(path.join(__dirname, file), content, 'utf8');
    console.log(`Updated ${file}`);
});
