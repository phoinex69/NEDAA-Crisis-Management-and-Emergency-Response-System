import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import 'api_exception.dart';
import 'api_endpoints.dart';
import '../session_service.dart';

/// عميل HTTP مركزي (Dio) بترويسة التوكن ومعالجة أخطاء موحدة.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: AppConfig.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConfig.receiveTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SessionService.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_refreshing &&
              error.requestOptions.path != ApiEndpoints.refreshToken) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null) {
              error.requestOptions.headers['Authorization'] =
                  'Bearer $refreshed';
              final response = await dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );

  bool _refreshing = false;

  /// تجديد التوكن المنتهي مرة واحدة عبر الـ Refresh Token المحفوظ.
  Future<String?> _tryRefreshToken() async {
    final session = SessionService.instance;
    final refresh = session.refreshToken;
    if (refresh == null || refresh.isEmpty) return null;
    _refreshing = true;
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refresh': refresh},
      );
      final data = response.data;
      if (data is Map) {
        final newToken =
            data['token']?.toString() ?? data['access']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await session.saveAccessToken(newToken);
          return newToken;
        }
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _refreshing = false;
    }
  }

  /// ينفذ الطلب ويحوّل أي خطأ إلى [ApiException] برسالة قابلة للعرض.
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method).copyWith(headers: options?.headers),
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        messageFromError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// يحوّل خطأ Dio إلى رسالة قابلة للعرض — دالة نقية قابلة للاختبار.
  @visibleForTesting
  static String messageFromError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      for (final value in data.values) {
        if (value is String && value.isNotEmpty) return value;
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
      }
    }
    if (data is String && data.isNotEmpty) return data;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت';
      case DioExceptionType.badResponse:
        return 'حدث خطأ في الخادم (${e.response?.statusCode})';
      default:
        return 'حدث خطأ غير متوقع، حاول مرة أخرى';
    }
  }
}