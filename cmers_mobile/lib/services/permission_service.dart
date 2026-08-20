import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// استعلام سريع عن حالة أذونات الموقع والإشعارات وتسجيلها محلياً
/// دون عرض أي نوافذ طلب إذن للمستخدم.
class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  static const _locationKey = 'perm_location';
  static const _notificationKey = 'perm_notifications';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> checkAndRecord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationKey, (await _locationStatus()).name);
      await prefs.setString(
          _notificationKey, await _notificationStatus());
    } catch (_) {
      // في بيئات الاختبار أو عند غياب المنصة نتجاهل بصمت.
    }
  }

  Future<LocationPermission> _locationStatus() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<String> _notificationStatus() async {
    try {
      if (kIsWeb) return 'denied';
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled == true ? 'granted' : 'denied';
    } catch (_) {
      return 'denied';
    }
  }
}