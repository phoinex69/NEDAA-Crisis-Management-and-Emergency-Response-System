import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:record/record.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../models/pending_report_payload.dart';
import '../models/report_model.dart';
import '../services/backend_data_source.dart';
import '../services/notification_service.dart';
import '../services/offline_queue_service.dart';
import '../services/realtime_service.dart';
import 'accessibility_controller.dart';
import 'map_controller.dart';
import 'sos_controller.dart';

class ReportsController extends GetxController {
  final BackendDataSource _backend = BackendProvider.dataSource;
  final RxList<ReportModel> allReports = <ReportModel>[].obs;
  final RxInt selectedFilterIndex = 0.obs;
  final Rx<ReportCategory?> selectedCategory = Rx<ReportCategory?>(null);
  final Rx<SeverityLevel> selectedSeverity = SeverityLevel.medium.obs;
  final Rx<ReportModel?> selectedReport = Rx<ReportModel?>(null);
  final Rx<LatLng?> pendingLocation = Rx<LatLng?>(null);
  final descriptionController = TextEditingController();

  /// عدد المصابين / المتضررين تقريباً (متطلب 4.2).
  final Rx<int?> victimsCount = Rx<int?>(null);
  final RxBool isWitness = false.obs;

  final Rx<File?> attachedImage = Rx<File?>(null);
  final Rx<File?> attachedAudio = Rx<File?>(null);
  final RxBool isRecordingAudio = false.obs;
  final RxBool isTranscribing = false.obs;
  final RxBool isLoading = false.obs;

  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<List<ReportModel>>? _realtimeSub;
  StreamSubscription<bool>? _lowDataSub;
  StreamSubscription<ReportRealtimeUpdate>? _liveTrackingSub;

  /// التتبع اللحظي لبلاغ معيّن عبر WebSocket (متطلب 4.4).
  /// يُفتح من شاشة التتبع ويُغلق عند مغادرتها — الاستطلاع يبقى fallback.
  void startReportLiveTracking(String reportId) {
    RealtimeService.instance.trackReport(reportId);
    _liveTrackingSub ??= RealtimeService.instance.reportUpdates.listen(
      (update) {
        if (update.reportId != reportId) return;
        applyRealtimeReport(update.payload);
      },
    );
  }

  void stopReportLiveTracking() {
    _liveTrackingSub?.cancel();
    _liveTrackingSub = null;
    RealtimeService.instance.trackReport(null);
  }

  /// يطبّق حمولة WebSocket من الخادم (ws/citizen/<id>/):
  /// {"report_id","status","status_display","updated_at","eta_minutes","assigned_unit"}
  /// — يدمج الحقول المرسلة فقط على البلاغ الموجود ويُشعر عند تغيّر الحالة.
  void applyRealtimeReport(Map<String, dynamic> payload) {
    final id = payload['report_id']?.toString() ?? payload['id']?.toString();
    if (id == null || id.isEmpty) return;
    final index = allReports.indexWhere((r) => r.id == id);
    final ReportModel updated;
    if (index == -1) {
      updated = ReportModel.fromJson(payload);
      allReports.insert(0, updated);
    } else {
      final previous = allReports[index];
      // حالة الخادم (snake_case) → حالة العرض، مع تقدم مشتق منها.
      final rawStatus = payload['status']?.toString();
      final mappedStatus = rawStatus != null
          ? reportStatusFromApi(rawStatus)
          : previous.status;
      updated = previous.copyWith(
        status: mappedStatus,
        progressValue: rawStatus != null
            ? reportProgressForStatus(mappedStatus)
            : previous.progressValue,
        respondingAgency: payload['assigned_unit']?.toString() ??
            previous.respondingAgency,
        etaMinutes: (payload['eta_minutes'] as num?)?.toInt() ??
            previous.etaMinutes,
      );
      allReports[index] = updated;
      _notifyStatusChange(previous, updated);
    }
    if (selectedReport.value?.id == updated.id) {
      selectedReport.value = updated;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final fetched = await _backend.fetchReports(const []);
      allReports.assignAll(fetched);
    } catch (_) {
      // تُترك القائمة فارغة عند تعذر الجلب — لا بيانات تجريبية.
    }
  }

  List<ReportModel> get filteredReports {
    switch (selectedFilterIndex.value) {
      case 1:
        return allReports
            .where((r) => r.status != ReportStatus.closed)
            .toList();
      case 2:
        return allReports
            .where((r) => r.status == ReportStatus.closed)
            .toList();
      default:
        return allReports.toList();
    }
  }

  List<ReportModel> get recentReports => allReports.take(2).toList();

