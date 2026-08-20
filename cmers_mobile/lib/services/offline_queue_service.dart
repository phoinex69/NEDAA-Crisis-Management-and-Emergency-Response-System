import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_report_payload.dart';
import 'backend_data_source.dart';

/// وضع العمل أوفلاين (متطلب 4.9):
/// يحفظ البلاغات محلياً عند غياب الاتصال ويرسلها تلقائياً عند عودة الشبكة.
class OfflineQueueService extends GetxController {
  static OfflineQueueService get instance => Get.find<OfflineQueueService>();

  static const _queueKey = 'offline_report_queue';

  final RxBool isOnline = true.obs;
  final RxInt pendingCount = 0.obs;

  final BackendDataSource _backend = BackendProvider.dataSource;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  List<PendingReportPayload> _queue = [];

  /// يُستدعى مرة واحدة عند إقلاع التطبيق.
  Future<void> init() async {
    await _loadQueue();
    Connectivity().onConnectivityChanged.listen(
      (results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        isOnline.value = online;
        if (online) syncPending();
      },
      onError: (_) {
        // لا قناة منصة متاحة (مثلاً في الاختبارات) — يبقى الوضع الافتراضي.
      },
    );
  }

  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) {
      pendingCount.value = 0;
      return;
    }
    try {
      _queue = (jsonDecode(raw) as List)
          .map((e) =>
              PendingReportPayload.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _queue = [];
    }
    pendingCount.value = _queue.length;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_queue.map((p) => p.toJson()).toList());
    await prefs.setString(_queueKey, raw);
    pendingCount.value = _queue.length;
  }

  /// يحفظ بلاغاً محلياً بانتظار المزامنة.
  Future<void> enqueue(PendingReportPayload payload) async {
    _queue.add(payload);
    await _persist();
  }

  /// يرسل كل البلاغات المحفوظة عند توفر الاتصال.
  Future<void> syncPending() async {
    if (_queue.isEmpty) return;
    final failed = <PendingReportPayload>[];
    for (final payload in _queue) {
      try {
        if (payload.isWitness) {
          // شهادة شاهد عيان: النقطة المخصصة تُنشئ سجل WitnessReport.
          await _backend.submitWitnessReport(position: payload.position);
        } else {
          await _backend.submitReport(
            category: payload.category,
            severity: payload.severity,
            description: payload.description,
            victimsCount: payload.victimsCount,
            isWitness: payload.isWitness,
            imageFile:
                payload.imagePath != null ? File(payload.imagePath!) : null,
            audioFile:
                payload.audioPath != null ? File(payload.audioPath!) : null,
            position: payload.position,
          );
        }
      } catch (_) {
        failed.add(payload);
      }
    }
    _queue = failed;
    await _persist();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}