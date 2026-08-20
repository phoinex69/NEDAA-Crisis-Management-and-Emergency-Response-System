import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الإتاحة (متطلب 7.4): خيارات لذوي الاحتياجات الخاصة —
/// تكبير الخط وتباين عالٍ، محفوظة محلياً.
/// وضع توفير البيانات (4.9): يُفعّل من حسابي ويقلل استهلاك البيانات.
class AccessibilityController extends GetxController {
  static const String _fontScaleKey = 'accessibility_font_scale';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _lowDataModeKey = 'low_data_mode';

  static const double normalFontScale = 1.0;
  static const double largeFontScale = 1.25;

  RxDouble fontScale = normalFontScale.obs;
  RxBool highContrast = false.obs;
  RxBool lowDataMode = false.obs;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    fontScale.value = prefs.getDouble(_fontScaleKey) ?? normalFontScale;
    highContrast.value = prefs.getBool(_highContrastKey) ?? false;
    lowDataMode.value = prefs.getBool(_lowDataModeKey) ?? false;
  }

  Future<void> toggleFontScale() async {
    fontScale.value =
        fontScale.value == largeFontScale ? normalFontScale : largeFontScale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, fontScale.value);
  }

  Future<void> toggleHighContrast() async {
    highContrast.value = !highContrast.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, highContrast.value);
  }

  Future<void> toggleLowDataMode() async {
    lowDataMode.value = !lowDataMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowDataModeKey, lowDataMode.value);
  }
}