  Future<void> refreshReports() async {
    try {
      final updated = await _backend.fetchReports(allReports.toList());
      _mergeFromBackend(updated);
      Get.snackbar('تم التحديث', 'تم تحديث قائمة البلاغات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: const Color(0xFFFFFFFF));
    } catch (e) {
      Get.snackbar('تعذر التحديث', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
    }
  }

  /// بثّ التحديثات اللحظية:
  /// مع Backend حقيقي = استطلاع GET /reports كل 6 ثوانٍ.
  /// بدون Backend = محاكاة محلية عبر [BackendDataSource].
  /// وضع توفير البيانات يخفّف الاستطلاع إلى 30 ثانية (4.9).
  void startRealtimeUpdates() {
    if (_realtimeSub != null) return;
    _startRealtimeTimer();
    _lowDataSub ??= Get.find<AccessibilityController>()
        .lowDataMode
        .listen((_) => _restartRealtimeTimer());
  }

  void _startRealtimeTimer() {
    final lowData = Get.find<AccessibilityController>().lowDataMode.value;
    _realtimeSub = Stream.periodic(
      Duration(seconds: lowData ? 30 : 6),
      (_) => _backend.fetchReports(allReports.toList()),
    ).asyncMap((future) => future).listen((updated) => _mergeFromBackend(updated));
  }

  void _restartRealtimeTimer() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    _startRealtimeTimer();
  }

  void stopRealtimeUpdates() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    _lowDataSub?.cancel();
    _lowDataSub = null;
  }

  void _mergeFromBackend(List<ReportModel> fetched) {
    final fetchedIds = fetched.map((r) => r.id).toSet();
    allReports.removeWhere((r) => !fetchedIds.contains(r.id));
    for (final report in fetched) {
      final index = allReports.indexWhere((r) => r.id == report.id);
      if (index == -1) {
        allReports.insert(0, report);
        continue;
      }
      final previous = allReports[index];
      allReports[index] = report;
      _notifyStatusChange(previous, report);
    }
  }

  /// إشعار فوري عند تغيّر حالة البلاغ (متطلب 4.4).
  void _notifyStatusChange(ReportModel previous, ReportModel report) {
    if (previous.status == report.status) {
      return;
    }
    final message = report.status == ReportStatus.closed
        ? AppStrings.reportClosed.replaceAll('{title}', report.title)
        : '${report.title} — ${report.statusLabel}';
    NotificationService.showNotification(
      title: AppStrings.liveUpdate,
      body: message,
    );
    Get.snackbar(
      AppStrings.liveUpdate,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: report.status == ReportStatus.closed
          ? const Color(0xFF6B7280)
          : const Color(0xFF059669),
      colorText: const Color(0xFFFFFFFF),
    );
  }

  void openReportDetails(ReportModel report) {
    selectedReport.value = report;
    Get.toNamed(AppRoutes.reportTracking);
  }

  void setFilter(int index) => selectedFilterIndex.value = index;

  void selectCategory(ReportCategory category) {
    selectedCategory.value = category;
    _resolveLocation().then((coords) {
      pendingLocation.value = coords;
    });
    Get.toNamed(AppRoutes.reportDetails);
  }

