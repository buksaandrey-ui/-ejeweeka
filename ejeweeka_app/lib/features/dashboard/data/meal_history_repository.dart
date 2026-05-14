import 'package:shared_preferences/shared_preferences.dart';

class MealHistoryRepository {
  static const String _recentKey = 'ejeweeka_recent_meals';
  static const String _favoritesKey = 'ejeweeka_favorite_meals';

  /// Добавить блюдо в историю съеденного (максимум 14 дней, ограничим 100 хэшами)
  static Future<void> addRecentMeal(String mealHash) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentKey) ?? [];
    
    // Удаляем дубликат, если он уже был, чтобы переместить в конец (недавние)
    recent.remove(mealHash);
    recent.add(mealHash);
    
    // Оставляем только последние 100 записей
    if (recent.length > 100) {
      recent = recent.sublist(recent.length - 100);
    }
    
    await prefs.setStringList(_recentKey, recent);
  }

  /// Получить историю съеденного
  static Future<List<String>> getRecentMeals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  /// Добавить блюдо в избранное
  static Future<void> addFavoriteMeal(String mealHash) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_favoritesKey) ?? [];
    
    if (!favs.contains(mealHash)) {
      favs.add(mealHash);
      await prefs.setStringList(_favoritesKey, favs);
    }
  }

  /// Удалить блюдо из избранного
  static Future<void> removeFavoriteMeal(String mealHash) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_favoritesKey) ?? [];
    
    if (favs.contains(mealHash)) {
      favs.remove(mealHash);
      await prefs.setStringList(_favoritesKey, favs);
    }
  }

  /// Получить список любимых блюд
  static Future<List<String>> getFavoriteMeals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }
}
