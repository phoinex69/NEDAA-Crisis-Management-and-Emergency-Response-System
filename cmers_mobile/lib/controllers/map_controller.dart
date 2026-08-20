import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/danger_zone_model.dart';
import '../models/hospital_model.dart';
import '../models/safe_point_model.dart';
import '../models/service_center_model.dart';
import '../models/shelter_model.dart';
import '../services/backend_data_source.dart';
import '../services/notification_service.dart';

class MapController extends GetxController {
  final BackendDataSource _backend = BackendProvider.dataSource;

  final RxBool isLoading = false.obs;
  final RxBool isTracking = false.obs;
  final Rx<LatLng?> userLocation = Rx<LatLng?>(null);
  final RxList<DangerZoneModel> dangerZones = <DangerZoneModel>[].obs;
  final RxList<HospitalModel> hospitals = <HospitalModel>[].obs;
  final RxList<ServiceCenterModel> serviceCenters = <ServiceCenterModel>[].obs;
  final RxList<ShelterModel> shelters = <ShelterModel>[].obs;
  final RxList<SafePointModel> safePoints = <SafePointModel>[].obs;

  StreamSubscription<Position>? _positionSub;
  final Set<String> _armedAlertedZoneIds = {};

  Future<void> loadMapData() async {
    isLoading.value = true;
    final current = userLocation.value;
    try {
      final results = await Future.wait([
        _backend.fetchDangerZones(),
        _backend.fetchHospitals(),
        _backend.fetchServiceCenters(
          latitude: current?.latitude,
          longitude: current?.longitude,
        ),
        _backend.fetchShelters(),
        _backend.fetchSafePoints(),
      ]);
      dangerZones.assignAll(results[0] as List<DangerZoneModel>);
      hospitals.assignAll(results[1] as List<HospitalModel>);
      serviceCenters.assignAll(results[2] as List<ServiceCenterModel>);
      shelters.assignAll(results[3] as List<ShelterModel>);
      safePoints.assignAll(results[4] as List<SafePointModel>);
      _saveCache();
    } catch (_) {
      // بلا شبكة: عرض آخر كاش محفوظ (متطلب 4.9).
      await _loadCache();
    } finally {
      isLoading.value = false;
    }
  }

  /// كاش JSON لنقاط الخريطة في SharedPreferences (متطلب 4.9).
  static const _cacheKey = 'map_points_cache';

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode({
      'zones': dangerZones.map((z) => z.toJson()).toList(),
      'hospitals': hospitals.map((h) => h.toJson()).toList(),
      'centers': serviceCenters.map((c) => c.toJson()).toList(),
      'shelters': shelters.map((s) => s.toJson()).toList(),
      'safePoints': safePoints.map((p) => p.toJson()).toList(),
    }));
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      dangerZones.assignAll(
        (json['zones'] as List? ?? [])
            .map((e) => DangerZoneModel.fromJson(e as Map<String, dynamic>)),
      );
      hospitals.assignAll(
        (json['hospitals'] as List? ?? [])
            .map((e) => HospitalModel.fromJson(e as Map<String, dynamic>)),
      );
      serviceCenters.assignAll(
        (json['centers'] as List? ?? [])
            .map((e) => ServiceCenterModel.fromJson(e as Map<String, dynamic>)),
      );
      shelters.assignAll(
        (json['shelters'] as List? ?? [])
            .map((e) => ShelterModel.fromJson(e as Map<String, dynamic>)),
      );
      safePoints.assignAll(
        (json['safePoints'] as List? ?? [])
            .map((e) => SafePointModel.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {
      // كاش تالف — يُترك فارغاً.
    }
  }

  Future<void> startTracking() async {
    if (isTracking.value) return;

    try {
      await _startPositionStream();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _startPositionStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('خدمة الموقع معطلة',
          'فعّل خدمة تحديد الموقع (GPS) لتفعيل التنبيه المكاني',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD97706),
          colorText: const Color(0xFFFFFFFF));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar('صلاحية الموقع مرفوضة',
          'اسمح بالوصول إلى الموقع للاستفادة من التنبيه المكاني',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) {
      final current = LatLng(position.latitude, position.longitude);
      userLocation.value = current;
      _checkGeofence(current);
      loadServiceCenters(current);
    });

    isTracking.value = true;

    // آخر موقع معروف (إن توفر) يُعرض فوراً بدل ترك المستخدم على شاشة
    // "الموقع مفقود" أثناء انتظار إصلاح GPS جديد، الذي قد يستغرق وقتاً
    // طويلاً أو لا يحدث إطلاقاً في الأماكن المغلقة.
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      userLocation.value = LatLng(lastKnown.latitude, lastKnown.longitude);
    }

    try {
      final immediate = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final current = LatLng(immediate.latitude, immediate.longitude);
      userLocation.value = current;
      _checkGeofence(current);
    } on TimeoutException {
      // لا بأس — آخر موقع معروف (إن وُجد) أو تحديث لاحق من الستريم أعلاه
      // كافيان لعرض الخريطة؛ ستُحدَّث تلقائياً عند توفر إصلاح GPS.
    }
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    isTracking.value = false;
  }

  void _checkGeofence(LatLng position) {
    for (final zone in dangerZones) {
      final inside = _isPointInPolygon(position, zone.boundary);
      if (inside) {
        if (_armedAlertedZoneIds.add(zone.id)) {
          NotificationService.showDangerAlert(
            zoneName: zone.name,
            body: 'أنت داخل منطقة خطر. ${zone.cause}',
          );
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.heavyImpact();
          Get.snackbar(
            '⚠ تنبيه: ${zone.name}',
            'أنت داخل منطقة خطر! ${zone.safetyInstructions.isNotEmpty ? zone.safetyInstructions.first : 'اتبع تعليمات السلامة'}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFCC1C2E),
            colorText: const Color(0xFFFFFFFF),
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        _armedAlertedZoneIds.remove(zone.id);
      }
    }
  }

  /// جلب مراكز الخدمة القريبة من موقع معيّن.
  Future<void> loadServiceCenters(LatLng position) async {
    try {
      final fetched = await _backend.fetchServiceCenters(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      serviceCenters.assignAll(fetched);
    } catch (_) {
      // تُترك القائمة الحالية عند فشل الجلب.
    }
  }

  HospitalModel? nearestHospitalTo(LatLng position) {
    HospitalModel? nearest;
    var minDistance = double.infinity;
    for (final hospital in hospitals) {
      final distance = _distanceInMeters(position, hospital.position);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = hospital;
      }
    }
    return nearest;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    var isInside = false;
    var j = polygon.length - 1;
    for (var i = 0; i < polygon.length; i++) {
      final vi = polygon[i];
      final vj = polygon[j];
      if ((vi.latitude > point.latitude) !=
              (vj.latitude > point.latitude) &&
          (point.longitude <
                  (vj.longitude - vi.longitude) *
                          (point.latitude - vi.latitude) /
                          (vj.latitude - vi.latitude) +
                      vi.longitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  double _distanceInMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final h = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLng / 2), 2);
    return 2 * earthRadius * asin(sqrt(h));
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}