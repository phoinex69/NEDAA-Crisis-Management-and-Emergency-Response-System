/// إعدادات التطبيق العامة.
///
/// التطبيق متصل دائمًا بالـ Backend الحقيقي عبر طلبات HTTP إلى [baseUrl].
/// لا توجد بيانات محلية أو تجريبية — كل البيانات تأتي من الخادم.
class AppConfig {
  AppConfig._();

  /// رابط الخادم (الـ Backend) — جذر الـ API الخاص بجهة المواطن
  /// في خادم NEDAA (cmers_backend) المُشغَّل عبر docker-compose.
  /// - محاكي أندرويد (الهدف): http://10.0.2.2:8000/api/v1 (عنوان الجهاز المضيف من داخل المحاكي)
  /// - جهاز حقيقي: استبدل 10.0.2.2 بعنوان IP جهاز الخادم على نفس الشبكة.
  ///
  /// تذكير: أضف عنوان المضيف إلى ALLOWED_HOSTS في cmers_backend/.env
  /// (الملف الحالي يشمل: localhost,10.0.2.2).
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  /// مهلة الاتصال بالخادم (بالثواني).
  static const int connectTimeoutSeconds = 10;

  /// مهلة استقبال الاستجابة (بالثواني).
  static const int receiveTimeoutSeconds = 20;
}