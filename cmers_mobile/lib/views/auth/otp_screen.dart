import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  Worker? _otpErrorWorker;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    final controller = Get.find<AuthController>();
    _otpErrorWorker = ever(controller.otpError, (_) {
      if (controller.otpError.isNotEmpty && mounted) {
        _pinController.clear();
        controller.setOtp('');
        _shakeController.forward(from: 0);
        Get.snackbar(
          'رمز غير صحيح',
          controller.otpError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  @override
  void dispose() {
    _otpErrorWorker?.dispose();
    _shakeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    final defaultTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.white,
      ),
    );

    final focusedTheme = defaultTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary, width: 2),
      borderRadius: BorderRadius.circular(10),
      color: AppColors.white,
    );

    final errorTheme = defaultTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary, width: 1.5),
      borderRadius: BorderRadius.circular(10),
      color: AppColors.statusUrgentBg,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/logo_margin.png',
                width: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                controller.twoFactorMode
                    ? AppStrings.twoFactorTitle
                    : AppStrings.otpTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.twoFactorMode
                    ? AppStrings.twoFactorSubtitle
                    : AppStrings.otpSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Obx(() {
                final hasError = controller.otpError.isNotEmpty;
                return AnimatedBuilder(
                  animation: _shakeController,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeOffset.value, 0),
                    child: child,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Pinput(
                      controller: _pinController,
                      length: 6,
                      enabled: !controller.isLoading.value,
                      defaultPinTheme: defaultTheme,
                      focusedPinTheme: focusedTheme,
                      errorPinTheme: errorTheme,
                      forceErrorState: hasError,
                      errorText: hasError ? controller.otpError.value : null,
                      errorTextStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: controller.setOtp,
                      onCompleted: (code) {
                        controller.setOtp(code);
                        controller.verifyOtp();
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 48),
              Obx(() {
                return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: controller.canResend.value
                                ? controller.resendOtp
                                : null,
                            child: Text(
                              AppStrings.resend,
                              style: TextStyle(
                                fontSize: 13,
                                color: controller.canResend.value
                                    ? AppColors.primary
                                    : AppColors.textSilver,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.noCode,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!controller.canResend.value)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textMedium),
                            const SizedBox(width: 4),
                            Text(
                              controller.formattedCountdown,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
              }),
              const SizedBox(height: 24),
              Obx(() => ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.verifyOtp,
                    icon: const Icon(Icons.check_circle_outline,
                        color: AppColors.white),
                    label: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2),
                          )
                        : Text(AppStrings.verifyBtn),
                  )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
