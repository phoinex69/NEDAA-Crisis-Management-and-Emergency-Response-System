import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sos_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// شاشة العد التنازلي للاستغاثة بضغطة واحدة (متطلب 4.2):
/// ضغطة زر → عد تنازلي قابل للإلغاء → POST /sos → التصنيف.
/// تُستدعى من [SosController.startSosFlow] عبر [AppRoutes.sosCountdown].
class SosCountdownScreen extends StatelessWidget {
  const SosCountdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SosController>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Obx(() {
          if (controller.isSending.value) {
            return const _SendingView();
          }
          return _CountdownView(controller: controller);
        }),
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  final SosController controller;

  const _CountdownView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.white, size: 44),
        const SizedBox(height: 12),
        Text(
          AppStrings.sosTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            AppStrings.sosSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.white,
            ),
          ),
        ),
        const Spacer(),
        Obx(() {
          final total = SosController.countdownSeconds.toDouble();
          final remaining = controller.countdown.value.toDouble();
          return SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: remaining / total,
                    strokeWidth: 8,
                    backgroundColor: AppColors.white.withValues(alpha: 0.25),
                    color: AppColors.white,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${controller.countdown.value}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        Obx(() {
          final location = controller.userLocation.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              location == null
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle,
                      size: 18, color: AppColors.white),
              const SizedBox(width: 8),
              Text(
                location == null
                    ? AppStrings.gettingLocation
                    : AppStrings.locationReady,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          );
        }),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: OutlinedButton(
            onPressed: controller.cancelSos,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.white, width: 1.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              AppStrings.cancel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _SendingView extends StatelessWidget {
  const _SendingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.sendingSos,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.my_location,
              color: AppColors.white, size: 22),
        ],
      ),
    );
  }
}