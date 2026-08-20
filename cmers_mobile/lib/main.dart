import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/app.dart';
import 'controllers/accessibility_controller.dart';
import 'core/localization/locale_service.dart';
import 'services/map_offline_service.dart';
import 'services/notification_service.dart';
import 'services/offline_queue_service.dart';
import 'services/realtime_service.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await SessionService.instance.init();
  await MapOfflineService.initFmtc();
  final locale = LocaleService();
  await locale.restore();
  Get.put(locale);
  final offline = OfflineQueueService();
  await offline.init();
  Get.put(offline);
  final accessibility = AccessibilityController();
  await accessibility.init();
  Get.put(accessibility);
  final realtime = RealtimeService();
  await realtime.init();
  Get.put(realtime);
  final mapOffline = MapOfflineService();
  Get.put(mapOffline);
  runApp(const NidaaApp());
}