import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nidaa_app/services/api/api_client.dart';

void main() {
  Response<dynamic> responseWith(Object? data, int statusCode) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: statusCode,
      data: data,
    );
  }

  DioException errorOf(DioExceptionType type, {Response<dynamic>? response}) {
    return DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: response,
    );
  }

  group('ApiClient.messageFromError', () {
    test('يستخرج message من جسم JSON', () {
      final e = errorOf(
        DioExceptionType.badResponse,
        response: responseWith({'message': 'رقم الهاتف غير موجود'}, 400),
      );
      expect(ApiClient.messageFromError(e), 'رقم الهاتف غير موجود');
    });

    test('يستخرج detail عندما لا يوجد message', () {
      final e = errorOf(
        DioExceptionType.badResponse,
        response: responseWith({'detail': 'otp_required'}, 403),
      );
      expect(ApiClient.messageFromError(e), 'otp_required');
    });

    test('يستخرج أول رسالة من قائمة أخطاء الحقول', () {
      final e = errorOf(
        DioExceptionType.badResponse,
        response: responseWith({
          'username': ['هذا الحقل مطلوب', 'قصير جداً'],
        }, 400),
      );
      expect(ApiClient.messageFromError(e), 'هذا الحقل مطلوب');
    });

    test('يقبل استجابة نصية مباشرة', () {
      final e = errorOf(
        DioExceptionType.badResponse,
        response: responseWith('خطأ غير متوقع', 500),
      );
      expect(ApiClient.messageFromError(e), 'خطأ غير متوقع');
    });

    test('رسالة انتهاء المهلة بالعربية', () {
      final e = errorOf(DioExceptionType.connectionTimeout);
      expect(ApiClient.messageFromError(e), contains('مهلة'));
    });

    test('رسالة انقطاع الاتصال بالعربية', () {
      final e = errorOf(DioExceptionType.connectionError);
      expect(ApiClient.messageFromError(e), contains('الاتصال'));
    });

    test('رسالة خطأ الخادم بدون جسم', () {
      final e = errorOf(
        DioExceptionType.badResponse,
        response: responseWith(null, 503),
      );
      expect(ApiClient.messageFromError(e), contains('503'));
    });
  });
}