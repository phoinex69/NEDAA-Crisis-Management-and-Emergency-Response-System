import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: settings);
    _initialized = true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> showDangerAlert({
    required String zoneName,
    required String body,
  }) {
    return showNotification(title: 'تنبيه: $zoneName', body: body);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'danger_zone_alerts',
        'تنبيهات المناطق الخطرة',
        channelDescription: 'إشعارات فورية عند دخول منطقة خطر',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
      ),
    );
    await _plugin.show(
      id: title.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}