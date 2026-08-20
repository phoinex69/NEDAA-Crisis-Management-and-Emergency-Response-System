import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة اللغة: تبديل بين العربية (الافتراضية) والإنجليزية (متطلب 7.4).
class LocaleService extends GetxController {
  static const _langKey = 'app_language';

  static LocaleService get instance => Get.find<LocaleService>();

  final RxBool isEnglish = false.obs;

  Locale get currentLocale =>
      isEnglish.value ? const Locale('en') : const Locale('ar', 'SA');

  /// يعيد النص حسب اللغة الحالية: [ar] الافتراضي، و[en] بديل إنجليزي.
  String t(String ar, {String? en}) => isEnglish.value ? (en ?? ar) : ar;

  /// استرجاع اللغة المحفوظة عند الإقلاع.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    isEnglish.value = prefs.getBool(_langKey) ?? false;
  }

  Future<void> setEnglish(bool value) async {
    if (isEnglish.value == value) return;
    isEnglish.value = value;
    Get.updateLocale(currentLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, value);
  }
}