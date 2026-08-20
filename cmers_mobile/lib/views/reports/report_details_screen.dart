import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/accessibility_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/report_model.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.appName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VictimsCountField(controller: controller),
            const SizedBox(height: 16),
            _SeveritySelector(controller: controller),
            const SizedBox(height: 20),
            _DescriptionField(controller: controller),
            const SizedBox(height: 20),
            _VoiceSection(controller: controller),
            const SizedBox(height: 20),
            _AttachmentSection(controller: controller),
            const SizedBox(height: 32),
            Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitReport,
                  icon: const Icon(Icons.send, color: AppColors.white),
                  label: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.submitReport),
                )),
          ],
        ),
      ),
    );
  }
}

class _VictimsCountField extends StatelessWidget {
  final ReportsController controller;
  const _VictimsCountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.victimsCount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final value = controller.victimsCount.value;
            return Row(
              children: [
                _stepper(
                  icon: Icons.remove,
                  onTap: value == null || value <= 0
                      ? null
                      : () => controller.setVictimsCount(value - 1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value == null || value == 0
                        ? AppStrings.victimsUnknown
                        : AppStrings.peopleCount.replaceAll('{n}', '$value'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _stepper(
                  icon: Icons.add,
                  onTap: () =>
                      controller.setVictimsCount((value ?? 0) + 1),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _stepper({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.statusClosedBg
              : const Color(0xFFE8F0FE),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: onTap == null ? AppColors.textLight : AppColors.primary),
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  final ReportsController controller;
  const _SeveritySelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.severityLevel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
                children: [
                  _SeverityOption(
                    label: AppStrings.severityCritical,
                    icon: Icons.report_problem_outlined,
                    color: AppColors.severityCritical,
                    bgColor: const Color(0xFFFDE8E8),
                    level: SeverityLevel.critical,
                    selected: controller.selectedSeverity.value ==
                        SeverityLevel.critical,
                    onTap: () =>
                        controller.setSeverity(SeverityLevel.critical),
                  ),
                  const SizedBox(width: 8),
                  _SeverityOption(
                    label: AppStrings.severityHigh,
                    icon: Icons.error_outline,
                    color: AppColors.severityHigh,
                    bgColor: AppColors.statusUrgentBg,
                    level: SeverityLevel.high,
                    selected: controller.selectedSeverity.value ==
                        SeverityLevel.high,
                    onTap: () =>
                        controller.setSeverity(SeverityLevel.high),
                  ),
                  const SizedBox(width: 8),
                  _SeverityOption(
                    label: AppStrings.severityMedium,
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.severityMedium,
                    bgColor: const Color(0xFFFFF8E6),
                    level: SeverityLevel.medium,
                    selected: controller.selectedSeverity.value ==
                        SeverityLevel.medium,
                    onTap: () =>
                        controller.setSeverity(SeverityLevel.medium),
                  ),
                  const SizedBox(width: 8),
                  _SeverityOption(
                    label: AppStrings.severityLow,
                    icon: Icons.check_circle_outline,
                    color: AppColors.severityLow,
                    bgColor: const Color(0xFFECFDF5),
                    level: SeverityLevel.low,
                    selected: controller.selectedSeverity.value ==
                        SeverityLevel.low,
                    onTap: () =>
                        controller.setSeverity(SeverityLevel.low),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class _SeverityOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final SeverityLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _SeverityOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? bgColor : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final ReportsController controller;
  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.reportDetails,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: controller.descriptionController,
            maxLines: 5,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: AppStrings.descriptionHint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }
}

/// تسجيل بلاغ صوتي وتحويله إلى نص للمراجعة قبل الإرسال (متطلب 4.3).
class _VoiceSection extends StatelessWidget {
  final ReportsController controller;
  const _VoiceSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.voiceReport,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.isTranscribing.value) {
              return Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(AppStrings.transcribing,
                      style:
                          const TextStyle(color: AppColors.textMedium)),
                ],
              );
            }
            final audio = controller.attachedAudio.value;
            return Row(
              children: [
                GestureDetector(
                  onTap: controller.isRecordingAudio.value
                      ? controller.stopAudioRecording
                      : controller.startAudioRecording,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.isRecordingAudio.value
                          ? AppColors.primary
                          : const Color(0xFFFDE8E8),
                    ),
                    child: controller.isRecordingAudio.value
                        ? const Icon(Icons.stop_rounded,
                            color: AppColors.white, size: 22)
                        : const Icon(Icons.mic,
                            color: AppColors.severityCritical, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    audio != null && !controller.isRecordingAudio.value
                        ? AppStrings.audioAttached
                        : AppStrings.voiceHint,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  final ReportsController controller;
  const _AttachmentSection({required this.controller});

  Future<void> _pickImage(BuildContext context) async {
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
              Text(
                AppStrings.attachImage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: AppStrings.gallery,
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: AppStrings.camera,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picker = ImagePicker();
    try {
      // وضع توفير البيانات: ضغط أعلى للصورة (4.9).
      final lowData = Get.find<AccessibilityController>().lowDataMode.value;
      final picked =
          await picker.pickImage(source: source, imageQuality: lowData ? 40 : 80);
      if (picked != null) {
        controller.setAttachedImage(File(picked.path));
      }
    } catch (_) {
      Get.snackbar('حدث خطأ', 'حدث خطأ في فتح الكاميرا/المعرض',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.attachments,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final image = controller.attachedImage.value;
          if (image == null) {
            return GestureDetector(
              onTap: () => _pickImage(context),
              child: CustomPaint(
                painter: _DottedBorderPainter(AppColors.textLight),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: Column(
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 32, color: AppColors.textMedium),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.attachImage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => controller.setAttachedImage(null),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: AppColors.white, size: 18),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textDark, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;

  _DottedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = min(distance + dash, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}