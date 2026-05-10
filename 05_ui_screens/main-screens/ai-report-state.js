// ai-report-state.js
// Логика рендеринга AI Отчета (PR-2)
// v2.0: подключен к /api/v1/report/weekly
//
// Стратегия:
// 1. Собрать DaySummary[] из локальных данных (food_log, water_log, weight_log)
// 2. Отправить на /api/v1/report/weekly
// 3. Отрендерить AI-ответ
// 4. Fallback на локальную аналитику если сервер недоступен

document.addEventListener('DOMContentLoaded', async () => {
    try {
        // === 1. Собираем данные за последние 7 дней ===
        const days = collectWeekData();
        const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
        
        // Показываем локальные данные сразу (не ждём сервер)
        renderLocalScore(days, profile);
        
        // === 2. Пробуем получить AI-отчёт с сервера ===
        if (typeof apiFetch === 'function') {
            try {
                showLoadingState();
                
                const response = await apiFetch('/api/v1/report/weekly', {
                    method: 'POST',
                    body: JSON.stringify({
                        days: days,
                        user_goal: profile['Главная цель'] || 'Поддержание здоровья',
                        user_name: profile['Имя'] || null,
                        user_diseases: (profile['Хронические заболевания'] || '').split(',').map(s => s.trim()).filter(Boolean)
                    })
                });
                
                if (response.ok) {
                    const report = await response.json();
                    renderServerReport(report);
                    console.log('[AI Report] Server report rendered');
                } else {
                    console.warn('[AI Report] Server returned error, using local analytics');
                }
            } catch (e) {
                console.warn('[AI Report] Server unavailable, using local analytics:', e.message);
            }
        }
        
        // === 3. Кнопка действия ===
        const btnCta = document.querySelector('.btn-share');
        if (btnCta) {
            btnCta.innerHTML = '<i class="ph ph-chat-circle-text"></i> Задать вопрос AI';
            btnCta.onclick = () => { location.href = 'c1-ai-chat.html'; };
        }
        
    } catch (e) {
        console.error('[AI Report] Error:', e);
    }
});

/**
 * Собирает данные за последние 7 дней из localStorage.
 * @returns {Array<Object>} DaySummary[]
 */
function collectWeekData() {
    const days = [];
    const now = new Date();
    
    const foodLog = JSON.parse(localStorage.getItem('aidiet_food_log') || '{}');
    const waterLog = JSON.parse(localStorage.getItem('aidiet_water_log') || '{}');
    const weightLog = JSON.parse(localStorage.getItem('aidiet_weight_log') || '{}');
    const profile = JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
    
    const targetCal = parseInt(profile['target_daily_calories']) || 2000;
    const waterTarget = 2000; // мл
    
    for (let i = 6; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(d.getDate() - i);
        const dateStr = d.toISOString().split('T')[0];
        
        // Калории из food_log
        let caloriesConsumed = 0;
        let mealsEaten = 0;
        if (foodLog.days && foodLog.days[dateStr]) {
            const entries = foodLog.days[dateStr];
            caloriesConsumed = entries.reduce((sum, e) => sum + (e.calories || 0), 0);
            mealsEaten = entries.length;
        }
        
        // Вода
        let waterMl = 0;
        if (waterLog[dateStr]) {
            waterMl = waterLog[dateStr].val || waterLog[dateStr] || 0;
        } else if (typeof waterLog.val === 'number' && i === 0) {
            waterMl = waterLog.val;
        }
        
        // Вес
        let weightKg = null;
        if (weightLog[dateStr]) {
            weightKg = parseFloat(weightLog[dateStr]);
        } else if (weightLog.entries && Array.isArray(weightLog.entries)) {
            const entry = weightLog.entries.find(e => e.date === dateStr);
            if (entry) weightKg = parseFloat(entry.weight);
        }
        
        days.push({
            date: dateStr,
            calories_consumed: caloriesConsumed,
            calories_target: targetCal,
            water_ml: waterMl,
            water_target_ml: waterTarget,
            weight_kg: weightKg,
            meals_eaten: mealsEaten,
            meals_planned: 4,
            steps: null,
            sleep_hours: null,
            fasting_completed: false
        });
    }
    
    return days;
}

/**
 * Рендерит локальный score (без сервера) — мгновенный отклик.
 */
