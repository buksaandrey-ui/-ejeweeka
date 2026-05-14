// lib/features/auth/data/auth_service.dart
// AuthService — anonymous auth lifecycle
// Endpoints: POST /api/v1/auth/init, POST /api/v1/auth/verify

import 'package:dio/dio.dart';
import 'package:ejeweeka_app/core/storage/secure_storage.dart';
import 'package:ejeweeka_app/features/onboarding/data/profile_repository.dart';

class AuthService {
  final Dio _dio;
  static const _tokenKey = 'auth_token';
  static const _uuidKey = 'anonymous_uuid';
  static const _appProfileIdKey = 'app_profile_id';
  static const _entitlementStatusKey = 'entitlement_status';

  AuthService(this._dio);

  /// Returns a valid token, refreshing if expired.
  /// Called before every API request.
  Future<String?> getValidToken() async {
    final token = await SecureStorageService.read(_tokenKey);
    if (token != null && await _verify(token)) return token;
    // Token expired or missing — re-init
    return await _init();
  }

  Future<String?> getStoredUuid() => SecureStorageService.read(_uuidKey);
  Future<String?> getAppProfileId() => SecureStorageService.read(_appProfileIdKey);
  Future<String?> getEntitlementStatus() => SecureStorageService.read(_entitlementStatusKey);

  // ── Private ───────────────────────────────────────────────────

  Future<String?> _init() async {
    try {
      final res = await _dio.post('/api/v1/auth/init');
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final uuid = data['anonymous_uuid'] as String;
        final profileId = data['app_profile_id'] as String;
        final status = data['entitlement_status'] as String;
        
        await SecureStorageService.write(_tokenKey, token);
        await SecureStorageService.write(_uuidKey, uuid);
        await SecureStorageService.write(_appProfileIdKey, profileId);
        await SecureStorageService.write(_entitlementStatusKey, status);
        
        // Sync to UserProfile SSOT
        await ProfileRepository.saveField('subscription_status', status);
        
        return token;
      }
    } on DioException catch (e) {
      // Offline → return null, callers handle degraded state
      print('[AuthService] init failed (offline?): ${e.message}');
    }
    return null;
  }

  Future<bool> _verify(String token) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/verify',
        data: {'token': token},
      );
      return res.statusCode == 200 &&
          (res.data as Map<String, dynamic>)['valid'] == true;
    } on DioException {
      // Network error → assume still valid (offline-first)
      return true;
    }
  }
}
