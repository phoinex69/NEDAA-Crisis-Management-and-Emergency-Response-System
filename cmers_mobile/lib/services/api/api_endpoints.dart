/// عقد الـ REST API الفعلي لخادم NEDAA (cmers_backend).
///
/// جميع الطلبات تُرسل بـ JSON، وتُرجع استجابات وفق الشكل التالي:
/// - النجاح: كائن/قائمة JSON مباشرة.
/// - الخطأ: أخطاء الحقول `{"field": ["رسالة"]}` أو `{"detail": "..."}` مع رمز حالة مناسب (400/401/404/5xx).
///
/// المسارات هنا مطابقة لنقاط الباك الحقيقية تحت جذر `api/v1`.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── المصادقة ────────────────────────────────────────────────
  /// POST /users/register/ — إنشاء حساب مواطن.
  /// الجسم: {"full_name", "phone", "password", "password_confirm"} (+ email اختياري)
  /// الاستجابة 201: {"message", "user_id", "identifier"} — الحساب يبدأ غير مفعّل
  /// ويتطلب التحقق عبر [verifyOtpUsers] (الرمز يُطبع في لوق الخادم).
  static const String register = '/users/register/';

  /// POST /users/login/ — دخول المواطن بالبريد الإلكتروني أو رقم الهاتف.
  /// الجسم: {"identifier": "...", "password": "..."}
  /// الاستجابة: {"message", "tokens": {"access","refresh"}, "user": {...}}
  static const String login = '/users/login/';

  /// POST /users/password-reset/ — استعادة كلمة المرور.
  /// الجسم: {"identifier": "..."} — الخادم يطبع الـ OTP بلوقه.
  static const String passwordReset = '/users/password-reset/';

  /// POST /users/password-reset/confirm/ — تعيين كلمة مرور جديدة.
  /// الجسم: {"identifier", "otp_code", "new_password", "new_password_confirm"}
  static const String passwordResetConfirm = '/users/password-reset/confirm/';

  /// POST /users/verify-otp/ — تفعيل الحساب (أو التحقق بالرمز) بعد التسجيل.
  /// الجسم: {"identifier": "...", "otp_code": "..."}
  /// الاستجابة: {"message", "tokens": {"access","refresh"}, "user": {...}}
  static const String verifyOtpUsers = '/users/verify-otp/';

  /// POST /users/resend-otp/ — إعادة إرسال رمز التفعيل.
  /// الجسم: {"identifier": "..."}
  static const String resendOtp = '/users/resend-otp/';

  /// POST /users/token/refresh/ — تجديد توكن الوصول المنتهي.
  /// الجسم: {"refresh": "..."} — الاستجابة: {"access": "...", "refresh": "..."}
  static const String refreshToken = '/users/token/refresh/';

  // ─── الاستغاثة ───────────────────────────────────────────────
  /// POST /reports/sos/ — استغاثة فورية.
  /// الجسم: {"latitude", "longitude"} — الخادم يُشعر جهات اتصال الطوارئ تلقائياً.
  static const String sos = '/reports/sos/';

  // ─── البلاغات ────────────────────────────────────────────────
  /// GET /reports/my/ — قائمة بلاغات المستخدم الحالي (مرتبة تنازلياً).
  static const String reports = '/reports/my/';

  /// POST /reports/ — إنشاء بلاغ.
  /// الجسم (JSON): {"report_type", "latitude", "longitude",
  ///  "reported_severity": 1..5, "victims_count", "description", "submission_method"}
  /// الاستجابة: كائن البلاغ كما في GET.
  static const String createReport = '/reports/';

  /// POST /reports/witness/ — بلاغ شاهد عيان بضغطة واحدة (متطلب 4.8).
  /// الجسم: {"latitude","longitude","witness_name","contact_info","statement"}
  /// الاستجابة: {"id","status","message"} — يُنشئ سجل WitnessReport فعلياً.
  static const String witnessReport = '/reports/witness/';

  /// GET /reports/:id/ — تفاصيل بلاغ.
  static String reportDetails(String id) => '/reports/$id/';

  /// GET /reports/:id/status/ — حالة البلاغ مع الوحدة المستجيبة والـ ETA.
  /// {"id","status","assigned_unit","eta_minutes","message"}
  static String reportStatus(String id) => '/reports/$id/status/';

  // ─── البلاغ الصوتي ───────────────────────────────────────────
  /// POST /reports/voice/ — بلاغ صوتي مع تحويل تلقائي إلى نص.
  /// multipart: ملف audio. الاستجابة: {"id","status","transcript","audio_url"}.
  static const String voiceReport = '/reports/voice/';

  // ─── التنبيهات ───────────────────────────────────────────────
  /// GET /notifications/ — تنبيهات وإشعارات المواطن الشخصية.
  /// {"id","type","title","message","is_read","is_broadcast","created_at"}
  static const String alerts = '/notifications/';

  // ─── الملف الشخصي ────────────────────────────────────────────
  /// GET/PUT /users/profile/ — عرض/تحديث الملف الشخصي.
  /// PUT: {"full_name": "..."} — الاستجابة: {"id","full_name","email","phone",...}
  static const String profile = '/users/profile/';

  /// GET/POST /users/profile/emergency-contacts/ — جهات اتصال الطوارئ.
  /// {"id","name","phone_number"} — لا يوجد حقل "علاقة" في الخادم.
  static const String contacts = '/users/profile/emergency-contacts/';

  /// DELETE /users/profile/emergency-contacts/:id/ — حذف جهة.
  static String deleteContact(String id) => '/users/profile/emergency-contacts/$id/';

  /// PUT /users/profile/emergency-contacts/:id/ — تعديل جهة.
  static String updateContact(String id) => '/users/profile/emergency-contacts/$id/';

  // ─── البطاقة الطبية الطارئة ──────────────────────────────────
  /// GET/PUT /users/profile/medical/ — البطاقة الطبية.
  /// {"id","blood_type","allergies":[],"chronic_conditions":[],"medications":[]}
  /// الخادم يعيدها دائماً (لا يوجد تقييد ببلاغ طبي نشط).
  static const String medicalCard = '/users/profile/medical/';
}
