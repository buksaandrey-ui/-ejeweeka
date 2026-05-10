/**
 * Health Code Medical Safety Interceptor
 * 
 * Встраивается на экраны O-6 и O-7 для перекрестной валидации опасных состояний
 * с целевыми темпами похудения (изветки O-4), предотвращая фатальный дефицит.
 */

window.validateMedicalSafety = function(diagnosesArray) {
    if (!window.AIDiet) return true;
    
    const profile = window.AIDiet.getProfile();
    const paceStr = profile['weight_loss_pace'] || profile['Темп похудения (срок)'];
    
    // Если пользователь не худеет или срок не задан, пропускаем
    if (!paceStr) return true;
    
    // Пытаемся распарсить кг/нед (в О-4 он сохраняется например "5 нед (1.8 кг/нед)")
    const paceMatch = paceStr.match(/\(([\d.]+)\s*кг\/нед/);
    if (!paceMatch) return true;

    const kgPerWeek = parseFloat(paceMatch[1]);
    
    // Опасные диагнозы, при которых дефицит > 0.5-0.7 кг запрещен
    const criticalDiagnoses = ['Диабет (1 тип)', 'Диабет (2 тип)', 'Беременность', 'Кормление грудью'];
    
    const hasDanger = diagnosesArray.some(d => criticalDiagnoses.includes(d));
    
    if (hasDanger && kgPerWeek > 0.6) {
        // Запускаем перехват
        alert("ОБЕСПЕЧЕНИЕ БЕЗОПАСНОСТИ\n\nПри твоём состоянии агрессивный дефицит калорий и быстрая потеря веса строго противопоказаны.\n\nМы автоматически перевели твой целевой темп на 'Безопасный' (0.5 кг/нед), чтобы не навредить твоему организму.\n\nВ дальнейшем ты сможешь отрегулировать темп снижения веса в настройках профиля.");
        
        // Принудительно корректируем план в безопасную сторону (0.5 кг/нед)
        // Если он хотел скинуть M кг, новый срок будет = M / 0.5 недель
        const currentWeight = parseFloat(profile['weight_kg'] || profile['Текущий вес']);
        const targetWeight = parseFloat(profile['target_weight_kg'] || profile['Целевой вес']);
        
        if (!isNaN(currentWeight) && !isNaN(targetWeight)) {
            const diff = currentWeight - targetWeight;
            if (diff > 0) {
                const safeWeeks = Math.ceil(diff / 0.5);
                window.AIDiet.saveField('target_timeline_weeks', safeWeeks);
                window.AIDiet.saveField('weight_loss_pace', `${safeWeeks} нед (0.5 кг/нед)`);
                window.AIDiet.saveField('pace_assessment', '🟢 Безопасный');
            }
        }
    }
    
    return true; // Всегда разрешаем продолжить движение, но уже с безопасными данными
};
