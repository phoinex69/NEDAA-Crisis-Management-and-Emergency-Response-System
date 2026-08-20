import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config/app_config.dart';
import 'offline_queue_service.dart';
import 'session_service.dart';

/// حمولة تحديث بلاغ لحظي من قناة ws/citizen/<report_id>/ (متطلب 4.4).
class ReportRealtimeUpdate {
  final String reportId;
  final Map<String, dynamic> payload;

  const ReportRealtimeUpdate({required this.reportId, required this.payload});
}

/// التحديث اللحظي عبر WebSocket (متطلب 4.4):
/// - ws/citizen/<report_id>/ — تحديثات بلاغ واحد أثناء تتبعه.
///
/// ملاحظة: لا توجد قناة "تنبيهات المواطن" في خادم NEDAA — التنبيهات
/// تُجلب بالاستطلاع من /notifications/ عبر [AlertsController].
///
/// إعادة اتصال تلقائية بـ backoff، ping كل 25 ثانية، ويتوقف/يعمل
/// تلقائياً حسب حالة الاتصال من [OfflineQueueService.isOnline].
class RealtimeService extends GetxService {
  static RealtimeService get instance => Get.find<RealtimeService>();

  final StreamController<ReportRealtimeUpdate> _reportUpdates =
      StreamController<ReportRealtimeUpdate>.broadcast();

  /// تحديثات البلاغ المُتتبَّع حالياً.
  Stream<ReportRealtimeUpdate> get reportUpdates => _reportUpdates.stream;

  final _WsChannel _reportChannel = _WsChannel();
  StreamSubscription<bool>? _onlineSub;

  /// يُستدعى مرة واحدة عند إقلاع التطبيق.
  Future<void> init() async {
    _onlineSub ??= OfflineQueueService.instance.isOnline.listen((online) {
      if (online) {
        if (_reportChannel.path != null) {
          _reportChannel.connect(
            path: _reportChannel.path!,
            onMessage: _handleReportMessage,
          );
        }
      } else {
        _reportChannel.disconnect();
      }
    });
  }

  /// يبدأ/يوقف تتبع بلاغ معيّن عبر ws/citizen/<report_id>/.
  /// مرّر null لإيقاف التتبع.
  void trackReport(String? reportId) {
    if (reportId == null || reportId.isEmpty) {
      _reportChannel.disconnect();
      return;
    }
    _reportChannel.connect(
      path: 'ws/citizen/$reportId/',
      onMessage: _handleReportMessage,
    );
  }

  void _handleReportMessage(dynamic raw) {
    final payload = _extractPayload(raw);
    if (payload == null) return;
    final id = payload['id']?.toString() ?? payload['report_id']?.toString();
    if (id == null || id.isEmpty) return;
    _reportUpdates.add(ReportRealtimeUpdate(reportId: id, payload: payload));
  }

  /// يفكك الأغلفة الشائعة: {"type": ..., "data": {...}} أو {"report": {...}}.
  Map<String, dynamic>? _extractPayload(dynamic raw) {
    if (raw is! String) return null;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    for (final key in const ['data', 'report', 'alert', 'zone', 'incident']) {
      final nested = json[key];
      if (nested is Map<String, dynamic>) return nested;
    }
    return json;
  }

  @override
  void onClose() {
    _onlineSub?.cancel();
    _reportChannel.dispose();
    _reportUpdates.close();
    super.onClose();
  }
}

/// قناة WebSocket واحدة مع إعادة اتصال بـ backoff و ping دوري.
class _WsChannel {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _wantConnected = false;
  void Function(dynamic)? _onMessage;

  /// المسار المطلوب (مثال: ws/citizen_alerts/) — يُستخدم لإعادة الاتصال.
  String? path;

  static const _maxBackoff = Duration(seconds: 30);
  static const _pingInterval = Duration(seconds: 25);

  String? _authToken() {
    try {
      return SessionService.instance.token;
    } catch (_) {
      return null;
    }
  }

  void connect({
    required String path,
    required void Function(dynamic) onMessage,
  }) {
    this.path = path;
    _onMessage = onMessage;
    _wantConnected = true;
    _open();
  }

  void _open() {
    if (!_wantConnected || _channel != null) return;
    if (!OfflineQueueService.instance.isOnline.value) return;

    final base = Uri.parse(AppConfig.baseUrl);
    // يُبنى المسار كاملاً مع الشرطة المائلة النهائية: خادم NEDAA يطابق
    // أنماط WebSocket حصراً بصيغة "ws/citizen/<id>/" (re_path بـ $).
    final fullPath = path!.startsWith('/') ? path : '/$path';
    final uri = Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      port: base.port,
      path: fullPath,
    );
    final token = _authToken();
    final fullUri = (token == null || token.isEmpty)
        ? uri
        : uri.replace(queryParameters: {'token': token});

    try {
      _channel = WebSocketChannel.connect(fullUri);
      _channel!.stream.listen(
        (message) => _onMessage?.call(message),
        onDone: _onClosed,
        onError: (_) => _onClosed(),
      );
      _attempt = 0;
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(_pingInterval, (_) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      });
    } catch (_) {
      _onClosed();
    }
  }

  void _onClosed() {
    _channel = null;
    _pingTimer?.cancel();
    if (!_wantConnected) return;
    final shift = _attempt > 5 ? 5 : _attempt;
    var delay = Duration(seconds: 1 << shift);
    if (delay > _maxBackoff) delay = _maxBackoff;
    _attempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _open);
  }

  void disconnect() {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
  }
}