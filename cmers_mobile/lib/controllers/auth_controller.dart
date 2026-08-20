import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../models/user_model.dart';
import '../services/api/api_exception.dart';
import '../services/backend_data_source.dart';
import '../services/session_service.dart';
import 'profile_controller.dart';

class AuthController extends GetxController {
  // شاشة الدخول بكلمة المرور (متطلب 4.1)
  final loginIdentifierController = TextEditingController();
  final passwordController = TextEditingController();
  final RxInt loginTabIndex = 0.obs;

  // شاشة إنشاء الحساب (متطلب 4.1)
  final regUsernameController = TextEditingController();
  final regPhoneController = TextEditingController();
  final regPasswordController = TextEditingController();
  final regConfirmController = TextEditingController();
  final RxBool isRegistering = false.obs;

  // استعادة كلمة المرور (متطلب 4.1)
  final resetPhoneController = TextEditingController();
  final resetOtpController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final resetConfirmController = TextEditingController();
  final RxBool resetRequested = false.obs;
  final RxBool isResetting = false.obs;

  // التحقق الثنائي (2FA): معرّف المستخدم المنتظر للتحقق بالرمز
  final RxString pendingIdentifier = ''.obs;

  // الدخول السريع برمز OTP على الجوال
  final phoneController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString otpCode = ''.obs;
  final RxInt countdownSeconds = 60.obs;
  final RxBool canResend = false.obs;
  final RxString otpError = ''.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  final BackendDataSource _backend = BackendProvider.dataSource;
  Timer? _countdownTimer;

