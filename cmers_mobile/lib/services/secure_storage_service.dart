import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين مشفّر للبيانات الحساسة (متطلب 7.2):
/// التوكنات والبطاقة الطبية — عبر Android Keystore / iOS Keychain / Windows DPAPI.
///
/// يحتفظ بنسخة في الذاكرة ليسمح بقراءات متزامنة (مطلوبة داخل Interceptor
/// التوكن في [ApiClient]) بعد تهيئة [SessionService.init] عند الإقلاع.
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final Map<String, String> _cache = {};

  /// قراءة متزامنة للقيمة المخزنة في الذاكرة (بعد التهيئة).
  String? cached(String key) => _cache[key];

  Future<String?> read(String key) async {
    final cachedValue = _cache[key];
    if (cachedValue != null) return cachedValue;
    final value = await _storage.read(key: key);
    if (value != null) _cache[key] = value;
    return value;
  }

  Future<void> write(String key, String value) async {
    _cache[key] = value;
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    _cache.remove(key);
    await _storage.delete(key: key);
  }
}