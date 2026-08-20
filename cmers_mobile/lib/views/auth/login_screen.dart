import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';

/// شاشة الدخول (متطلب 4.1): تسجيل الدخول بالبريد/الجوال وكلمة المرور
/// أو إنشاء حساب جديد — مع استعادة كلمة المرور.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  bool _obscureLogin = true;
  bool _obscureRegister = true;
  bool _obscureRegisterConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني أو رقم الهاتف';
    final isPhone = RegExp(r'^(09\d{8}|\+9639\d{8})$').hasMatch(v);
    if (!isPhone && !v.contains('@')) {
      return 'أدخل رقماً سورياً صحيحاً أو بريداً إلكترونياً صالحاً';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    return validateSyrianPhone(v);
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) return;
    Get.find<AuthController>().loginWithPassword();
  }

  void _submitRegister() {
    if (!_registerFormKey.currentState!.validate()) return;
    Get.find<AuthController>().registerAccount();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appTagline,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.statusProcessingBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Obx(() => TabBar(
                          controller: _tabController,
                          onTap: (i) => controller.loginTabIndex.value = i,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textMedium,
                          labelStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          tabs: [
                            Tab(text: AppStrings.loginTab),
                            Tab(text: AppStrings.registerTab),
                          ],
                        )),
                  ),
                  // تزامن التبويب مع الاختيار البرمجي (بعد نجاح التسجيل).
                  Obx(() {
                    final target = controller.loginTabIndex.value;
                    if (_tabController.index != target) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _tabController.index != target) {
                          _tabController.animateTo(target);
                        }
                      });
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 460,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginTab(controller),
                        _buildRegisterTab(controller),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.termsNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── تبويب تسجيل الدخول ─────────────────────────────────────
  Widget _buildLoginTab(AuthController controller) {
    return SingleChildScrollView(
      child: Form(
        key: _loginFormKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.loginSubtitle2,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel(AppStrings.emailOrPhone),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.loginIdentifierController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.rtl,
            validator: _validateIdentifier,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              hint: 'example@mail.com / 09xxxxxxxx',
              icon: Icons.alternate_email_outlined,
            ),
          ),
          const SizedBox(height: 14),
          _fieldLabel(AppStrings.password),
          const SizedBox(height: 6),
          TextFormField(
                controller: controller.passwordController,
                obscureText: _obscureLogin,
                textDirection: TextDirection.rtl,
                validator: (v) => (v ?? '').isEmpty
                    ? 'الرجاء إدخال كلمة المرور'
                    : null,
                textInputAction: TextInputAction.done,
                decoration: _decoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLogin
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscureLogin = !_obscureLogin),
                  ),
                ),
              ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  Get.toNamed(AppRoutes.passwordReset),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                AppStrings.forgotPassword,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed:
                      controller.isLoading.value ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor:
                        AppColors.primary.withValues(alpha: 0.35),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.loginBtn),
                )),
          ),
        ],
      ),
    ),
  );
}

  // ─── تبويب إنشاء حساب جديد ──────────────────────────────────
  Widget _buildRegisterTab(AuthController controller) {
    return SingleChildScrollView(
      child: Form(
        key: _registerFormKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.registerSubtitle,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          _fieldLabel(AppStrings.username),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.regUsernameController,
            textDirection: TextDirection.rtl,
            validator: _validateRequired,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              hint: 'e.g. citizen1',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel(AppStrings.phoneNumber),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.regPhoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.rtl,
            validator: _validatePhone,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              hint: '09xxxxxxxx',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel(AppStrings.password),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.regPasswordController,
            obscureText: _obscureRegister,
            textDirection: TextDirection.rtl,
            validator: (v) => (v ?? '').length < 8
                ? 'كلمة المرور يجب ألا تقل عن 8 أحرف'
                : null,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegister
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: () =>
                    setState(() => _obscureRegister = !_obscureRegister),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel(AppStrings.confirmPassword),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.regConfirmController,
            obscureText: _obscureRegisterConfirm,
            textDirection: TextDirection.rtl,
            validator: (v) => v != controller.regPasswordController.text
                ? 'كلمتا المرور غير متطابقتين'
                : null,
            textInputAction: TextInputAction.done,
            decoration: _decoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
                onPressed: () => setState(
                    () => _obscureRegisterConfirm = !_obscureRegisterConfirm),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed:
                      controller.isRegistering.value ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor:
                        AppColors.primary.withValues(alpha: 0.35),
                  ),
                  child: controller.isRegistering.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.registerBtn),
                )),
          ),
        ],
      ),
    ),
  );
}

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      suffixIcon: Icon(icon, color: AppColors.textLight),
      errorStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.primary,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo_margin.png',
      width: 84,
      fit: BoxFit.contain,
    );
  }
}