function renderLocalScore(days, profile) {
    // Водный баланс
    const totalWater = days.reduce((sum, d) => sum + d.water_ml, 0);
    const avgWater = totalWater / Math.max(days.length, 1);
    const waterScore = Math.min(100, Math.round((avgWater / 2000) * 100));
    
    // BMI score
    let bmiScore = 85;
    if (profile['Текущий вес'] && profile['Рост']) {
        const h = parseFloat(profile['Рост']) / 100;
        const w = parseFloat(profile['Текущий вес']);
        const bmi = w / (h * h);
        const diff = Math.abs(bmi - 22);
        bmiScore = Math.max(10, 100 - (diff * 5));
    }
    
    // Питание score
    const daysWithFood = days.filter(d => d.calories_consumed > 0);
    const nutritionScore = daysWithFood.length > 0 
        ? Math.round(daysWithFood.reduce((sum, d) => {
            const ratio = Math.min(d.calories_consumed / Math.max(d.calories_target, 1), 1.3);
            return sum + (ratio > 0.7 && ratio < 1.15 ? 90 : ratio > 0.5 ? 70 : 40);
          }, 0) / daysWithFood.length)
        : 60;
    
    const overallScore = Math.round((bmiScore * 1.5 + waterScore + nutritionScore + 80) / 4.5);
    
    renderScore(overallScore, {
        nutrition: nutritionScore,
        activity: 65,
        sleep: 80
    });
    
    // Insight
    const insightText = document.querySelector('.insight-text');
    if (insightText) {
        if (waterScore < 70) {
            insightText.innerText = 'Анализ выявил дефицит потребления воды на этой неделе. Обезвоживание замедляет липолиз (сжигание жира) на 15%. Рекомендую увеличить норму.';
        } else if (nutritionScore < 70) {
            insightText.innerText = 'На этой неделе калорийность питания была нестабильной. Старайся придерживаться плана питания — это ускорит достижение цели.';
        } else {
            insightText.innerText = 'Твой метаболизм работает как часы! Не забывай вносить тренировки в трекер, чтобы AI мог точнее считать дефицит калорий.';
        }
    }
}

/**
 * Рендерит полноценный серверный AI-отчёт.
 */
function renderServerReport(report) {
    // Score
    if (report.health_score !== undefined) {
        renderScore(report.health_score, report.metrics || {});
    }
    
    // Summary text
    const sumText = document.querySelector('.score-summary-text');
    if (sumText && report.summary) {
        // Берём первое предложение как summary
        const firstSentence = report.summary.split('.')[0] + '.';
        sumText.innerText = firstSentence;
    }
    
    // AI Insight — полный текст отчёта
    const insightText = document.querySelector('.insight-text');
    if (insightText && report.summary) {
        insightText.innerText = report.summary;
    }
    
    // Recommendations
    if (report.metrics && report.metrics.recommendations) {
        const recList = document.querySelector('.rec-list');
        if (recList) {
            recList.innerHTML = '';
            const icons = ['ph-sneaker', 'ph-drop', 'ph-apple', 'ph-sun', 'ph-heart'];
            report.metrics.recommendations.forEach((rec, i) => {
                const div = document.createElement('div');
                div.className = 'rec-item';
                div.innerHTML = `
                    <div class="rec-icon"><i class="ph ${icons[i % icons.length]}"></i></div>
                    <div class="rec-content">${rec}</div>
                `;
                recList.appendChild(div);
            });
        }
    }
    
    hideLoadingState();
}

/**
 * Рендерит score circle и category bars.
 */
function renderScore(score, metrics) {
    const valEl = document.querySelector('.score-val');
    if (valEl) valEl.innerText = score;
    
    const circle = document.querySelector('.score-svg circle:nth-child(2)');
    if (circle) {
        const offset = 339.29 - (339.29 * (score / 100));
        circle.style.strokeDasharray = '339.29';
        circle.style.strokeDashoffset = offset;
        circle.style.stroke = score >= 80 ? 'var(--color-success)' : score >= 60 ? 'var(--color-warning)' : 'var(--color-danger)';
    }
    
    const sumText = document.querySelector('.score-summary-text');
    if (sumText) {
        if (score >= 80) sumText.innerText = 'Отличный результат! План питания полностью соответствует целям.';
        else if (score >= 60) sumText.innerText = 'Хороший прогресс. Есть зоны для улучшения — обрати внимание на рекомендации.';
        else sumText.innerText = 'Есть зоны для улучшения. Обрати внимание на гидратацию и регулярность питания.';
    }
    
    // Category bars
    const catItems = document.querySelectorAll('.cat-item');
    const categories = [
        { key: 'nutrition', label: 'Питание', color: 'var(--color-success)' },
        { key: 'activity', label: 'Активность', color: 'var(--color-warning)' },
        { key: 'sleep', label: 'Сон', color: 'var(--color-info)' }
    ];
    
    catItems.forEach((item, i) => {
        if (categories[i]) {
            const val = metrics[categories[i].key] || 60;
            const scoreSpan = item.querySelector('.cat-score');
            if (scoreSpan) scoreSpan.innerText = `${val}/100`;
            const fill = item.querySelector('.cat-fill');
            if (fill) {
                fill.style.width = `${val}%`;
                fill.style.backgroundColor = val >= 80 ? 'var(--color-success)' : val >= 60 ? 'var(--color-warning)' : 'var(--color-danger)';
            }
        }
    });
}

function showLoadingState() {
    const insight = document.querySelector('.insight-card');
    if (insight) {
        insight.style.opacity = '0.7';
        const header = insight.querySelector('.insight-header');
        if (header) header.innerHTML = '<i class="ph ph-sparkle-fill"></i> AI Анализ <span style="font-size:12px; color:#B36200;">(загрузка...)</span>';
    }
}

function hideLoadingState() {
    const insight = document.querySelector('.insight-card');
    if (insight) {
        insight.style.opacity = '1';
        const header = insight.querySelector('.insight-header');
        if (header) header.innerHTML = '<i class="ph ph-sparkle-fill"></i> AI Анализ';
    }
}
