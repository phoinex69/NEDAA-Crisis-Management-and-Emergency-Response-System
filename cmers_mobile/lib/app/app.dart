import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import '../controllers/accessibility_controller.dart';
import '../controllers/alerts_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/map_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/reports_controller.dart';
import '../controllers/sos_controller.dart';
import '../core/constants/app_routes.dart';
import '../core/localization/locale_service.dart';
import '../core/theme/app_theme.dart';
import '../views/alerts/alerts_list_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/otp_screen.dart';
import '../views/auth/password_reset_screen.dart';
import '../views/main_scaffold.dart';
import '../views/map/map_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/reports/report_category_screen.dart';
import '../views/reports/report_details_screen.dart';
import '../views/reports/report_tracking_screen.dart';
import '../views/reports/reports_list_screen.dart';
import '../views/sos/sos_countdown_screen.dart';
import '../views/splash/splash_screen.dart';

class NidaaApp extends StatelessWidget {
  const NidaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // يُلتف حول GetMaterialApp بـ Obx حتى يعاد البناء فورياً عند تغيير
    // خيارات الإتاحة (التباين العالي والخط الكبير) أو اللغة (متطلب 7.4).
    return Obx(() {
      final accessibility = Get.find<AccessibilityController>();
      // قراءة القيمتين داخل نطاق Obx لإنشاء اشتراك تفاعلي بهما:
      // بدون ذلك لا يُعاد بناء التطبيق عند تغيير حجم الخط (نص عالق).
      final fontScale = accessibility.fontScale.value;
      final highContrast = accessibility.highContrast.value;
      return GetMaterialApp(
        title: 'نداء',
        debugShowCheckedModeBanner: false,
        theme: highContrast ? AppTheme.highContrast : AppTheme.lightTheme,
        // الاتجاه يُشتق تلقائياً من اللغة: عربي = RTL، إنجليزي = LTR (متطلب 7.4).
        locale: Get.find<LocaleService>().currentLocale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // تطبيق حجم الخط المُختار (الإتاحة) عبر كل الشاشات، ومرشح رفع
        // التباين عند تفعيل "التباين العالي" (متطلب 7.4).
        builder: (context, child) {
          final scaled = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(fontScale),
            ),
            child: child!,
          );
          return highContrast
              ? ColorFiltered(
                  colorFilter: AppTheme.highContrastFilter,
                  child: scaled,
                )
              : scaled;
        },
        initialBinding: BindingsBuilder(() {
          // LocaleService و OfflineQueueService و AccessibilityController
          // مسجّلون في main.dart قبل runApp.
          Get.put(AuthController());
          Get.put(NavController());
          Get.put(ReportsController());
          Get.put(ProfileController());
          Get.put(MapController());
          Get.put(SosController());
          Get.put(AlertsController());
          Get.find<AlertsController>().startPolling();
        }),
        initialRoute: AppRoutes.splash,
        getPages: [
          GetPage(
            name: AppRoutes.splash,
            page: () => const SplashScreen(),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const LoginScreen(),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: AppRoutes.otp,
            page: () => const OtpScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.passwordReset,
            page: () => const PasswordResetScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.home,
            page: () => const MainScaffold(),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: AppRoutes.reportsList,
            page: () => const ReportsListScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.reportCategory,
            page: () => const ReportCategoryScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.reportDetails,
            page: () => const ReportDetailsScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.reportTracking,
            page: () => const ReportTrackingScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.profile,
            page: () => const ProfileScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.alertsList,
            page: () => const AlertsListScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
          GetPage(
            name: AppRoutes.sosCountdown,
            page: () => const SosCountdownScreen(),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: AppRoutes.map,
            page: () => const MapScreen(),
            transition: Transition.rightToLeftWithFade,
          ),
        ],
      );
    });
  }
}