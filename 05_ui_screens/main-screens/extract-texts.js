const fs = require('fs');
const path = require('path');

const UI_DIR = __dirname;
const files = fs.readdirSync(UI_DIR).filter(f => f.startsWith('o') && f.endsWith('.html'));

let report = '# Text Audit Report\n\n';

files.forEach(file => {
    const content = fs.readFileSync(path.join(UI_DIR, file), 'utf8');
    // Extract text between tags, skipping scripts and styles
    let textOnly = content.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    textOnly = textOnly.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '');
    textOnly = textOnly.replace(/<[^>]+>/g, ' '); // remove tags
    
    // Clean up whitespace
    const words = textOnly.split(/\s+/).filter(w => w.trim().match(/[А-Яа-яЁё]/));
    
    // Reconstruct sentences roughly by grouping Cyrillic strings
    // We can just extract distinct Cyrillic lines from the raw file for better context
    const lines = content.split('\n');
    let fileTexts = [];
    lines.forEach(line => {
        if (line.includes('<script') || line.includes('<style')) return;
        const matches = line.match(/>([^<]+[А-Яа-яЁё]+[^<]+)</g);
        if (matches) {
            matches.forEach(m => {
                const text = m.substring(1, m.length - 1).trim();
                if (text && text.match(/[А-Яа-яЁё]/) && text.length > 5) {
                    fileTexts.push(text);
                }
            });
        }
        // Also catch placeholders
        const placeholders = line.match(/placeholder=["']([^"']+[А-Яа-яЁё]+[^"']+)["']/g);
        if (placeholders) {
            placeholders.forEach(p => {
                fileTexts.push("PLACEHOLDER: " + p.split(/['"]/)[1]);
            });
        }
    });

    if (fileTexts.length > 0) {
        report += `## ${file}\n`;
        [...new Set(fileTexts)].forEach(t => {
            report += `- ${t}\n`;
        });
        report += '\n';
    }
});

fs.writeFileSync('text_audit.md', report);
console.log('Text audit saved to text_audit.md');
