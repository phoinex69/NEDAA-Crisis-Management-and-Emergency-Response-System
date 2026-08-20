import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../services/backend_data_source.dart';
import '../services/notification_service.dart';
import 'profile_controller.dart';

class SosController extends GetxController {
  static const double holdDurationSeconds = 1.5;
  static const int countdownSeconds = 5;

  final BackendDataSource _backend = BackendProvider.dataSource;

  final RxBool isHolding = false.obs;
  final RxDouble holdProgress = 0.0.obs;
  final RxBool isSosActive = false.obs;
  final RxBool isSending = false.obs;
  final RxInt countdown = countdownSeconds.obs;
  final Rx<LatLng?> userLocation = Rx<LatLng?>(null);

  Timer? _holdTimer;
  Timer? _countdownTimer;

  /// يبدأ الامتلاء التدريجي أثناء الضغط المطول على زر الاستغاثة.
  void startHold() {
    if (isSosActive.value) return;
    isHolding.value = true;
    holdProgress.value = 0.0;
    HapticFeedback.heavyImpact();
    const tickMs = 30;
    const step = tickMs / (holdDurationSeconds * 1000);
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      holdProgress.value += step;
      if (holdProgress.value >= 1.0) {
        timer.cancel();
        _holdTimer = null;
        isHolding.value = false;
        completeHold();
      }
    });
  }

  /// يُلغى عند رفع الإصبع قبل اكتمال الامتلاء.
  void cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    isHolding.value = false;
    holdProgress.value = 0.0;
  }

  /// اكتمل الضغط المطول: فحص GPS فوري، جلب الإحداثيات،
  /// ثم الانتقال مباشرة لشاشة تصنيف البلاغ (مسار البلاغ الكامل).
  Future<void> completeHold() async {
    try {
      if (!await _ensureLocationEnabled()) return;
      await _fetchLocation();
      Get.toNamed(AppRoutes.reportCategory);
    } on MissingPluginException {
      Get.toNamed(AppRoutes.reportCategory);
    } on PlatformException {
      Get.toNamed(AppRoutes.reportCategory);
    }
  }

  /// الاستغاثة بضغطة واحدة (متطلب 4.2): يتحقق من الموقع ثم يبدأ
  /// العد التنازلي القابل للإلغاء ثم يرسل POST /sos مع جهات الاتصال.
  Future<void> requestSos() async {
    if (isSosActive.value || isSending.value) return;
    try {
      if (!await _ensureLocationEnabled()) return;
      await _fetchLocation();
    } on MissingPluginException {
      // بدون إضافة الموقع يبقى التدفق صالحاً — سيُطلب الموقع عند الإرسال.
    } on PlatformException {
      return;
    }
    startSosFlow();
  }

  /// الانتقال لشاشة العد التنازلي والبدء فوراً بجلب الإحداثيات.
  void startSosFlow() {
    isSosActive.value = true;
    countdown.value = countdownSeconds;
    Get.toNamed(AppRoutes.sosCountdown);
    _fetchLocation();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 1) {
        timer.cancel();
        _countdownTimer = null;
        sendSos();
      } else {
        countdown.value--;
      }
    });
  }

  Future<bool> _ensureLocationEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showEnableLocationDialog();
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar(AppStrings.locationPermissionTitle,
          AppStrings.locationPermissionBody,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
      return false;
    }
    return true;
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      userLocation.value = LatLng(position.latitude, position.longitude);
    } catch (_) {
      // فشل تحديد الموقع — يبقى userLocation بلا قيمة
      // ويُعرض للمستخدم زر إعادة المحاولة في شاشة الاستغاثة.
    }
  }

  void cancelSos() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    isSosActive.value = false;
    Get.back();
  }

  /// إرسال الاستغاثة للخادم مع الإحداثيات وجهات الطوارئ،
  /// ثم الانتقال لشاشة اختيار نوع الطوارئ لاستكمال البلاغ إن أراد المستخدم.
  /// الخادم يُشعر جهات اتصال الطوارئ (العائلة) تلقائياً (متطلب 4.5).
  Future<void> sendSos() async {
    final location = userLocation.value;
    if (location == null) {
      Get.snackbar(
        'تعذر تحديد الموقع',
        AppStrings.sosNoLocation,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFCC1C2E),
        colorText: const Color(0xFFFFFFFF),
      );
      isSosActive.value = false;
      return;
    }
    isSending.value = true;
    try {
      final profile = Get.find<ProfileController>();
      final phones =
          profile.emergencyContacts.map((c) => c.phone).toList();

      // نوع الطوارئ يُحدد لاحقاً في شاشة الفئة ويُرسل مع البلاغ الكامل.
      await _backend.sendSos(
        emergencyType: null,
        latitude: location.latitude,
        longitude: location.longitude,
        contactPhones: phones,
      );

      await NotificationService.showNotification(
        title: AppStrings.sosSentTitle,
        body:
            '${AppStrings.sosSentBody} (${location.latitude.toStringAsFixed(4)}, '
            '${location.longitude.toStringAsFixed(4)})',
      );

      Get.snackbar(
        AppStrings.sosSentTitle,
        AppStrings.sosSentBody,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );

      isSosActive.value = false;
      Get.offNamed(AppRoutes.reportCategory);
    } catch (e) {
      Get.snackbar(
        'تعذر إرسال الاستغاثة',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFCC1C2E),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isSending.value = false;
    }
  }

  void _showEnableLocationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.enableLocationTitle),
        content: Text(AppStrings.enableLocationBody),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              Geolocator.openLocationSettings();
            },
            child: Text(AppStrings.enableNow),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    super.onClose();
  }
}