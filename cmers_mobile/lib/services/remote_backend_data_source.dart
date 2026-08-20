import 'dart:io';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/alert_model.dart';
import '../models/danger_zone_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/hospital_model.dart';
import '../models/medical_card_model.dart';
import '../models/report_model.dart';
import '../models/safe_point_model.dart';
import '../models/service_center_model.dart';
import '../models/shelter_model.dart';
import '../models/user_model.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';
import 'backend_data_source.dart';

/// التنفيذ الحقيقي للـ Backend عبر طلبات HTTP (Dio) لنقاط خادم NEDAA.
///
/// كل دالة هنا تُترجم عقد التطبيق إلى عقد الخادم الفعلي
/// (أسماء الحقول snake_case + أنواع بلاغات الخادم).
class RemoteBackendDataSource implements BackendDataSource {
  final ApiClient _api = ApiClient.instance;

  // ─── المصادقة ───
  /// يطلب رمز تفعيل (أو إعادة إرساله) — الخادم يولّد الرمز ويطبعه بلوقه.
  @override
  Future<void> requestOtp(String phone) async {
    await _api.request(
      ApiEndpoints.resendOtp,
      method: 'POST',
      data: {'identifier': phone},
    );
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    final data = await _api.request(
      ApiEndpoints.verifyOtpUsers,
      method: 'POST',
      data: {'identifier': phone, 'otp_code': code},
    ) as Map<String, dynamic>;
    return _sessionFromTokens(data);
  }

  @override
  Future<UserModel> register({
    required String username,
    required String phone,
    required String password,
  }) async {
    final data = await _api.request(
      ApiEndpoints.register,
      method: 'POST',
      data: {
        'full_name': username,
        'phone': phone,
        'password': password,
        'password_confirm': password,
      },
    ) as Map<String, dynamic>;
    return UserModel(
      id: data['user_id']?.toString() ?? '',
      name: username,
      phone: phone,
    );
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _api.request(
      ApiEndpoints.login,
      method: 'POST',
      data: {'identifier': identifier, 'password': password},
    ) as Map<String, dynamic>;
    return _sessionFromTokens(data);
  }

  @override
  Future<void> requestPasswordReset(String phone) async {
    await _api.request(
      ApiEndpoints.passwordReset,
      method: 'POST',
      data: {'identifier': phone},
    );
  }

