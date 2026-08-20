/// خطأ موحد يُرمى من طبقة الـ API ليعرضه المتصل مباشرة.
class ApiException implements Exception {
  /// رمز الحالة من الخادم (إن وُجد).
  final int? statusCode;

  /// رسالة قابلة للعرض للمستخدم.
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}