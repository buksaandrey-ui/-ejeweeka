const fs = require('fs');

const pathA = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/tails/LandingTailA.tsx';
const pathB = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/tails/LandingTailB.tsx';
const pathC = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/tails/LandingTailC.tsx';

let contentA = fs.readFileSync(pathA, 'utf8');
const contentB = fs.readFileSync(pathB, 'utf8');
const contentC = fs.readFileSync(pathC, 'utf8');

// Extract Comparison block from C
const compareStart = contentC.indexOf('{/* Вариант C: Сравнение */}');
const compareEnd = contentC.indexOf('{/* Статусы Decision Helper */}');
const compareSection = contentC.substring(compareStart, compareEnd).trim() + '\n\n';

// Extract Storytelling block from B
const storyStart = contentB.indexOf('{/* Вариант B: Неделя с Health Code */}');
const storyEnd = contentB.indexOf('{/* Статусы */}');
// Also, add a border-t to the storytelling section to visually separate it from comparison
let storySection = contentB.substring(storyStart, storyEnd).trim() + '\n\n';
storySection = storySection.replace(
  '<section className="relative py-32 overflow-hidden bg-[var(--bg)]">',
  '<section className="relative py-32 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">'
);

// We want Comparison first, then Storytelling, right after Variant A's first section
const insertPoint = contentA.indexOf('{/* Статусы */}');

const newContentA = contentA.substring(0, insertPoint) + 
  compareSection + 
  storySection + 
  contentA.substring(insertPoint);

fs.writeFileSync(pathA, newContentA);
console.log("Successfully combined blocks into LandingTailA.tsx");
