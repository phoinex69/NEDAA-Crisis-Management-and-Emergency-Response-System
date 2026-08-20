import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/accessibility_controller.dart';
import '../../controllers/alerts_controller.dart';
import '../../controllers/nav_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/offline_queue_service.dart';
import '../widgets/nidaa_app_bar.dart';
import '../widgets/report_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportsController>();
    final sosController = Get.find<SosController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NidaaAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OfflineBanner(),
            _AlertsBanner(),
            _SafetyTipCard(),
            const SizedBox(height: 24),
            Center(
              child: _SosButton(controller: sosController),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                AppStrings.tapOrHoldToHelp,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: _WitnessButton()),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.latestReports,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.find<NavController>().changeTab(2),
                  child: Text(
                    AppStrings.viewAll,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.recentReports.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 36, color: AppColors.textLight),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.noReports,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: controller.recentReports
                    .map((r) => ReportCard(
                          report: r,
                          onTap: () => controller.openReportDetails(r),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// شريط يظهر عند غياب الاتصال أو وجود بلاغات بانتظار المزامنة (متطلب 4.9).
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final offline = OfflineQueueService.instance;
      final pending = offline.pendingCount.value;
      if (offline.isOnline.value && pending == 0) {
        return const SizedBox.shrink();
      }
      final message = pending > 0
          ? AppStrings.pendingSync.replaceAll('{count}', '$pending')
          : AppStrings.offlineModeBody;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.severityMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 18, color: AppColors.severityMedium),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.severityMedium,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// شريط التنبيهات الفورية أعلى الشاشة (متطلب 4.5).
class _AlertsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final alerts = Get.find<AlertsController>();
      if (alerts.alerts.isEmpty) return const SizedBox.shrink();
      final alert = alerts.alerts.first;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.statusUrgentBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.statusUrgent),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_rounded,
                size: 18, color: AppColors.statusUrgent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusUrgent,
                    ),
                  ),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.statusUrgent,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SafetyTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBlueBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.infoBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline,
                color: AppColors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.safetyTipTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.infoBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.safetyTipBody,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.infoBlue,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// إبلاغ سريع لشاهد العيان بضغطة واحدة (متطلب 4.8):
/// يُرسل الموقع فوراً دون تفاصيل — مع خيار إرفاق صورة من الموقع قبل الإرسال.
class _WitnessButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reports = Get.find<ReportsController>();
    return Obx(() => reports.isLoading.value
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : TextButton.icon(
            onPressed: () => _showWitnessOptions(context),
            icon: const Icon(Icons.visibility_outlined,
                size: 18, color: AppColors.primary),
            label: Text(
              AppStrings.witnessReport,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ));
  }

  Future<void> _showWitnessOptions(BuildContext context) async {
    final reports = Get.find<ReportsController>();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.send, color: AppColors.primary),
                title: Text(
                  AppStrings.sendNow,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
                subtitle: Text(
                  AppStrings.witnessModeSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, 'send'),
              ),
              ListTile(
                leading: const Icon(Icons.add_a_photo_outlined,
                    color: AppColors.primary),
                title: Text(
                  AppStrings.witnessAddPhoto,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
                subtitle: Text(
                  AppStrings.witnessPhotoHint,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'send') {
      reports.submitWitnessReport();
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.attachImage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppStrings.gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(AppStrings.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    File? file;
    try {
      final lowData = Get.find<AccessibilityController>().lowDataMode.value;
      final picked = await ImagePicker()
          .pickImage(source: source, imageQuality: lowData ? 40 : 80);
      if (picked != null) file = File(picked.path);
    } catch (_) {
      Get.snackbar('حدث خطأ', 'حدث خطأ في فتح الكاميرا/المعرض',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (file == null || !context.mounted) return;
    reports.setAttachedImage(file);
    reports.submitWitnessReport();
  }
}

class _SosButton extends StatelessWidget {
  final SosController controller;

  const _SosButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // ضغطة واحدة = استغاثة فورية مع عد تنازلي قابل للإلغاء (متطلب 4.2).
      onTap: controller.requestSos,
      // ضغط مطول = استكمال بلاغ كامل عبر اختيار نوع الطوارئ.
      onLongPressStart: (_) => controller.startHold(),
      onLongPressEnd: (_) => controller.cancelHold(),
      onLongPressCancel: controller.cancelHold,
      child: Obx(() {
        final holding = controller.isHolding.value;
        final progress = controller.holdProgress.value;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary
                      .withValues(alpha: holding ? 0.28 : 0.16),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary
                      .withValues(alpha: holding ? 0.12 : 0.06),
                ),
              ),
              SizedBox(
                width: 196,
                height: 196,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: holding
                      ? AppColors.white.withValues(alpha: 0.55)
                      : Colors.transparent,
                  color:
                      holding ? AppColors.white : Colors.transparent,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: holding ? AppColors.primaryDark : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: holding ? 0.4 : 0.35),
                      blurRadius: holding ? 45 : 30,
                      spreadRadius: holding ? 14 : 10,
                    ),
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: holding ? 0.22 : 0.18),
                      blurRadius: 60,
                      spreadRadius: holding ? 30 : 22,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: AppColors.white, size: 44),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.helpButton,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}