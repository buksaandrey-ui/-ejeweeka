// lib/core/storage/isar_service.dart
// SharedPreferences-based storage (replaces Isar due to codegen conflicts)
// Profile stored as JSON under key 'ejeweeka_profile' — mirrors web localStorage

import 'package:shared_preferences/shared_preferences.dart';

class IsarService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    assert(_prefs != null, 'Call IsarService.init() first');
    return _prefs!;
  }
}
