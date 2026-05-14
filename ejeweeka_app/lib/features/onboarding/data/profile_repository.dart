// lib/features/onboarding/data/profile_repository.dart
// SSOT: only class that reads/writes UserProfile
// Storage key 'ejeweeka_profile' — matches web localStorage key for compatibility

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejeweeka_app/core/storage/isar_service.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_model.dart';

class ProfileRepository {
  static const _key = 'ejeweeka_profile';
  static const _recentMealsKey = 'ejeweeka_recent_meals';
  static const _favoriteMealsKey = 'ejeweeka_favorite_meals';

  static SharedPreferences get _prefs => IsarService.prefs;

  // ── History & Favorites ───────────────────────────────────────
  static List<String> get recentMeals {
    return _prefs.getStringList(_recentMealsKey) ?? [];
  }

  static Future<void> saveRecentMeal(String hash) async {
    final list = recentMeals;
    if (!list.contains(hash)) {
      list.add(hash);
      if (list.length > 70) list.removeAt(0); // Max 14 days ~70 meals
      await _prefs.setStringList(_recentMealsKey, list);
    }
  }

  static List<String> get favoriteMeals {
    return _prefs.getStringList(_favoriteMealsKey) ?? [];
  }

  static Future<void> toggleFavoriteMeal(String hash) async {
    final list = favoriteMeals;
    if (list.contains(hash)) {
      list.remove(hash);
    } else {
      list.add(hash);
    }
    await _prefs.setStringList(_favoriteMealsKey, list);
  }

  // ── Read ──────────────────────────────────────────────────────
  static UserProfile getOrCreate() {
    final json = _prefs.getString(_key);
    if (json != null && json.isNotEmpty) {
      return UserProfile.fromJsonString(json);
    }
    return UserProfile();
  }

  /// Returns the raw JSON map from storage (for checking key existence)
  static Map<String, dynamic> getRawJson() {
    final json = _prefs.getString(_key);
    if (json != null && json.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(
          const JsonDecoder().convert(json) as Map,
        );
      } catch (_) {}
    }
    return {};
  }

  // ── saveField: canonical key → typed field → persist ─────────
  static Future<void> saveField(String key, dynamic value) async {
    final profile = getOrCreate();
    profile.setField(key, value);
    await _prefs.setString(_key, profile.toJsonString());
  }

  static Future<void> saveFields(Map<String, dynamic> fields) async {
    final profile = getOrCreate();
    for (final entry in fields.entries) {
      profile.setField(entry.key, entry.value);
    }
    await _prefs.setString(_key, profile.toJsonString());
  }

  // ── Mark onboarding complete ──────────────────────────────────
  static Future<void> completeOnboarding() async {
    final profile = getOrCreate();
    profile.onboardingComplete = true;
    profile.firstLaunch ??= DateTime.now();
    await _prefs.setString(_key, profile.toJsonString());
  }

  // ── Delete all (GDPR) ─────────────────────────────────────────
  static Future<void> deleteAll() async {
    await _prefs.remove(_key);
  }
}