  /// تجهيز حمولة البلاغ في الخلفية: إحداثيات GPS الحالية (من الاستغاثة،
  /// أو تتبع الخريطة، أو جلب فوري) مع نوع الطوارئ المختار — جاهزة للـ API.
  Future<LatLng?> _resolveLocation() async {
    final sos = Get.find<SosController>();
    if (sos.userLocation.value != null) return sos.userLocation.value;

    final map = Get.find<MapController>();
    if (map.userLocation.value != null) return map.userLocation.value;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  void setSeverity(SeverityLevel level) => selectedSeverity.value = level;

  void setVictimsCount(int? count) => victimsCount.value = count;

  void setAttachedImage(File? file) => attachedImage.value = file;

  void setAttachedAudio(File? file) => attachedAudio.value = file;

  /// بدء التسجيل الصوتي للبلاغ (متطلب 4.3).
  Future<void> startAudioRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        Get.snackbar('صلاحية المايك مطلوبة',
            'اسمح بالوصول إلى المايك لتسجيل بلاغ صوتي',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFCC1C2E),
            colorText: const Color(0xFFFFFFFF));
        return;
      }
      final path =
          '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // وضع توفير البيانات: جودة صوت أخف (4.9).
      final lowData = Get.find<AccessibilityController>().lowDataMode.value;
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: lowData ? 48000 : 128000,
          sampleRate: lowData ? 22050 : 44100,
        ),
        path: path,
      );
      isRecordingAudio.value = true;
    } catch (_) {
      Get.snackbar('تعذر التسجيل', 'تعذر بدء التسجيل الصوتي',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
    }
  }

  /// إيقاف التسجيل ثم تحويل الصوت إلى نص (Whisper) وعرضه للمراجعة.
  Future<void> stopAudioRecording() async {
    if (!isRecordingAudio.value) return;
    isRecordingAudio.value = false;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      return;
    }
    if (path == null || !File(path).existsSync()) return;
    setAttachedAudio(File(path));
    isTranscribing.value = true;
    try {
      final text = await _backend.transcribeAudio(File(path));
      if (text.trim().isNotEmpty) {
        descriptionController.text = text;
      }
    } catch (_) {
      Get.snackbar(AppStrings.voiceReport, AppStrings.transcriptionFailed,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isTranscribing.value = false;
    }
  }

  /// إرسال بلاغ الشاهد بضغطة واحدة (متطلب 4.8): الموقع + صورة اختيارية.
  /// يُرسل إلى النقطة المخصصة /reports/witness/ فيُنشأ سجل WitnessReport
  /// فعلي في الخادم (بعكس المسار السابق الذي أرسله كبلاغ عادي).
  Future<void> submitWitnessReport() async {
    isWitness.value = true;
    selectedCategory.value = ReportCategory.other;
    await _resolveLocation().then((coords) {
      pendingLocation.value = coords;
    });
    isLoading.value = true;
    try {
      final newReport = await _backend.submitWitnessReport(
        position: pendingLocation.value,
      );
      allReports.insert(0, newReport);
      _showSuccessAndGoHome();
    } catch (e) {
      // فشل الإرسال (مثلاً بلا اتصال): حفظ محلي + مزامنة تلقائية (متطلب 4.9).
      final offline = OfflineQueueService.instance;
      await offline.enqueue(
        PendingReportPayload.fromReport(
          category: ReportCategory.other,
          severity: selectedSeverity.value,
          description: descriptionController.text,
          victimsCount: victimsCount.value,
          isWitness: true,
          imagePath: attachedImage.value?.path,
          audioPath: attachedAudio.value?.path,
          position: pendingLocation.value,
        ),
      );
      Get.snackbar(
        AppStrings.offlineMode,
        offline.isOnline.value
            ? 'تعذر الإرسال — تم حفظ البلاغ وإعادة المحاولة'
            : AppStrings.offlineModeBody,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
      );
      Get.until((route) => route.settings.name == AppRoutes.home);
    } finally {
      isLoading.value = false;
      isWitness.value = false;
      selectedCategory.value = null;
      pendingLocation.value = null;
      descriptionController.clear();
      attachedImage.value = null;
      attachedAudio.value = null;
      victimsCount.value = null;
      selectedSeverity.value = SeverityLevel.medium;
    }
  }

  Future<void> submitReport() async {
    if (selectedCategory.value == null) return;

    isLoading.value = true;
    try {
      // إرسال حقيقي: رفع الصورة/الصوت (multipart) + إنشاء البلاغ على الخادم.
      // الحقول اختيارية — يُرسل البلاغ حتى لو لم تُعبأ.
      final newReport = await _backend.submitReport(
        category: selectedCategory.value!,
        severity: selectedSeverity.value,
        description: descriptionController.text,
        victimsCount: victimsCount.value,
        isWitness: isWitness.value,
        imageFile: attachedImage.value,
        audioFile: attachedAudio.value,
        position: pendingLocation.value,
      );
      allReports.insert(0, newReport);
      _showSuccessAndGoHome();
    } catch (e) {
      // فشل الإرسال (مثلاً بلا اتصال): حفظ محلي + مزامنة تلقائية (متطلب 4.9).
      final offline = OfflineQueueService.instance;
      await offline.enqueue(
        PendingReportPayload.fromReport(
          category: selectedCategory.value!,
          severity: selectedSeverity.value,
          description: descriptionController.text,
          victimsCount: victimsCount.value,
          isWitness: isWitness.value,
          imagePath: attachedImage.value?.path,
          audioPath: attachedAudio.value?.path,
          position: pendingLocation.value,
        ),
      );
      Get.snackbar(
        AppStrings.offlineMode,
        offline.isOnline.value
            ? 'تعذر الإرسال — تم حفظ البلاغ وإعادة المحاولة'
            : AppStrings.offlineModeBody,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
      );
      Get.until((route) => route.settings.name == AppRoutes.home);
    } finally {
      isLoading.value = false;
      selectedCategory.value = null;
      pendingLocation.value = null;
      descriptionController.clear();
      attachedImage.value = null;
      attachedAudio.value = null;
      victimsCount.value = null;
      selectedSeverity.value = SeverityLevel.medium;
    }
  }

  /// نافذة النجاح ثم العودة للشاشة الرئيسية بعد إرسال البلاغ.
  void _showSuccessAndGoHome() {
    Get.dialog(
      const _SuccessCheckmark(),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.until((route) => route.settings.name == AppRoutes.home);
    });
  }

  @override
  void onClose() {
    stopRealtimeUpdates();
    stopReportLiveTracking();
    _recorder.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}

/// نافذة النجاح: علامة صح خضراء تظهر لحظياً بعد رفع البلاغ.
class _SuccessCheckmark extends StatelessWidget {
  const _SuccessCheckmark();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66059669),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 56),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم إرسال بلاغك بنجاح',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}