// lib/shared/utils/enum_translator.dart
// Универсальный маппер backend enum-ключей в русские UI-лейблы.

class EnumTranslator {
  static String goal(String? g) => {
    'weight_loss': 'Снижение веса',
    'maintenance': 'Поддержание веса',
    'muscle_gain': 'Набор массы',
    'improve_energy': 'Энергия и самочувствие',
    'skin_hair_nails': 'Кожа, волосы, ногти',
    'gut_health': 'Здоровье ЖКТ',
    'longevity': 'Долголетие',
    'sport_performance': 'Спортивные результаты',
    'health_restrictions': 'Питание при ограничениях',
    'reduce_cravings': 'Снизить тягу к сладкому',
    'recovery': 'Восстановление',
    'age_adapted': 'Адаптировать к возрасту',
    'age_adaptation': 'Адаптировать к возрасту'
  }[g] ?? g ?? '—';

  static String gender(String? g) => g == 'male' ? 'Мужчина' : g == 'female' ? 'Женщина' : '—';
  
  static String bmiClass(String? c) => {
    'underweight': 'Дефицит',
    'normal': 'Норма',
    'overweight': 'Избыток',
    'obese': 'Ожирение'
  }[c] ?? c ?? '';
  
  static String bodyType(String? b) => {
    'slim': 'Худощавое',
    'medium': 'Среднее',
    'athletic': 'Спортивное',
    'full': 'Полное',
    'large': 'Крупное'
  }[b] ?? b ?? '—';

  static String activityType(String? t) => {
    'walking': 'Ходьба',
    'running': 'Бег',
    'strength': 'Силовые',
    'home_workout': 'Домашние',
    'swimming': 'Плавание',
    'yoga': 'Йога/растяжка',
    'cycling': 'Велосипед',
    'team_sports': 'Командные',
    'pilates': 'Пилатес'
  }[t] ?? t ?? '';

  static String diet(String? d) => {
    'none': 'Нет ограничений',
    'vegetarian': 'Вегетарианство',
    'vegan': 'Веганство',
    'no_red_meat': 'Без красного мяса',
    'pescatarian': 'Пескетарианство',
    'no_dairy': 'Без молочных продуктов',
    'gluten_free': 'Без глютена',
    'no_sugar': 'Без сахара',
    'halal': 'Халяль',
    'kosher': 'Кошерное питание'
  }[d] ?? d ?? '';

  static String allergy(String? a) => {
    'nuts': 'Орехи',
    'peanuts': 'Арахис',
    'dairy': 'Молочные продукты',
    'eggs': 'Яйца',
    'fish': 'Рыба',
    'shellfish': 'Морепродукты',
    'soy': 'Соя',
    'citrus': 'Цитрусовые',
    'honey': 'Мёд'
  }[a] ?? a ?? '';

  static String mealType(String? t) => {
    'pork': 'Свинина',
    'beef': 'Говядина',
    'chicken': 'Курица',
    'fish': 'Рыба',
    'seafood': 'Морепродукты',
    'dairy': 'Молочка',
    'eggs': 'Яйца',
    'mushrooms': 'Грибы',
    'spicy': 'Острое',
    'sweet': 'Сладкое'
  }[t] ?? t ?? '';
}
