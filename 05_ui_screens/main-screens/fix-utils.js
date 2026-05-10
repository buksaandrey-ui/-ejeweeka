const fs = require('fs');
let content = fs.readFileSync('app-utils.js', 'utf8');

// 1. Fix target_timeline_weeks missed by regex
content = content.replace(/p\['Срок \(недель\)'\]/g, "p['target_timeline_weeks']");

// 2. Wrap strings with toRuVal for display
// Just wrap the raw p['key'] calls for enum fields
const keysToTranslate = ['goal', 'gender', 'body_type', 'fat_distribution', 'bmi_class', 'diet_restrictions', 'allergies', 'symptoms', 'chronic_diseases', 'takes_medication', 'womens_health', 'takes_contraceptives', 'fasting_interest', 'fasting_pattern', 'meals_per_day', 'sleep_type', 'shift_type', 'activity_frequency', 'activity_types', 'budget', 'cooking_time', 'takes_supplements', 'supplement_openness', 'past_barriers', 'excluded_categories'];

keysToTranslate.forEach(key => {
    // Replace p['key'] with window.i18n.toRuVal(p['key']) BUT ONLY if it's not already wrapped
    const regex = new RegExp(`p\\['${key}'\\]`, 'g');
    content = content.replace(regex, `(window.i18n ? window.i18n.toRuVal(p['${key}']) : p['${key}'])`);
});

fs.writeFileSync('app-utils.js', content);
console.log('Fixed app-utils.js');
