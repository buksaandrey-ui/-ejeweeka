// lib/features/plan/data/plan_repository.dart
// PlanRepository — handles plan storage in SharedPreferences
// Offline-first: reads cache → serves stale-while-revalidate

import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_code/features/plan/data/meal_plan_model.dart';

class PlanRepository {
  static const _planKey = 'cached_meal_plan';
  static const _generatedAtKey = 'plan_generated_at';

  // ── Read ──────────────────────────────────────────────────────

  static Future<MealPlan?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return MealPlan.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasCachedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_planKey);
  }

  static Future<bool> isCacheStale() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_generatedAtKey);
    if (raw == null) return true;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return true;
    return DateTime.now().difference(dt).inDays >= 7;
  }

  // ── Write ─────────────────────────────────────────────────────

  static Future<void> savePlan(MealPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan.toJsonString());
    await prefs.setString(_generatedAtKey, plan.generatedAt);
  }

  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
    await prefs.remove(_generatedAtKey);
  }
}
