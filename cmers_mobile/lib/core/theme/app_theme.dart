import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  /// مرشح رفع التباين العالمي (متطلب 7.4): يُطبَّق على كامل الواجهة عند
  /// تفعيل "التباين العالي" — الألوان الداكنة تزداد دكانة والفاتحة تزداد
  /// سطوعاً (نسبة تباين أعلى) لأن مكوّنات الواجهة تستخدم ألواناً ثابتة
  /// خارج الثيم، فلا يكفي تبديل ThemeData وحده.
  static const ColorFilter highContrastFilter = ColorFilter.matrix(<double>[
    1.8, 0, 0, 0, -95,
    0, 1.8, 0, 0, -95,
    0, 0, 1.8, 0, -95,
    0, 0, 0, 1, 0,
  ]);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
          ),
        ),
      );

  /// ثيم التباين العالي (متطلب 7.4) — خلفية بيضاء نقية ونصوص داكنة
  /// وحدود أوضح لمستخدمي ذوي الاحتياجات البصرية.
  static ThemeData get highContrast {
    final base = lightTheme;
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: Colors.white,
      ),
    );
  }
}
