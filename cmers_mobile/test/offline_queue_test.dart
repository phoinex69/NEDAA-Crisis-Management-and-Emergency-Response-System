import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nidaa_app/models/pending_report_payload.dart';
import 'package:nidaa_app/models/report_model.dart';
import 'package:nidaa_app/services/backend_data_source.dart';
import 'package:nidaa_app/services/offline_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend وهمي يتتبع استدعاءات الإرسال فقط (متطلب 4.9).
class FakeBackend implements BackendDataSource {
  int submitCalls = 0;
  int witnessCalls = 0;
  bool failSubmit = false;

  @override
  Future<ReportModel> submitReport({
    required ReportCategory category,
    required SeverityLevel severity,
    required String description,
    int? victimsCount,
    bool isWitness = false,
    File? imageFile,
    File? audioFile,
    LatLng? position,
  }) async {
    submitCalls++;
    if (failSubmit) throw Exception('لا يوجد اتصال');
    return ReportModel(
      id: '1',
      title: description,
      location: '',
      status: ReportStatus.processing,
      category: category,
      severity: severity,
      timeAgo: 'الآن',
    );
  }

  @override
  Future<ReportModel> submitWitnessReport({LatLng? position}) async {
    submitCalls++;
    witnessCalls++;
    if (failSubmit) throw Exception('لا يوجد اتصال');
    return ReportModel(
      id: 'witness-1',
      title: 'بلاغ شاهد',
      location: '',
      status: ReportStatus.processing,
      category: ReportCategory.other,
      severity: SeverityLevel.medium,
      timeAgo: 'الآن',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BackendProvider.overrideForTesting(FakeBackend());
  });

  tearDown(() {
    BackendProvider.reset();
  });

  PendingReportPayload payload({
    String description = 'بلاغ اختبار',
  }) {
    return PendingReportPayload(
      category: ReportCategory.ambulance,
      severity: SeverityLevel.critical,
      description: description,
      victimsCount: 3,
      isWitness: true,
      latitude: 33.51,
      longitude: 36.29,
    );
  }

  test('enqueue يحفظ البلاغ ويحدّث العداد', () async {
    final queue = OfflineQueueService();

    await queue.enqueue(payload());
    await queue.enqueue(payload(description: 'بلاغ ثانٍ'));

    expect(queue.pendingCount.value, 2);
  });

  test('syncPending يرسل البلاغات المحفوظة ويمسحها عند نجاحها', () async {
    final queue = OfflineQueueService();
    final backend = BackendProvider.dataSource as FakeBackend;
    await queue.enqueue(payload());
    await queue.enqueue(payload(description: 'بلاغ ثانٍ'));

    await queue.syncPending();

    expect(backend.submitCalls, 2);
    expect(backend.witnessCalls, 2);
    expect(queue.pendingCount.value, 0);
  });

  test('syncPending يُبقي البلاغات عند فشل الإرسال (أوفلاين)', () async {
    final queue = OfflineQueueService();
    final backend = BackendProvider.dataSource as FakeBackend;
    backend.failSubmit = true;
    await queue.enqueue(payload());

    await queue.syncPending();

    expect(backend.submitCalls, 1);
    expect(queue.pendingCount.value, 1);
  });

  test('الطابور يستعيد البلاغات المحفوظة بعد إعادة التشغيل', () async {
    final queue = OfflineQueueService();
    await queue.enqueue(payload());

    final restored = OfflineQueueService();
    await restored.init();
    final backend = BackendProvider.dataSource as FakeBackend;
    backend.failSubmit = true;
    await restored.syncPending();

    // بلاغ واحد استُعيد من التخزين وحاول المزامنة (وفشل — يبقى محفوظاً).
    expect(backend.submitCalls, 1);
    expect(restored.pendingCount.value, 1);
  });
}