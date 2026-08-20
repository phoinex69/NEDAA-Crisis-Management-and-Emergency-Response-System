/// تحقق موحد من صيغة أرقام الهاتف السورية في كل حقول التطبيق.
///
/// يقبل الصيغتين:
/// - المحلية: 09xxxxxxxx (10 أرقام)
/// - الدولية: +9639xxxxxxxx (13 رقماً)
String? validateSyrianPhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'الرجاء إدخال رقم الهاتف';
  final digits = v.replaceAll(RegExp(r'[\s\-()]'), '');
  final local = RegExp(r'^09\d{8}$');
  final intl = RegExp(r'^\+9639\d{8}$');
  if (!local.hasMatch(digits) && !intl.hasMatch(digits)) {
    return 'رقم غير صحيح — استخدم 09xxxxxxxx أو +9639xxxxxxxx';
  }
  return null;
}