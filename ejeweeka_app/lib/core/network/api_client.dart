// lib/core/network/api_client.dart
// Dio HTTP client for all API calls to ejeweeka-api.onrender.com
// Bearer JWT auth + retry + Sentry error tracking

import 'package:dio/dio.dart';
import 'package:ejeweeka_app/core/network/endpoints.dart';
import 'package:ejeweeka_app/core/storage/secure_storage.dart';

class ApiClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _buildDio();
    return _dio!;
  }

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 120), // AI plan gen can be slow (Render cold starts)
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — attaches Bearer token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401: token expired — re-auth
        if (error.response?.statusCode == 401) {
          try {
            await _refreshToken();
            // Retry original request
            final clonedRequest = await instance.fetch(error.requestOptions);
            return handler.resolve(clonedRequest);
          } catch (_) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));

    // Logging (debug only)
    assert(() {
      dio.interceptors.add(LogInterceptor(
        requestBody: true, // Log request to see what payload is failing
        responseBody: true,
        logPrint: (o) => print('🌐 $o'),
      ));
      return true;
    }());

    return dio;
  }

  static Future<void> _refreshToken() async {
    final uuid = await SecureStorageService.getAnonymousUuid();
    if (uuid == null) return;

    final response = await Dio().post(
      '${Endpoints.baseUrl}${Endpoints.authInit}',
      data: {'anonymous_uuid': uuid},
    );

    final token = response.data['access_token'] as String?;
    if (token != null) {
      await SecureStorageService.saveAuthToken(token);
    }
  }
}
