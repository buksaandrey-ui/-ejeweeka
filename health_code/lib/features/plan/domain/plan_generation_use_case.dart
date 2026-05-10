// lib/features/plan/domain/plan_generation_use_case.dart
// PlanGenerationUseCase — Orchestrates:
//   1. Auth (get valid token)
//   2. Build payload from UserProfile
//   3. POST /api/v1/plan/generate
//   4. Normalize response → MealPlan
//   5. Cache to SharedPreferences
//   6. Offline fallback (serve cached plan if network unavailable)

import 'package:dio/dio.dart';
import 'package:health_code/core/network/api_client.dart';
import 'package:health_code/features/auth/data/auth_service.dart';
import 'package:health_code/features/onboarding/data/payload_builder.dart';
import 'package:health_code/features/onboarding/data/profile_model.dart';
import 'package:health_code/features/plan/data/meal_plan_model.dart';
import 'package:health_code/features/plan/data/plan_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_code/features/dashboard/data/snack_log_model.dart';
import 'package:health_code/features/dashboard/data/drink_log_model.dart';

/// Result type for generation
sealed class PlanResult {
  const PlanResult();
}

class PlanSuccess extends PlanResult {
  final MealPlan plan;
  final bool fromCache;
  const PlanSuccess(this.plan, {this.fromCache = false});
}

class PlanError extends PlanResult {
  final String message;
  final String? errorCode;
  const PlanError(this.message, {this.errorCode});
}

class PlanOfflineFallback extends PlanResult {
  final MealPlan plan;
  const PlanOfflineFallback(this.plan);
}

class PlanGenerationUseCase {
  final Dio _dio;
  final AuthService _auth;

  PlanGenerationUseCase({required Dio dio, required AuthService auth})
      : _dio = dio,
        _auth = auth;

  /// Main entry point. Returns [PlanResult].
  Future<PlanResult> generate(UserProfile profile) async {
    // 1. Check network via auth — if offline, serve cache
    final token = await _auth.getValidToken();
    if (token == null) {
      // Offline path
      final cached = await PlanRepository.loadCached();
      if (cached != null) {
        return PlanOfflineFallback(cached);
      }
      return const PlanError(
        'Нет соединения с сервером. Первый план требует интернета.',
        errorCode: 'OFFLINE_NO_CACHE',
      );
    }

    // 2. Load extra logs for AI correction
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final snackStr = prefs.getString('hc_snack_logs_$todayKey');
    final drinkStr = prefs.getString('hc_drink_logs_$todayKey');
    List<Map<String, dynamic>> snacks = [];
    List<Map<String, dynamic>> drinks = [];
    if (snackStr != null) {
      try { snacks = SnackLog.decodeList(snackStr).map((e) => e.toJson()).toList(); } catch (_) {}
    }
    if (drinkStr != null) {
      try { drinks = DrinkLog.decodeList(drinkStr).map((e) => e.toJson()).toList(); } catch (_) {}
    }


    // 3. Build payload
    final payload = ProfilePayloadBuilder.build(profile, snacks: snacks, drinks: drinks);

    // 4. Validate minimum required fields before sending
    final validation = _validatePayload(payload);
    if (validation != null) {
      return PlanError(validation, errorCode: 'VALIDATION_ERROR');
    }

    // 5. POST /api/v1/plan/generate
    try {
      final res = await _dio.post(
        '/api/v1/plan/generate',
        data: payload,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['status'] == 'success') {
          // 6. Parse and return for review (do NOT save to cache yet)
          final plan = MealPlan.fromApiResponse(data);
          return PlanSuccess(plan);
        }
        return PlanError(
          data['detail']?.toString() ?? 'Неизвестная ошибка сервера',
          errorCode: 'SERVER_ERROR',
        );
      }

      return PlanError(
        'Сервер вернул код ${res.statusCode}',
        errorCode: 'HTTP_${res.statusCode}',
      );
    } on DioException catch (e) {
      // 6. Offline fallback after request attempt
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cached = await PlanRepository.loadCached();
        if (cached != null) {
          return PlanOfflineFallback(cached);
        }
        return const PlanError(
          'Нет соединения. Попробуйте позже.',
          errorCode: 'TIMEOUT',
        );
      }

      if (e.response?.statusCode == 503) {
        return const PlanError(
          'HC-движок временно перегружен. Попробуй через минуту.',
          errorCode: 'HC_OVERLOADED',
        );
      }

      if (e.response?.statusCode == 429) {
        return const PlanError(
          'Слишком много запросов. Подождите минуту.',
          errorCode: 'RATE_LIMITED',
        );
      }

      return const PlanError(
        'Проверьте интернет-соединение и попробуйте снова',
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      return const PlanError('Произошла непредвиденная ошибка. Попробуйте еще раз.', errorCode: 'UNKNOWN');
    }
  }

  /// Validates minimum required fields for the API
  String? _validatePayload(Map<String, dynamic> p) {
    final age = p['age'] as int?;
    if (age == null || age < 10 || age > 120) {
      return 'Пожалуйста, укажите возраст (от 10 до 120 лет)';
    }
    final weight = p['weight'] as double?;
    if (weight == null || weight < 20 || weight > 400) {
      return 'Пожалуйста, укажите вес (от 20 до 400 кг)';
    }
    final height = p['height'] as double?;
    if (height == null || height < 100 || height > 260) {
      return 'Пожалуйста, укажите рост (от 100 до 260 см)';
    }
    final gender = p['gender'] as String?;
    if (gender == null || !{'male', 'female'}.contains(gender)) {
      return 'Пожалуйста, укажите пол';
    }
    return null;
  }
}
