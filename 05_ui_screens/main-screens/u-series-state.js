// u-series-state.js
// Универсальный стейт-менеджер для Настроек (U-1..U-16)
// SSOT: Все данные читаются/пишутся через aidiet_profile (AIDiet.saveField/getProfile)
// U.2 FIX: Screen-aware save — каждый экран сохраняет только свои поля

document.addEventListener('DOMContentLoaded', () => {
    // 1. Загружаем профиль из SSOT
    const p = (window.AIDiet && window.AIDiet.getProfile) 
        ? window.AIDiet.getProfile() 
        : JSON.parse(localStorage.getItem('aidiet_profile') || '{}');
    
    // Определяем текущий экран по data-screen или title
    const screenId = document.body.dataset.screen 
        || (document.title.match(/U-(\d+)/i) || [])[0] 
        || '';

    // === HYDRATION: Заполнение UI данными из профиля ===
    
    // Гидратация инпутов по placeholder
    document.querySelectorAll('input').forEach(inp => {
        const ph = inp.placeholder;
        if (ph === 'Имя' && p['Имя']) inp.value = p['Имя'];
        if (ph === 'Возраст' && p['Возраст']) inp.value = p['Возраст'];
        if (ph === 'Рост' && p['Рост']) inp.value = p['Рост'];
        if (ph === 'Вес' && p['Текущий вес']) inp.value = p['Текущий вес'];
        if (ph === 'Обхват' && p['Обхват талии']) inp.value = p['Обхват талии'];
    });

    // Гидратация селектов (Пол)
    document.querySelectorAll('.select-item').forEach(item => {
        const text = item.innerText.trim();
        const sex = p['Пол'] || '';
        if (text === 'М' && sex.includes('Мужск')) item.classList.add('active');
        else if (text === 'Ж' && sex.includes('Женск')) item.classList.add('active');
        
        // Цель — прямое сравнение
        const goal = p['Главная цель'] || '';
        if (goal && text === goal) item.classList.add('active');
        // Fuzzy match для укороченных целей
        if (goal.includes('Снизить вес') && text === 'Снизить вес') item.classList.add('active');
        if (goal.includes('Набрать') && text === 'Набрать массу') item.classList.add('active');
        if (goal.includes('здоровье') && text === 'Здоровое тело') item.classList.add('active');
        if (goal.includes('нерги') && text === 'Энергия') item.classList.add('active');
    });

    // Гидратация U-3: Симптомы (chips) + Хронические (options)
    if (screenId.includes('3') || document.title.includes('U-3')) {
        const symptoms = (p['Симптомы'] || '').split(',').map(s => s.trim()).filter(Boolean);
        document.querySelectorAll('.chip').forEach(c => {
            if (symptoms.includes(c.innerText.trim())) c.classList.add('active');
            else c.classList.remove('active');
        });
        const diseases = (p['Хронические заболевания'] || '').split(',').map(s => s.trim()).filter(Boolean);
        document.querySelectorAll('.option-item').forEach(item => {
            const label = item.querySelector('.option-label');
            if (label && diseases.includes(label.innerText.trim())) item.classList.add('active');
            else item.classList.remove('active');
        });
        // Лекарства
        const medTA = document.querySelector('textarea');
        if (medTA && p['Принимает лекарства'] && p['Принимает лекарства'] !== 'Нет') {
            medTA.value = p['Принимает лекарства'];
        }
    }

    // Гидратация U-4: Ограничения + Аллергии
    if (screenId.includes('4') || document.title.includes('U-4')) {
        const restrictions = (p['Выбранные диеты/ограничения'] || '').split(',').map(s => s.trim()).filter(Boolean);
        const allergies = (p['Аллергии'] || '').split(',').map(s => s.trim()).filter(Boolean);
        
        const sections = document.querySelectorAll('section');
        // Section 0 = Тип питания (ограничения)
        if (sections[0]) {
            sections[0].querySelectorAll('.list-item').forEach(item => {
                const label = item.querySelector('.list-label');
                if (label && restrictions.includes(label.innerText.trim())) item.classList.add('active');
                else item.classList.remove('active');
            });
        }
        // Section 1 = Аллергии
        if (sections[1]) {
            sections[1].querySelectorAll('.list-item').forEach(item => {
                const label = item.querySelector('.list-label');
                if (label && allergies.includes(label.innerText.trim())) item.classList.add('active');
                else item.classList.remove('active');
            });
        }
    }

    // === INTERACTIVITY ===

    // Переключатели (одиночный выбор)
    document.querySelectorAll('.select-grid').forEach(grid => {
        grid.querySelectorAll('.select-item').forEach(item => {
            item.addEventListener('click', () => {
                grid.querySelectorAll('.select-item').forEach(i => i.classList.remove('active'));
                item.classList.add('active');
            });
        });
    });

    // Чипсы (Множественный выбор)
    document.querySelectorAll('.chip').forEach(chip => {
        chip.addEventListener('click', () => chip.classList.toggle('active'));
    });

    // Чекбоксы в option-item списках
    document.querySelectorAll('.option-item').forEach(item => {
        item.addEventListener('click', () => item.classList.toggle('active'));
    });

    // U.3 FIX: Чекбоксы в list-item списках (U-4 использует .list-item)
    document.querySelectorAll('.list-item').forEach(item => {
        item.addEventListener('click', () => item.classList.toggle('active'));
    });

    // === SAVE LOGIC: Screen-Aware ===

    const saveBtn = document.querySelector('.save-btn');
    if (saveBtn) {
        saveBtn.addEventListener('click', () => {
            const save = (key, val) => {
                if (window.AIDiet) window.AIDiet.saveField(key, val);
            };
            
            // == U-2: Личные данные и цель ==
            if (screenId.includes('2') || document.title.includes('U-2')) {
                document.querySelectorAll('input').forEach(inp => {
                    const ph = inp.placeholder;
                    if (ph === 'Имя') save('Имя', inp.value);
                    if (ph === 'Возраст') save('Возраст', inp.value);
                    if (ph === 'Рост') save('Рост', inp.value);
                    if (ph === 'Вес') save('Текущий вес', inp.value);
                    if (ph === 'Обхват') save('Обхват талии', inp.value || '');
                });

                // Пол
                document.querySelectorAll('.select-item.active').forEach(item => {
                    const text = item.innerText.trim();
                    if (text === 'М') save('Пол', 'Мужской');
                    if (text === 'Ж') save('Пол', 'Женский');
                });

                // Цель
                const goalMap = {
                    'Снизить вес': 'Снизить вес',
                    'Поддержание веса': 'Поддержание веса',
                    'Набрать массу': 'Набрать мышечную массу',
                    'Кожа, ногти, волосы': 'Питание для кожи, ногтей, волос',
                    'Здоровье': 'Питание при ограничениях по здоровью',
                    'Возраст 40+': 'Адаптировать питание к возрасту (40+ / 50+ / 60+)',
                    'Тяга к сладкому': 'Снизить тягу к сладкому и голод',
                    'Энергия': 'Улучшить самочувствие и энергию',
                    'Восстановление': 'Восстановление после болезни/стресса'
                };
                document.querySelectorAll('.select-grid .select-item.active').forEach(item => {
                    const text = item.innerText.trim();
                    if (goalMap[text]) save('Главная цель', goalMap[text]);
                });

                // Пересчёт BMR/ИМТ
                const updated = window.AIDiet ? window.AIDiet.getProfile() : {};
                const w = parseFloat(updated['Текущий вес']);
                const h = parseFloat(updated['Рост']);
                const a = parseInt(updated['Возраст']);
                if (w && h) {
                    const bmi = (w / ((h/100) ** 2)).toFixed(1);
                    save('ИМТ', bmi);
                    
                    const isFemale = (updated['Пол'] || '').includes('Женск');
                    const bmr = isFemale 
                        ? Math.round(10 * w + 6.25 * h - 5 * a - 161)
                        : Math.round(10 * w + 6.25 * h - 5 * a + 5);
                    // U.6: Сохраняем в оба ключа для совместимости
                    save('Базовый обмен', String(bmr));
                    save('bmr_kcal', String(bmr));
                    
                    // TDEE (с множителем активности)
                    const mult = parseFloat(updated['activity_multiplier']) || 1.375;
                    const tdee = Math.round(bmr * mult);
                    save('target_daily_calories', String(tdee));
                }
            }

            // == U-3: Здоровье и симптомы ==
            if (screenId.includes('3') || document.title.includes('U-3')) {
                // Симптомы (chips)
                let symptoms = [];
                document.querySelectorAll('.chip.active').forEach(c => symptoms.push(c.innerText.trim()));
                save('Симптомы', symptoms.join(', '));

                // Хронические заболевания (option-items)
                let diseases = [];
                document.querySelectorAll('.option-item.active .option-label').forEach(c => diseases.push(c.innerText.trim()));
                save('Хронические заболевания', diseases.join(', '));

                // Лекарства (textarea) — только канонический ключ
                document.querySelectorAll('textarea').forEach(ta => {
                    save('Принимает лекарства', ta.value || 'Нет');
                });
            }

            // == U-4: Ограничения и аллергии ==
            if (screenId.includes('4') || document.title.includes('U-4')) {
                const sections = document.querySelectorAll('section');
                
                // Section 0: Тип питания → 'Выбранные диеты/ограничения'
                if (sections[0]) {
                    let restrictions = [];
                    sections[0].querySelectorAll('.list-item.active .list-label').forEach(c => restrictions.push(c.innerText.trim()));
                    save('Выбранные диеты/ограничения', restrictions.join(', '));
                }
                
                // Section 1: Аллергии → только канонический ключ 'Аллергии'
                if (sections[1]) {
                    let allergies = [];
                    sections[1].querySelectorAll('.list-item.active .list-label').forEach(c => allergies.push(c.innerText.trim()));
                    save('Аллергии', allergies.join(', '));
                }
                
                // Custom exclusion input
                const customInput = document.querySelector('.text-input');
                if (customInput && customInput.value) {
                    save('Исключённые продукты', customInput.value);
                }
            }

            // == U-5 and beyond: generic save (no field collisions) ==

            // Очистка кеша плана (данные изменились)
            localStorage.removeItem('aidiet_meal_plan');

            // Уведомление и возврат
            alert("Изменения сохранены. План питания будет перегенерирован.");
            history.back();
        });
    }
});
