import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/validators.dart';
import '../models/emergency_contact_model.dart';
import '../models/medical_card_model.dart';
import '../models/user_model.dart';
import '../services/backend_data_source.dart';
import '../services/secure_storage_service.dart';
import '../services/session_service.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  static const String _medicalCardKey = 'medical_card';
  static const String _contactsKey = 'emergency_contacts';

  final BackendDataSource _backend = BackendProvider.dataSource;

  final RxList<EmergencyContactModel> emergencyContacts =
      <EmergencyContactModel>[].obs;
  final Rx<MedicalCardModel?> medicalCard = Rx<MedicalCardModel?>(null);
  final RxBool isUpdatingProfile = false.obs;
  final RxBool isSavingMedicalCard = false.obs;

  final List<PublicEmergencyNumber> publicNumbers = [
    PublicEmergencyNumber(
        label: 'الشرطة', number: '112', iconType: 'police'),
    PublicEmergencyNumber(
        label: 'الإسعاف', number: '110', iconType: 'ambulance'),
    PublicEmergencyNumber(
        label: 'الإطفاء', number: '113', iconType: 'fire'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadContacts();
    _loadMedicalCard();
  }

  Future<void> _loadMedicalCard() async {
    try {
      final card = await _backend.fetchMedicalCard();
      if (card != null) {
        // الخادم لا يخزّن جهة الاتصال الطارئة — تُعاد تطبيقها من النسخة المحلية.
        final cached = await _readCachedCard();
        medicalCard.value = _mergeEmergencyContact(card, cached);
        // نسخة مشفّرة محلياً (متطلب 7.2) — متاحة أيضاً عند تعذّر الخادم.
        await SecureStorageService.instance
            .write(_medicalCardKey, jsonEncode(medicalCard.value!.toJson()));
      }
    } catch (_) {
      // لا بطاقة من الخادم — استرجاع النسخة المشفّرة المحلية إن وُجدت.
      final cached = await _readCachedCard();
      if (cached != null) {
        medicalCard.value = cached;
      }
    }
  }

  Future<MedicalCardModel?> _readCachedCard() async {
    final cached = await SecureStorageService.instance.read(_medicalCardKey);
    if (cached == null) return null;
    try {
      return MedicalCardModel.fromJson(
          jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {
      // تجاهل النسخة التالفة.
      return null;
    }
  }

  /// الخادم لا يخزّن جهة الاتصال الطارئة في البطاقة الطبية — تُحفظ محلياً
  /// وتُعاد تطبيقها عند الجلب من الخادم.
  MedicalCardModel _mergeEmergencyContact(
      MedicalCardModel server, MedicalCardModel? local) {
    return MedicalCardModel(
      bloodType: server.bloodType,
      allergies: server.allergies,
      chronicDiseases: server.chronicDiseases,
      medications: server.medications,
      emergencyContactName:
          server.emergencyContactName ?? local?.emergencyContactName,
      emergencyContactPhone:
          server.emergencyContactPhone ?? local?.emergencyContactPhone,
    );
  }

  /// حفظ البطاقة الطبية الطارئة (متطلب 4.7).
  Future<void> saveMedicalCard(MedicalCardModel card) async {
    isSavingMedicalCard.value = true;
    try {
      final saved = await _backend.updateMedicalCard(card);
      // الخادم يخزّن فصيلة الدم والحساسيات والأمراض والأدوية فقط —
      // جهة الاتصال الطارئة تُحفظ محلياً وتُعاد تطبيقها.
      medicalCard.value = _mergeEmergencyContact(saved, card);
      await SecureStorageService.instance
          .write(_medicalCardKey, jsonEncode(saved.toJson()));
      // تأخير بسيط: قد تكون نافذة التحرير أُغلقت للتو — ننتظر نهاية حركة الإغلاق.
      await Future.delayed(const Duration(milliseconds: 350));
      Get.snackbar(AppStrings.medicalCard, AppStrings.medicalCardSaved,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: const Color(0xFFFFFFFF));
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 350));
      Get.snackbar('تعذر الحفظ', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
    } finally {
      isSavingMedicalCard.value = false;
    }
  }

  Future<void> _loadContacts() async {
    try {
      final fetched = await _backend.fetchContacts();
      final cached = await _readCachedContacts();
      final relationByPhone = {
        for (final c in cached)
          if (c.phone.isNotEmpty) c.phone: c.relation
      };
      // الخادم لا يخزّن الصلة — تُعاد تطبيقها من النسخة المحلية حسب رقم الجوال.
      emergencyContacts.assignAll(fetched.map((c) {
        final relation = relationByPhone[c.phone];
        return relation == null
            ? c
            : EmergencyContactModel(
                id: c.id, name: c.name, relation: relation, phone: c.phone);
      }));
      await _cacheContacts();
    } catch (_) {
      // تعذّر الجلب — استرجاع القائمة المخزنة محلياً.
      emergencyContacts.assignAll(await _readCachedContacts());
    }
  }

  Future<List<EmergencyContactModel>> _readCachedContacts() async {
    final raw = await SecureStorageService.instance.read(_contactsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheContacts() async {
    await SecureStorageService.instance.write(
        _contactsKey,
        jsonEncode(
            emergencyContacts.map((c) => c.toJson()).toList()));
  }

  /// تحديث الاسم على الخادم وحفظ الجلسة محلياً.
  /// لا تُغلق النوافذ من هنا (لتجنّب كراش الإغلاق المزدوج) —
  /// المتصل يعرض رسالة النجاح ويغلق النافذة بنفسه. تُرجع نجاحاً أم لا.
  Future<bool> updateName(String name) async {
    if (isUpdatingProfile.value) return false;
    final authCtrl = Get.find<AuthController>();
    final user = authCtrl.currentUser.value;
    if (user == null) return false;
    if (name.trim().isEmpty) {
      Get.snackbar('حقل مطلوب', 'الرجاء إدخال الاسم',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
      return false;
    }

    isUpdatingProfile.value = true;
    try {
      final updated = await _backend.updateProfile(name: name.trim());
      final merged = _mergeUser(user, updated);
      authCtrl.currentUser.value = merged;
      await _saveSession(merged);
      return true;
    } catch (e) {
      Get.snackbar('تعذر الحفظ', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
      return false;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  UserModel _mergeUser(UserModel current, UserModel updated) {
    return UserModel(
      id: updated.id.isNotEmpty ? updated.id : current.id,
      name: updated.name.isNotEmpty ? updated.name : current.name,
      phone: updated.phone.isNotEmpty ? updated.phone : current.phone,
      avatarUrl: updated.avatarUrl ?? current.avatarUrl,
    );
  }

  Future<void> _saveSession(UserModel user) async {
    await SessionService.instance.saveSession(
      token: SessionService.instance.token ?? '',
      userJson: jsonEncode(user.toJson()),
    );
  }

  Future<void> addContact(String name, String relation, String phone) async {
    final phoneError = validateSyrianPhone(phone);
    if (name.trim().isEmpty || relation.trim().isEmpty || phoneError != null) {
      Get.snackbar('خطأ', phoneError ?? 'يرجى تعبئة الاسم والصفة ورقم الجوال',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
      return;
    }
    try {
      final created = await _backend.addContact(
        name: name.trim(),
        relation: relation.trim(),
        phone: phone.trim(),
      );
      // الخادم لا يخزّن الصلة — تُحفظ محلياً وتُعاد تطبيقها عند كل جلب.
      final withRelation = EmergencyContactModel(
        id: created.id,
        name: created.name,
        relation: relation.trim(),
        phone: created.phone,
      );
      emergencyContacts.add(withRelation);
      Get.snackbar('تمت الإضافة', 'تم إضافة جهة الاتصال بنجاح',
          snackPosition: SnackPosition.BOTTOM);
      try {
        await _cacheContacts();
      } catch (_) {}
    } catch (e) {
      Get.snackbar('تعذر الإضافة', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
    }
  }

  /// تعديل جهة اتصال موجودة — تُحدَّث على الخادم (PUT) وفي التخزين المحلي.
  Future<void> updateContact({
    required String id,
    required String name,
    required String relation,
    required String phone,
  }) async {
    final phoneError = validateSyrianPhone(phone);
    if (name.trim().isEmpty || relation.trim().isEmpty || phoneError != null) {
      Get.snackbar('خطأ', phoneError ?? 'يرجى تعبئة الاسم والصفة ورقم الجوال',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
      return;
    }
    try {
      final updated = await _backend.updateContact(
        id: id,
        name: name.trim(),
        relation: relation.trim(),
        phone: phone.trim(),
      );
      final index = emergencyContacts.indexWhere((c) => c.id == id);
      if (index >= 0) {
        emergencyContacts[index] = EmergencyContactModel(
          id: updated.id,
          name: updated.name,
          relation: relation.trim(),
          phone: updated.phone,
        );
      }
      await _cacheContacts();
      Get.snackbar('تم الحفظ', 'تم تعديل جهة الاتصال',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('تعذر الحفظ', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
    }
  }

  Future<void> removeContact(String id) async {
    try {
      await _backend.deleteContact(id);
      emergencyContacts.removeWhere((c) => c.id == id);
      try {
        await _cacheContacts();
      } catch (_) {}
      // النافذة أُغلقت للتو — ننتظر نهاية حركة الإغلاق قبل إظهار الإشعار.
      await Future.delayed(const Duration(milliseconds: 350));
      Get.snackbar('تم الحذف', 'تم حذف جهة الاتصال',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 350));
      Get.snackbar('تعذر الحذف', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFCC1C2E),
          colorText: const Color(0xFFFFFFFF));
    }
  }

  void confirmDeleteContact(String id, String name) {
    Get.dialog(
      Builder(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(AppStrings.deleteConfirmTitle),
            content: Text('${AppStrings.deleteConfirmBody}\n$name'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: const Color(0xFFCC1C2E),
                ),
                onPressed: () {
                  // إغلاق مضمون عبر سياق الحوار نفسه ثم الحذف في الخلفية
                  // (رسالة النجاح/الخطأ من removeContact).
                  Navigator.pop(context);
                  removeContact(id);
                },
                child: Text(AppStrings.delete),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri);
    if (!launched) {
      Get.snackbar('تعذر الاتصال', 'تعذر الاتصال بالرقم $number',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}