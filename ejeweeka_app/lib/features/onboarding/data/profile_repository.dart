// lib/features/onboarding/data/profile_repository.dart
// SSOT: only class that reads/writes UserProfile
// Storage key 'ejeweeka_profile' — matches web localStorage key for compatibility

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejeweeka_app/core/storage/isar_service.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_model.dart';

class ProfileRepository {
  static const _key = 'ejeweeka_profile';

  static SharedPreferences get _prefs => IsarService.prefs;

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
