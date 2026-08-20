import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../services/permission_service.dart';
import '../../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _navigateTimer = Timer(const Duration(seconds: 5), _navigate);
    _checkPermissions();
    _prefetchData();
  }

  /// استعلام سريع عن حالة أذونات الموقع والإشعارات وتسجيلها دون طلب نوافذ.
  Future<void> _checkPermissions() async {
    await PermissionService.instance.checkAndRecord();
  }

  /// تحميل البيانات الأولية — يُربط لاحقاً مع الباك ايند.
  Future<void> _prefetchData() async {}

  /// التنقل بعد انتهاء المؤقت بناءً على حالة التوثيق المخزنة.
  void _navigate() {
    if (!mounted) return;
    final isLoggedIn = SessionService.instance.isLoggedIn;
    Get.offAllNamed(isLoggedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_shield.png',
                  width: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appTagline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}