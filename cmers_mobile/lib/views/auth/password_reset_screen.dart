import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';

/// استعادة كلمة المرور (متطلب 4.1): رقم الهاتف → رمز OTP → كلمة مرور جديدة.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    return validateSyrianPhone(v);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                AppStrings.passwordResetTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.passwordResetSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Obx(() => controller.resetRequested.value
                  ? _buildConfirmStep(controller)
                  : _buildRequestStep(controller)),
            ],
          ),
        ),
      ),
    );
  }

  /// الخطوة 1: طلب الرمز برقم الهاتف.
  Widget _buildRequestStep(AuthController controller) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.phoneNumber,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.resetPhoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.rtl,
            validator: _validatePhone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.requestPasswordReset(),
            decoration: const InputDecoration(
              hintText: '09xxxxxxxx',
              hintStyle: TextStyle(
                  color: AppColors.textLight, fontSize: 13),
              suffixIcon: Icon(Icons.phone_outlined,
                  color: AppColors.textLight),
              errorStyle: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton.icon(
                  onPressed:
                      controller.isResetting.value ? null : () => controller.requestPasswordReset(),
                  icon: const Icon(Icons.sms_outlined, color: AppColors.white),
                  label: controller.isResetting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.continueBtn),
                )),
          ),
        ],
      ),
    );
  }

  /// الخطوة 2: الرمز + كلمة المرور الجديدة + تأكيدها.
  Widget _buildConfirmStep(AuthController controller) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.otpTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.resetOtpController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.rtl,
            maxLength: 6,
            validator: (v) => (v ?? '').length < 6
                ? 'الرجاء إدخال الرمز كاملاً'
                : null,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(
                  color: AppColors.textLight, fontSize: 13),
              suffixIcon: Icon(Icons.pin_outlined,
                  color: AppColors.textLight),
              errorStyle: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
              counterText: '',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: controller.canResend.value
                    ? controller.resendResetCode
                    : null,
                child: Text(
                  AppStrings.resend,
                  style: TextStyle(
                    fontSize: 13,
                    color: controller.canResend.value
                        ? AppColors.primary
                        : AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Obx(() => Text(
                    controller.formattedCountdown,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.newPassword,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.resetPasswordController,
            obscureText: _obscureNew,
            textDirection: TextDirection.rtl,
            validator: (v) => (v ?? '').length < 8
                ? 'كلمة المرور يجب ألا تقل عن 8 أحرف'
                : null,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(
                  color: AppColors.textLight, fontSize: 13),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.confirmPassword,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.resetConfirmController,
            obscureText: _obscureConfirm,
            textDirection: TextDirection.rtl,
            validator: (v) => v != controller.resetPasswordController.text
                ? 'كلمتا المرور غير متطابقتين'
                : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.confirmPasswordReset(),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(
                  color: AppColors.textLight, fontSize: 13),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isResetting.value
                      ? null
                      : controller.confirmPasswordReset,
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.white),
                  label: controller.isResetting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.resetBtn),
                )),
          ),
        ],
      ),
    );
  }
}