import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'remote_backend_data_source.dart';

/// نتيجة التحقق من رمز OTP من الخادم.
class AuthSession {
  final String token;
  final String? refreshToken;
  final UserModel user;

  const AuthSession({
    required this.token,
    this.refreshToken,
    required this.user,
  });
}

/// واجهة موحدة للـ Backend.
///
/// التنفيذ الحقيقي الوحيد هو [RemoteBackendDataSource] عبر طلبات HTTP
/// إلى [AppConfig.baseUrl]. لا توجد بيانات محلية أو تجريبية.
abstract class BackendDataSource {
  // ─── المصادقة ───
  Future<void> requestOtp(String phone);

  Future<AuthSession> verifyOtp(String phone, String code);

  /// إنشاء حساب جديد (متطلب 4.1): اسم مستخدم + جوال + كلمة مرور.
  Future<UserModel> register({
    required String username,
    required String phone,
    required String password,
  });

  /// دخول بالبريد الإلكتروني أو رقم الهاتف وكلمة مرور (متطلب 4.1).
  /// يرمي [ApiException] برمز 403 عند الحاجة للتحقق الثنائي — يُستكمل
  /// عبر [verifyOtpUsers].
  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  /// طلب رمز إعادة تعيين كلمة المرور (الخادم يطبعه بلوقه).
  Future<void> requestPasswordReset(String phone);

  /// تأكيد إعادة التعيين برمز الـ OTP وكلمة مرور جديدة.
  Future<void> confirmPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  });

  /// التحقق الثنائي بالرمز بعد الدخول بكلمة المرور (متطلب 4.1).
  Future<AuthSession> verifyOtpUsers({
    required String identifier,
    required String otpCode,
  });

  // ─── الاستغاثة ───
  Future<void> sendSos({
    required String? emergencyType,
    required double latitude,
    required double longitude,
    required List<String> contactPhones,
  });

  // ─── البلاغات ───
  Future<List<ReportModel>> fetchReports(List<ReportModel> current);

  Future<ReportModel> submitReport({
    required ReportCategory category,
    required SeverityLevel severity,
    required String description,
    int? victimsCount,
    bool isWitness,
    File? imageFile,
    File? audioFile,
    LatLng? position,
  });

  /// بلاغ شاهد عيان بضغطة واحدة (متطلب 4.8): يُرسل إلى /reports/witness/
  /// فيُنشأ سجل WitnessReport فعلي في الخادم.
  Future<ReportModel> submitWitnessReport({LatLng? position});

  // ─── البلاغ الصوتي (4.3) ───
  /// يحوّل ملفاً صوتياً إلى نص (Whisper عند الخادم).
  Future<String> transcribeAudio(File audioFile);

  // ─── الخريطة ───
  Future<List<DangerZoneModel>> fetchDangerZones();

  Future<List<HospitalModel>> fetchHospitals();

  /// مراكز الخدمة (شرطة/دفاع مدني...) القريبة من موقع المستخدم.
  Future<List<ServiceCenterModel>> fetchServiceCenters({
    double? latitude,
    double? longitude,
  });

  /// مراكز الإيواء (متطلب 4.6).
  Future<List<ShelterModel>> fetchShelters();

  /// نقاط التجمع الآمنة (متطلب 4.6).
  Future<List<SafePointModel>> fetchSafePoints();

  // ─── التنبيهات (4.5) ───
  Future<List<AlertModel>> fetchAlerts();

  // ─── البطاقة الطبية (4.7) ───
  Future<MedicalCardModel?> fetchMedicalCard();

  Future<MedicalCardModel> updateMedicalCard(MedicalCardModel card);

  // ─── الملف الشخصي ───
  Future<UserModel> updateProfile({required String name});

  Future<List<EmergencyContactModel>> fetchContacts();

  Future<EmergencyContactModel> addContact({
    required String name,
    required String relation,
    required String phone,
  });

  Future<EmergencyContactModel> updateContact({
    required String id,
    required String name,
    required String relation,
    required String phone,
  });

  Future<void> deleteContact(String id);
}

/// يوفّر التنفيذ الحقيقي الوحيد للـ Backend (طلبات HTTP).
class BackendProvider {
  BackendProvider._();

  static BackendDataSource? _dataSource;

  static BackendDataSource get dataSource {
    return _dataSource ??= RemoteBackendDataSource();
  }

  /// يعيد ضبط المزود (للاختبارات).
  @visibleForTesting
  static void reset() => _dataSource = null;

  /// يحقن تنفيذاً وهمياً (للاختبارات).
  @visibleForTesting
  static void overrideForTesting(BackendDataSource dataSource) =>
      _dataSource = dataSource;
}