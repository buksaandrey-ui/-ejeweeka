// aidiet-dev.js
// Инструменты для разработки и тестирования (НЕ подключать в продакшн)

(function() {
  window.AIDiet = window.AIDiet || {};

  /**
   * Тестовый авто-филлер профиля.
   * Вызов: window.AIDiet.devFill() в консоли браузера.
   * Заполняет весь профиль тестовыми данными и переходит к плану.
   */
  window.AIDiet.devFill = function() {
    const mockProfile = {
      "Страна": "Россия",
      "Город": "Москва",
      "Главная цель": "Снизить вес (похудеть)",
      "Имя": "Тестер",
      "Пол": "Женский",
      "Возраст": "28",
      "Рост": "165",
      "Текущий вес": "72",
      "Желаемый вес": "60",
      "Целевой вес": "60",
      "Срок (недель)": "12",
      "Доп. Снижение веса": "Да",
      "Частота активности": "3-4 раза в неделю",
      "Аллергии": "Лактоза",
      "Симптомы": "Усталость, Вздутие живота",
      "Хронические заболевания": "Инсулинорезистентность",
      "Женское здоровье": "ПМС",
      "Голодание": "16:8",
      "Сколько раз в день удобно есть?": "3 раза (Классика)",
      "Принимает лекарства": "Метформин",
      "Бюджет": "Средний",
      "Время на готовку": "Не более 30 минут в день",
      "Любимые продукты": "Авокадо, Лосось, Яйца",
      "Нелюбимые продукты": "Брокколи",
      "Исключённые категории": "Молочка",
      "_schema_version": 2
    };
    localStorage.setItem('aidiet_profile', JSON.stringify(mockProfile));
    localStorage.setItem('aidiet_subscription', 'gold');
    console.log('✅ Dev-профиль загружен (Gold-статус включен). Переход на P-1...');
    
    if (typeof generatePlanAPI === 'function') {
      generatePlanAPI().then(() => {
        location.href = 'p1-weekly-plan.html';
      }).catch(() => {
        location.href = 'p1-weekly-plan.html';
      });
    } else {
      console.warn('[devFill] generatePlanAPI not loaded, redirecting directly');
      location.href = 'p1-weekly-plan.html';
    }
  };

  console.log('[Health Code Dev] Dev tools loaded. Use AIDiet.devFill() to auto-fill profile.');
})();
