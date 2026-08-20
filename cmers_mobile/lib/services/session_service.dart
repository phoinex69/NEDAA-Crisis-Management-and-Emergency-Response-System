import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// تخزين جلسة المستخدم محلياً لتبقى بعد إغلاق التطبيق.
///
/// التوكنات (الوصول + التجديد) محفوظة في التخزين المشفّر (متطلب 7.2)
/// عبر [SecureStorageService]، وبيانات المستخدم غير الحساسة (الاسم/الهاتف)
/// في SharedPreferences.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _refreshKey = 'auth_refresh_token';

  SharedPreferences? _prefs;
  String? _tokenCache;
  String? _refreshCache;

  /// يُستدعى مرة واحدة عند إقلاع التطبيق — يهيّئ SharedPreferences ويُرحّل
  /// التوكنات القديمة (كانت مخزنة plaintext قبل إضافة التشفير) إلى
  /// التخزين المشفّر ثم يملأ الذاكرة للقراءات المتزامنة.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final legacyToken = _prefs!.getString(_tokenKey);
    final legacyRefresh = _prefs!.getString(_refreshKey);
    if (legacyToken != null || legacyRefresh != null) {
      if (legacyToken != null) {
        await SecureStorageService.instance.write(_tokenKey, legacyToken);
        await _prefs!.remove(_tokenKey);
      }
      if (legacyRefresh != null) {
        await SecureStorageService.instance.write(_refreshKey, legacyRefresh);
        await _prefs!.remove(_refreshKey);
      }
    }
    _tokenCache = await SecureStorageService.instance.read(_tokenKey);
    _refreshCache = await SecureStorageService.instance.read(_refreshKey);
  }

  String? get token => _tokenCache;

  String? get userJson => _prefs?.getString(_userKey);

  String? get refreshToken => _refreshCache;

  bool get isLoggedIn =>
      _tokenCache?.isNotEmpty == true && _prefs?.getString(_userKey) != null;

  Future<void> saveSession({
    required String token,
    required String userJson,
    String? refreshToken,
  }) async {
    await SecureStorageService.instance.write(_tokenKey, token);
    _tokenCache = token;
    if (refreshToken != null) {
      await SecureStorageService.instance.write(_refreshKey, refreshToken);
      _refreshCache = refreshToken;
    }
    await _prefs?.setString(_userKey, userJson);
  }

  /// تحديث توكن الوصول بعد التجديد — بلا لمس بقية الجلسة.
  Future<void> saveAccessToken(String token) async {
    await SecureStorageService.instance.write(_tokenKey, token);
    _tokenCache = token;
  }

  Future<void> clear() async {
    await SecureStorageService.instance.delete(_tokenKey);
    await SecureStorageService.instance.delete(_refreshKey);
    _tokenCache = null;
    _refreshCache = null;
    await _prefs?.remove(_userKey);
  }
}