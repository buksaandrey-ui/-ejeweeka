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
}
