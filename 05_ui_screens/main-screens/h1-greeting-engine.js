/**
 * h1-greeting-engine.js
 * Логика системы динамических приветствий
 */

import greetingData from './h1-greeting-data.json' with { type: 'json' };

/**
 * Нормализует имя пользователя для отображения в приветствии
 * @param {string|null|undefined} rawName - сырое значение из хранилища
 * @returns {string} - нормализованное имя или пустая строка
 */
export function normalizeName(rawName) {
  if (!rawName || typeof rawName !== 'string') return '';

  const trimmed = rawName.trim();
  if (trimmed.length === 0) return '';

  // Только цифры или спецсимволы — считать пустым
  if (/^[^a-zA-ZА-ЯЁа-яё]+$/.test(trimmed)) return '';

  // Нормализация регистра первой буквы
  const normalized = trimmed.charAt(0).toUpperCase() + trimmed.slice(1);

  // Обрезка длинных имён
  if (normalized.length > 18) return normalized.slice(0, 18) + '…';

  return normalized;
}

/**
 * Генерирует контекстное приветствие и эпитет для пользователя.
 * @param {Object} userProfile - профиль пользователя
 * @returns {Object} объект с line1 и line2
 */
export function getGreeting(userProfile) {
  const currentYear = new Date().getFullYear();
  const hour = new Date().getHours();
  // Маппинг кириллической цели в английский ключ
  const rawGoal = userProfile['Главная цель'] || userProfile.goal || '';
  let goal = "health_energy";
  if (rawGoal.includes('Снизить вес') || rawGoal.includes('Поддержание веса')) goal = "weight_loss";
  else if (rawGoal.includes('Набрать')) goal = "muscle_gain";
  else if (rawGoal.includes('Восстановление')) goal = "recovery";
  
  const gender = userProfile.gender;
  const progressPercent = userProfile.progress_percent || 0;
  
  // ШАГ 1 — определить time_slot
  let timeSlot = "night";
  if (hour >= 5 && hour < 11) timeSlot = "morning";
  else if (hour >= 11 && hour < 17) timeSlot = "day";
  else if (hour >= 17 && hour < 22) timeSlot = "evening";

  // ШАГ 2 — определить age_range
  const birthYear = userProfile.birth_year || 1990;
  const age = currentYear - birthYear;
  let ageRange = "age_45_plus";
  if (age < 30) ageRange = "age_under30";
  else if (age < 45) ageRange = "age_30_44";

  // ШАГ 3 — определить context_phrase
  let contextPhrase = "";
  const minutes = new Date().getMinutes();
  
  // Расчет дней в приложении (для анти-срыва и первого запуска)
  const regDate = userProfile.registration_date ? new Date(userProfile.registration_date) : new Date();
  const daysInApp = Math.floor((new Date() - regDate) / (1000 * 60 * 60 * 24));
  
  // Проверка на самый первый запуск (First Session)
  const isFirstSession = (daysInApp === 0 && !userProfile.aidiet_first_greeting_shown);
  let isFirstSessionGreeting = false;

  if (isFirstSession && gender && greetingData.first_session && greetingData.first_session[gender]) {
     const goalKey = "goal_" + goal;
     const ageGroupObj = greetingData.first_session[gender][goalKey];
     if (ageGroupObj && ageGroupObj[ageRange]) {
       contextPhrase = getRandomItem(ageGroupObj[ageRange]);
       isFirstSessionGreeting = true;
       // Помечаем в профиле, что мы уже показали первое приветствие
       userProfile.aidiet_first_greeting_shown = true;
     }
  }
  
  if (!isFirstSessionGreeting) {
    if (userProfile.workout_done_today === true) {
    contextPhrase = getRandomItem(greetingData.context_phrases.post_workout);
  } else if (progressPercent === 100) {
    contextPhrase = getRandomItem(greetingData.progress_phrases["100"]);
  } else if (progressPercent >= 85) {
    contextPhrase = getRandomItem(greetingData.progress_phrases["85_99"]);
  } else if (progressPercent >= 60) {
    contextPhrase = getRandomItem(greetingData.progress_phrases["60_85"]);
  } else if (progressPercent >= 35) {
    contextPhrase = getRandomItem(greetingData.progress_phrases["35_60"]);
  } else if (progressPercent >= 15) {
    contextPhrase = getRandomItem(greetingData.progress_phrases["15_35"]);
  } else {
    // Низкий прогресс (0-15)
    if (daysInApp > 2) {
      // Пользователь давно с нами, но прогресс низкий -> анти-срыв (Блок 21)
      contextPhrase = getRandomItem(greetingData.context_phrases.anti_relapse) || getRandomItem(greetingData.progress_phrases["0_15"]);
    } else {
      // Новичок -> 50/50: прогресс или время суток
      if (minutes % 2 === 0) {
        contextPhrase = getRandomItem(greetingData.progress_phrases["0_15"]);
      } else {
        contextPhrase = getRandomItem(greetingData.context_phrases[timeSlot]);
      }
    }
  }

  // ШАГ 4 — выбрать эпитет
  let epithet = "";
  if (gender && greetingData.epithets[gender]) {
     const goalKey = "goal_" + goal;
     const ageGroupObj = greetingData.epithets[gender][goalKey];
     if (ageGroupObj && ageGroupObj[ageRange]) {
       const epithetsArray = ageGroupObj[ageRange];
       epithet = getRandomEpithet(epithetsArray, userProfile.last_greeting_epithet);
     }
  }

  // ШАГ 5 — собрать эмодзи
  let emoji = "☀️"; // fallback
  if (progressPercent === 100) emoji = "🏆";
  else if (userProfile.workout_done_today) emoji = "💪";
  else if (timeSlot === "morning") emoji = "☀️";
  else if (timeSlot === "day") emoji = "⚡";
  else if (timeSlot === "evening") emoji = "🌆";
  else if (timeSlot === "night") emoji = "🌙";

  // ШАГ 6 — собрать строки
  const cleanName = normalizeName(userProfile.nickname || userProfile['Имя']);
  
  let formattedContext = contextPhrase;
  let line1 = "";

  if (isFirstSessionGreeting) {
    // В первом приветствии фраза уже содержит [Имя], нужно просто заменить плейсхолдер
    line1 = formattedContext.replace('[Имя]', cleanName || 'друг');
  } else {
    if (cleanName && contextPhrase.length > 0) {
       formattedContext = contextPhrase.charAt(0).toLowerCase() + contextPhrase.slice(1);
    }
    
    // Убираем возможную запятую в конце и ставим восклицательный знак
    formattedContext = formattedContext.replace(/[,!]+$/, '') + '!';
    line1 = cleanName ? `${cleanName}, ${formattedContext}` : formattedContext;
  }
  
  let line2 = "";
  if (epithet) {
    line2 = `Ты — ${epithet} ${emoji}`;
  } else {
    // Фолбек, если пол не указан или эпитет не найден
    line2 = `${emoji}`;
  }

  return {
    line1: line1,
    line2: line2,
    _newEpithet: epithet // возвращаем, чтобы обновить в localStorage при необходимости
  };
}

// Helpers
function getRandomItem(arr) {
  if (!arr || !arr.length) return "";
  return arr[Math.floor(Math.random() * arr.length)];
}

function getRandomEpithet(arr, lastEpithet) {
  if (!arr || !arr.length) return "";
  if (arr.length === 1) return arr[0];
  
  // Ищем индекс прошлого эпитета для защиты от повторов
  let result = lastEpithet;
  let attempts = 0;
  while (result === lastEpithet || !result) {
    result = arr[Math.floor(Math.random() * arr.length)];
    attempts++;
    if (attempts > 5) break; // Предохранитель
    if (!lastEpithet) break; // Если не было истории, первое же случайное подходит
  }
  return result;
}

// Экспортируем в глобальную область для совместимости с dashboard-state.js
if (typeof window !== 'undefined') {
  window.getDynamicGreeting = getGreeting;
}