  @override
  Future<void> confirmPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await _api.request(
      ApiEndpoints.passwordResetConfirm,
      method: 'POST',
      data: {
        'identifier': phone,
        'otp_code': otp,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
      },
    );
  }

  @override
  Future<AuthSession> verifyOtpUsers({
    required String identifier,
    required String otpCode,
  }) async {
    final data = await _api.request(
      ApiEndpoints.verifyOtpUsers,
      method: 'POST',
      data: {'identifier': identifier, 'otp_code': otpCode},
    ) as Map<String, dynamic>;
    return _sessionFromTokens(data);
  }

  /// يبني جلسة من استجابة {"tokens": {"access","refresh"}, "user": {...}}.
  AuthSession _sessionFromTokens(Map<String, dynamic> data) {
    final tokens = data['tokens'] as Map<String, dynamic>? ?? {};
    final user = data['user'] as Map<String, dynamic>?;
    return AuthSession(
      token: tokens['access']?.toString() ?? '',
      refreshToken: tokens['refresh']?.toString(),
      user: user != null
          ? UserModel.fromJson(user)
          : UserModel(id: '', name: '', phone: ''),
    );
  }

  // ─── الاستغاثة ───
  @override
  Future<void> sendSos({
    required String? emergencyType,
    required double latitude,
    required double longitude,
    required List<String> contactPhones,
  }) async {
    await _api.request(
      ApiEndpoints.sos,
      method: 'POST',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'idempotency_key': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  // ─── البلاغات ───
  @override
  Future<List<ReportModel>> fetchReports(List<ReportModel> current) async {
    final data = await _api.request(ApiEndpoints.reports) as List;
    return data
        .map((item) => _reportFromBackend(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReportModel> submitReport({
    required ReportCategory category,
    required SeverityLevel severity,
    required String description,
    int? victimsCount,
    bool isWitness = false,
    File? imageFile,
    File? audioFile,
    LatLng? position,
  }) async {
    // ملاحظة: الخادم لا يقبل صوراً/ملفات صوتية مع البلاغ العادي
    // (الصوت عبر /reports/voice/ فقط) — تُتجاهل المرفقات هنا.
    final data = await _api.request(
      ApiEndpoints.createReport,
      method: 'POST',
      data: {
        'report_type': _categoryToBackend(category),
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'reported_severity': _severityToBackend(severity),
        'victims_count': victimsCount ?? 0,
        'description': description,
        'submission_method': isWitness ? 'witness' : 'form',
        'idempotency_key': '${DateTime.now().millisecondsSinceEpoch}',
      },
    ) as Map<String, dynamic>;
    return _reportFromBackend(data);
  }

  @override
  Future<ReportModel> submitWitnessReport({LatLng? position}) async {
    // نقطة /reports/witness/ المخصصة: تُنشئ سجل WitnessReport
    // (الواجهة الحالية بضغطة واحدة — الشاهد مجهول ببيان افتراضي).
    final data = await _api.request(
      ApiEndpoints.witnessReport,
      method: 'POST',
      data: {
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'witness_name': 'Anonymous',
        'contact_info': '',
        'statement': 'Witness report submitted.',
      },
    ) as Map<String, dynamic>;
    // الاستجابة مختصرة {"id","status","message"} — نطلب فوراً تفاصيل البلاغ
    // من نقطة GET /reports/:id/ الموجودة، لعرض بطاقة ببيانات الخادم الحقيقية
    // (شارة "بلاغ شاهد" + العنوان + الحالة + الموقع).
    final id = data['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      try {
        final detail =
            await _api.request(ApiEndpoints.reportDetails(id));
        return _reportFromBackend(detail as Map<String, dynamic>);
      } catch (_) {
        // فشل طلب التفاصيل — نموذج بديل محلي ببيانات الإرسال.
      }
    }
    return ReportModel(
      id: id,
      title: 'بلاغ شاهد',
      location: '',
      status: ReportStatus.received,
      category: ReportCategory.other,
      severity: SeverityLevel.medium,
      timeAgo: 'الآن',
      createdAt: DateTime.now(),
      description: null,
      position: position,
      victimsCount: null,
      isWitness: true,
    );
  }

  // ─── البلاغ الصوتي ───
  @override
  Future<String> transcribeAudio(File audioFile) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
    });
    final data = await _api.request(
      ApiEndpoints.voiceReport,
      method: 'POST',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    ) as Map<String, dynamic>;
    return data['transcript']?.toString() ?? '';
  }

  // ─── الخريطة ─────────────────────────────────────────────────
  // ⚠️ ملاحظة مهمة: خادم NEDAA (cmers_backend) لا يوفر حالياً نقاط API
  // للمستشفيات/مراكز الخدمة/مراكز الإيواء/نقاط التجمع الآمنة/مناطق الخطر —
  // لذلك تُرجع الدوال أدناه قوائم فارغة عمداً (لا توجد بيانات تجريبية محلية)،
  // وتُعرض الخريطة بموقع المستخدم فقط.
  // عند إضافة هذه النقاط للباك مستقبلاً: عُدّل كل دالة لإجراء طلب HTTP
  // وتحويل الاستجابة عبر النموذج المقابل (DangerZoneModel, HospitalModel...).
  @override
  Future<List<DangerZoneModel>> fetchDangerZones() async => const [];

  @override
  Future<List<HospitalModel>> fetchHospitals() async => const [];

  @override
  Future<List<ServiceCenterModel>> fetchServiceCenters({
    double? latitude,
    double? longitude,
  }) async =>
      const [];

  @override
  Future<List<ShelterModel>> fetchShelters() async => const [];

  @override
  Future<List<SafePointModel>> fetchSafePoints() async => const [];

  // ─── التنبيهات ───
  @override
  Future<List<AlertModel>> fetchAlerts() async {
    final data = _unwrapResults(await _api.request(ApiEndpoints.alerts));
    return data
        .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ─── البطاقة الطبية ───
  @override
  Future<MedicalCardModel?> fetchMedicalCard() async {
    final data = await _api.request(ApiEndpoints.medicalCard);
    if (data is! Map) return null;
    return MedicalCardModel.fromJson(
        _medicalCardFromBackend(data as Map<String, dynamic>));
  }

  @override
  Future<MedicalCardModel> updateMedicalCard(MedicalCardModel card) async {
    final data = await _api.request(
      ApiEndpoints.medicalCard,
      method: 'PUT',
      data: _medicalCardToBackend(card),
    ) as Map<String, dynamic>;
    return MedicalCardModel.fromJson(_medicalCardFromBackend(data));
  }

  // ─── الملف الشخصي ───
  @override
  Future<UserModel> updateProfile({required String name}) async {
    final data = await _api.request(
      ApiEndpoints.profile,
      method: 'PUT',
      data: {'full_name': name},
    ) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<List<EmergencyContactModel>> fetchContacts() async {
    final data = _unwrapResults(await _api.request(ApiEndpoints.contacts));
    return data
        .map((item) => _contactFromBackend(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EmergencyContactModel> addContact({
    required String name,
    required String relation,
    required String phone,
  }) async {
    // الخادم لا يخزّن الصلة — يُرسل الاسم والجوال فقط، وتُحفظ الصلة محلياً.
    final data = await _api.request(
      ApiEndpoints.contacts,
      method: 'POST',
      data: {'name': name, 'phone_number': phone},
    ) as Map<String, dynamic>;
    return _contactFromBackend(data);
  }

  @override
  Future<EmergencyContactModel> updateContact({
    required String id,
    required String name,
    required String relation,
    required String phone,
  }) async {
    // الخادم لا يخزّن الصلة — تُرسل الاسم والجوال فقط.
    final data = await _api.request(
      ApiEndpoints.updateContact(id),
      method: 'PUT',
      data: {'name': name, 'phone_number': phone},
    ) as Map<String, dynamic>;
    return _contactFromBackend(data);
  }

  @override
  Future<void> deleteContact(String id) async {
    await _api.request(
      ApiEndpoints.deleteContact(id),
      method: 'DELETE',
    );
  }

  // ─── ترجمة عقد التطبيق ↔ عقد الخادم ──────────────────────────

  /// فئة التطبيق → نوع البلاغ في الخادم (report_type).
  String _categoryToBackend(ReportCategory category) {
    switch (category) {
      case ReportCategory.ambulance:
        return 'medical';
      case ReportCategory.fire:
        return 'fire';
      case ReportCategory.police:
        return 'security';
      case ReportCategory.rescue:
        return 'accident';
      case ReportCategory.naturalDisaster:
        return 'flood';
      case ReportCategory.buildingCollapse:
        return 'other';
      case ReportCategory.roadClosure:
        return 'other';
      case ReportCategory.other:
        return 'other';
    }
  }

  /// نوع البلاغ من الخادم → فئة التطبيق.
  ReportCategory _categoryFromBackend(String? value) {
    switch (value) {
      case 'accident':
        return ReportCategory.rescue;
      case 'fire':
        return ReportCategory.fire;
      case 'medical':
        return ReportCategory.ambulance;
      case 'flood':
        return ReportCategory.naturalDisaster;
      case 'security':
        return ReportCategory.police;
      default:
        return ReportCategory.other;
    }
  }

  /// خطورة التطبيق → رقم 1..5 في الخادم.
  int _severityToBackend(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return 5;
      case SeverityLevel.high:
        return 4;
      case SeverityLevel.medium:
        return 3;
      case SeverityLevel.low:
        return 2;
    }
  }

  /// رقم 1..5 من الخادم → خطورة التطبيق.
  SeverityLevel _severityFromBackend(num? value) {
    final v = value?.toInt() ?? 3;
    if (v >= 5) return SeverityLevel.critical;
    if (v == 4) return SeverityLevel.high;
    if (v == 3) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  /// حالة الخادم → حالة التطبيق — يفوّض إلى [reportStatusFromApi] كمصدر
  /// وحيد للترجمة (كانت هذه دالة مكررة تجمّع كل شيء تحت "processing").
  ReportStatus _statusFromBackend(String? value) => reportStatusFromApi(value);

  /// استجابة بلاغ من الخادم → نموذج التطبيق.
  ReportModel _reportFromBackend(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lng = json['longitude'];
    final description = json['description']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final isWitness = json['submission_method'] == 'witness';
    return ReportModel(
      id: json['id']?.toString() ?? '',
      // بلاغ الشاهد يعرض عنواناً عربياً ثابتاً بدل عنوان السيرفر الإنجليزي.
      title: isWitness
          ? 'بلاغ شاهد'
          : (title.isNotEmpty ? title : (description.isNotEmpty ? description : 'بلاغ طوارئ')),
      location: '',
      status: _statusFromBackend(json['status']?.toString()),
      category: _categoryFromBackend(json['report_type']?.toString()),
      severity: _severityFromBackend(json['reported_severity'] as num?),
      timeAgo: 'الآن',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      description: description.isEmpty ? null : description,
      position: (lat != null && lng != null)
          ? LatLng((lat as num).toDouble(), (lng as num).toDouble())
          : null,
      victimsCount: (json['victims_count'] as num?)?.toInt(),
      isWitness: isWitness,
    );
  }

  /// استجابة جهة اتصال من الخادم → نموذج التطبيق.
  EmergencyContactModel _contactFromBackend(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relation: json['relationship']?.toString() ?? '',
      phone: json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
    );
  }

  /// استجابة البطاقة الطبية من الخادم → صيغة التطبيق (camelCase).
  ///
  /// الخادم يخزّن الحساسيات/الأمراض/الأدوية كنص واحد يفصل بين قيمه
  /// بأسطر جديدة (TextField) — تُحوَّل إلى قائمة قيم هنا.
  Map<String, dynamic> _medicalCardFromBackend(Map<String, dynamic> json) {
    return {
      'bloodType': json['blood_type'],
      'allergies': _splitMedicalList(json['allergies']),
      'chronicDiseases': _splitMedicalList(json['chronic_conditions']),
      'medications': _splitMedicalList(json['medications']),
    };
  }

  /// نموذج التطبيق → صيغة الخادم (snake_case).
  ///
  /// القوائم تُدمج في نص واحد (أسطر جديدة) لأن حقول الخادم من نوع نصي.
  Map<String, dynamic> _medicalCardToBackend(MedicalCardModel card) {
    return {
      if (card.bloodType != null) 'blood_type': card.bloodType,
      'allergies': card.allergies.join('\n'),
      'chronic_conditions': card.chronicDiseases.join('\n'),
      'medications': card.medications.join('\n'),
    };
  }

  /// يقسّم نصاً قادماً من الخادم (أسطر/فواصل) إلى قائمة قيم نظيفة.
  List<String> _splitMedicalList(Object? value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return (value?.toString() ?? '')
        .split(RegExp(r'[\n,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// يفكك استجابة مُرقّمة من الخادم: بعض نقاط القوائم في NEDAA مرصّدة
  /// وتُعاد داخل {"count", "next", "previous", "results": [...]} —
  /// تُرجع عناصر "results" في تلك الحالة، والقائمة كما هي خلاف ذلك.
  List _unwrapResults(dynamic data) {
    if (data is Map && data['results'] is List) {
      return data['results'] as List;
    }
    return data as List;
  }
}