  bool get twoFactorMode => pendingIdentifier.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _restoreFromSession();
    _startCountdown();
  }

  /// استرجاع الجلسة المحفوظة عند إقلاع التطبيق.
  void _restoreFromSession() {
    final userJson = SessionService.instance.userJson;
    if (userJson == null) return;
    try {
      currentUser.value =
          UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      SessionService.instance.clear();
    }
  }

  void setOtp(String value) {
    otpCode.value = value;
    if (otpError.isNotEmpty) otpError.value = '';
  }

  /// يحوّل رقم الجوال المحلي (09xxxxxxxx) إلى الصيغة الدولية السورية (+9639xxxxxxxx).
  String _normalizeSyrianPhone(String phone) {
    var p = phone.trim();
    if (p.startsWith('09') && p.length == 10) {
      return '+963${p.substring(1)}';
    }
    return p;
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFCC1C2E),
      colorText: const Color(0xFFFFFFFF),
    );
  }

  // ─── الدخول بكلمة المرور ────────────────────────────────────

  /// دخول المواطن بالبريد الإلكتروني أو رقم الهاتف وكلمة المرور (متطلب 4.1).
  Future<void> loginWithPassword() async {
    // نفس تحويل التسجيل: 09xxxxxxxx → +9639xxxxxxxx (البريد يبقى كما هو).
    final identifier = _normalizeSyrianPhone(loginIdentifierController.text.trim());
    final password = passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showError('خطأ', 'الرجاء إدخال البريد/الجوال وكلمة المرور');
      return;
    }
    isLoading.value = true;
    try {
      final session =
          await _backend.login(identifier: identifier, password: password);
      await _saveSession(session);
      isLoading.value = false;
      if (session.user.name.trim().isEmpty) {
        await _promptForName();
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } on ApiException catch (e) {
      isLoading.value = false;
      // الدخول العادي لا يمر بشاشة OTP إطلاقاً — أي خطأ (بما فيه
      // "الحساب غير مفعّل") يظهر كرسالة فقط.
      _showError('تعذر الدخول', e.message);
    } catch (e) {
      isLoading.value = false;
      _showError('تعذر الدخول', e.toString());
    }
  }

  /// إنشاء حساب جديد: اسم مستخدم + جوال + كلمة مرور (متطلب 4.1).
  Future<void> registerAccount() async {
    final username = regUsernameController.text.trim();
    final phone = regPhoneController.text.trim();
    final password = regPasswordController.text;
    final confirm = regConfirmController.text;
    if (username.isEmpty || phone.isEmpty) {
      _showError('خطأ', 'الرجاء إدخال اسم المستخدم ورقم الهاتف');
      return;
    }
    if (password.length < 8) {
      _showError('خطأ', 'كلمة المرور يجب ألا تقل عن 8 أحرف');
      return;
    }
    if (password != confirm) {
      _showError('خطأ', 'كلمتا المرور غير متطابقتين');
      return;
    }
    isRegistering.value = true;
    try {
      final normalizedPhone = _normalizeSyrianPhone(phone);
      await _backend.register(
        username: username,
        phone: normalizedPhone,
        password: password,
      );
      isRegistering.value = false;
      // الحساب الجديد غير مفعّل بعد — الانتقال لشاشة OTP فوراً
      // (الرمز يظهر في لوق الخادم) ثم الدخول تلقائياً بعد التفعيل.
      pendingIdentifier.value = normalizedPhone;
      otpCode.value = '';
      _startCountdown();
      Get.toNamed(AppRoutes.otp);
    } catch (e) {
      isRegistering.value = false;
      _showError('تعذر إنشاء الحساب', e.toString());
    }
  }

  // ─── استعادة كلمة المرور ────────────────────────────────────

  /// يطلب رمز إعادة التعيين (الخادم يطبعه بلوقه — وهمي).
  Future<void> requestPasswordReset() async {
    final phone = resetPhoneController.text.trim();
    if (phone.isEmpty) {
      _showError('خطأ', 'الرجاء إدخال رقم الهاتف');
      return;
    }
    isResetting.value = true;
    try {
      await _backend.requestPasswordReset(_normalizeSyrianPhone(phone));
      isResetting.value = false;
      resetRequested.value = true;
      _startCountdown();
    } catch (e) {
      isResetting.value = false;
      _showError('تعذر الإرسال', e.toString());
    }
  }

  /// يؤكد إعادة التعيين بالرمز وكلمة المرور الجديدة.
  Future<void> confirmPasswordReset() async {
    final otp = resetOtpController.text.trim();
    final password = resetPasswordController.text;
    final confirm = resetConfirmController.text;
    if (otp.length < 6) {
      _showError('خطأ', 'الرجاء إدخال الرمز كاملاً');
      return;
    }
    if (password.length < 8) {
      _showError('خطأ', 'كلمة المرور يجب ألا تقل عن 8 أحرف');
      return;
    }
    if (password != confirm) {
      _showError('خطأ', 'كلمتا المرور غير متطابقتين');
      return;
    }
    isResetting.value = true;
    try {
      await _backend.confirmPasswordReset(
        phone: _normalizeSyrianPhone(resetPhoneController.text.trim()),
        otp: otp,
        newPassword: password,
      );
      isResetting.value = false;
      Get.snackbar(
        AppStrings.passwordResetSuccess,
        '',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF157F3D),
        colorText: const Color(0xFFFFFFFF),
      );
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      isResetting.value = false;
      _showError('تعذر التغيير', e.toString());
    }
  }

  // ─── الدخول السريع برمز OTP (الجوال) ─────────────────────────

  /// يطلب رمز تحقق من الخادم (الخادم يولّد رمزاً وهمياً ويطبعه بلوقه).
  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('خطأ', 'الرجاء إدخال رقم الجوال');
      return;
    }
    isLoading.value = true;
    try {
      await _backend.requestOtp(_normalizeSyrianPhone(phone));
      isLoading.value = false;
      otpCode.value = '';
      _startCountdown();
      Get.toNamed(AppRoutes.otp, arguments: phone);
    } catch (e) {
      isLoading.value = false;
      _showError('تعذر الإرسال', e.toString());
    }
  }

  /// تحقق OTP: ثنائي (بعد الدخول) أو دخول سريع بالجوال.
  Future<void> verifyOtp() async {
    if (otpCode.value.length < 6) {
      _showError('خطأ', 'الرجاء إدخال الرمز كاملاً');
      return;
    }
    isLoading.value = true;
    try {
      final AuthSession session;
      if (twoFactorMode) {
        session = await _backend.verifyOtpUsers(
          identifier: pendingIdentifier.value,
          otpCode: otpCode.value,
        );
      } else {
        session = await _backend.verifyOtp(
          _normalizeSyrianPhone(phoneController.text.trim()),
          otpCode.value,
        );
      }
      await _saveSession(session);
      pendingIdentifier.value = '';
      isLoading.value = false;
      if (session.user.name.trim().isEmpty) {
        // أول تسجيل (متطلب 4.1): طلب الاسم لتكوين الحساب.
        await _promptForName();
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      isLoading.value = false;
      otpError.value = e.toString();
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    await SessionService.instance.saveSession(
      token: session.token,
      userJson: jsonEncode(session.user.toJson()),
      refreshToken: session.refreshToken,
    );
    currentUser.value = session.user;
  }

  /// أول تسجيل: حوار إدخال الاسم — يُحفظ عبر [ProfileController.updateName].
  Future<void> _promptForName() async {
    final nameCtrl = TextEditingController();
    final saved = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.welcomeNameTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.welcomeNameBody),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              textDirection: TextDirection.rtl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppStrings.skip),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.save),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    final name = nameCtrl.text.trim();
    try {
      if (saved == true && name.isNotEmpty) {
        await Get.find<ProfileController>().updateName(name);
        // الحوار أُغلق للتو — ننتظر نهاية حركة الإغلاق قبل الإشعار.
        await Future.delayed(const Duration(milliseconds: 350));
        Get.snackbar('تم الحفظ', 'تم تحديث اسم المستخدم',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      // تأجيل الإتلاف حتى تنتهي حركة إغلاق الحوار (يمنع كراش _dependents).
      Future.delayed(const Duration(milliseconds: 400), nameCtrl.dispose);
    }
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> logout() async {
    await SessionService.instance.clear();
    currentUser.value = null;
    pendingIdentifier.value = '';
    Get.offAllNamed(AppRoutes.login);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    countdownSeconds.value = 60;
    canResend.value = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (countdownSeconds.value > 0) {
        countdownSeconds.value--;
      } else {
        canResend.value = true;
        _countdownTimer?.cancel();
      }
    });
  }

  void resendOtp() {
    if (!canResend.value) return;
    otpError.value = '';
    // بعد التسجيل (وضع 2FA) يُعاد الإرسال للمعرّف المُعلَّق نفسه عبر الخادم.
    if (twoFactorMode) {
      _requestPendingOtp();
      _startCountdown();
      return;
    }
    sendOtp();
    _startCountdown();
  }

  /// إعادة إرسال رمز التفعيل للمعرّف المُعلَّق (بعد التسجيل مباشرة).
  Future<void> _requestPendingOtp() async {
    try {
      await _backend.requestOtp(pendingIdentifier.value);
    } catch (e) {
      _showError('تعذر الإرسال', e.toString());
    }
  }

  void resendResetCode() {
    if (!canResend.value) return;
    resetOtpController.clear();
    requestPasswordReset();
  }

  String get formattedCountdown {
    final m = (countdownSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (countdownSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    loginIdentifierController.dispose();
    passwordController.dispose();
    regUsernameController.dispose();
    regPhoneController.dispose();
    regPasswordController.dispose();
    regConfirmController.dispose();
    resetPhoneController.dispose();
    resetOtpController.dispose();
    resetPasswordController.dispose();
    resetConfirmController.dispose();
    super.onClose();
  }
}