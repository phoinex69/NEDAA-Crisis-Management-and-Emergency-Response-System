import 'dart:async';

import 'package:get/get.dart';

import '../models/alert_model.dart';
import '../services/backend_data_source.dart';
import '../services/notification_service.dart';
import 'accessibility_controller.dart';

/// التنبيهات الفورية للمواطنين (متطلب 4.5):
/// تحذيرات الطقس والكوارث الطبيعية، إغلاق الطرق، تعليمات السلامة والإخلاء.
class AlertsController extends GetxController {
  final BackendDataSource _backend = BackendProvider.dataSource;

  final RxList<AlertModel> alerts = <AlertModel>[].obs;
  final RxBool isLoading = false.obs;

  Timer? _pollTimer;
  StreamSubscription<bool>? _lowDataSub;
  final Set<String> _notifiedIds = {};

  @override
  void onInit() {
    super.onInit();
    loadAlerts();
    // ملاحظة: لا توجد قناة WebSocket للتنبيهات في خادم NEDAA —
    // التنبيهات تأتي بالاستطلاع الدوري من /notifications/.
  }

  Future<void> loadAlerts() async {
    isLoading.value = true;
    try {
      final fetched = await _backend.fetchAlerts();
      _merge(fetched);
    } catch (_) {
      // تُترك القائمة الحالية عند تعذر الجلب.
    } finally {
      isLoading.value = false;
    }
  }

  /// استطلاع دوري أثناء الأزمات.
  /// وضع توفير البيانات يخفّفه من 60 ثانية إلى 5 دقائق (4.9).
  void startPolling() {
    if (_pollTimer != null) return;
    _startTimer();
    _lowDataSub ??= Get.find<AccessibilityController>()
        .lowDataMode
        .listen((_) => _restartTimer());
  }

  void _startTimer() {
    final lowData = Get.find<AccessibilityController>().lowDataMode.value;
    _pollTimer = Timer.periodic(
      Duration(seconds: lowData ? 300 : 60),
      (_) => loadAlerts(),
    );
  }

  void _restartTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _startTimer();
  }

  void _merge(List<AlertModel> fetched) {
    final known = alerts.map((a) => a.id).toSet();
    for (final alert in fetched) {
      if (known.contains(alert.id)) continue;
      alerts.insert(0, alert);
      if (_notifiedIds.add(alert.id)) {
        NotificationService.showNotification(
          title: alert.title,
          body: alert.message,
        );
      }
    }
    if (alerts.length > 20) {
      alerts.removeRange(20, alerts.length);
    }
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _lowDataSub?.cancel();
    super.onClose();
  }
}