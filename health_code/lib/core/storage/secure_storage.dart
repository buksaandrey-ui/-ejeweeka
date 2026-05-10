// lib/core/storage/secure_storage.dart
// Wrapper for flutter_secure_storage — Keychain (iOS) / Keystore (Android)
// Stores: anonymous_uuid, auth_token, isar_encryption_key

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyUuid = 'anonymous_uuid';
  static const _keyAuthToken = 'auth_token';

  // ── Anonymous UUID (Zero-Knowledge auth) ──────────────────────
  static Future<String> ensureAnonymousUuid() async {
    final stored = await _storage.read(key: _keyUuid);
    if (stored != null) return stored;
    final newUuid = const Uuid().v4();
    await _storage.write(key: _keyUuid, value: newUuid);
    return newUuid;
  }

  static Future<String?> getAnonymousUuid() async {
    return _storage.read(key: _keyUuid);
  }

  // ── Auth Token (Bearer JWT) ───────────────────────────────────
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  static Future<String?> getAuthToken() async {
    return _storage.read(key: _keyAuthToken);
  }

  static Future<void> clearAuthToken() async {
    await _storage.delete(key: _keyAuthToken);
  }

  // ── Generic key/value (for AuthService) ─────────────────────
  static Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // ── Full reset (for data deletion feature) ────────────────────
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
