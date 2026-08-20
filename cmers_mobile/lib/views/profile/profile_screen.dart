import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/accessibility_controller.dart';
import '../../controllers/map_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../core/localization/locale_service.dart';
import '../../models/emergency_contact_model.dart';
import '../../models/medical_card_model.dart';
import '../../services/map_offline_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: AppColors.textDark, size: 24),
            onPressed: () => Get.toNamed(AppRoutes.alertsList),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.profile,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _UserCard(authCtrl: authCtrl),
            const SizedBox(height: 24),
            Text(
              AppStrings.emergencyContacts,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.contactsNote,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (profileCtrl.emergencyContacts.isEmpty) {
                return const _EmptyContactsCard();
              }
              return Column(
                children: profileCtrl.emergencyContacts
                    .map((c) => _ContactCard(
                          contact: c,
                          onDelete: () =>
                              profileCtrl.confirmDeleteContact(c.id, c.name),
                          onEdit: () => _showAddContactSheet(context, profileCtrl,
                              contact: c),
                        ))
                    .toList(),
              );
            }),
            const SizedBox(height: 8),
            _AddContactButton(
              onTap: () => _showAddContactSheet(context, profileCtrl),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.medicalCard,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _MedicalCardSection(profileCtrl: profileCtrl),
            const SizedBox(height: 24),
            Text(
              AppStrings.language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const _LanguageToggle(),
            const SizedBox(height: 24),
            const _AccessibilitySection(),
            const SizedBox(height: 24),
            const _MapDownloadCard(),
            const SizedBox(height: 24),
            Text(
              AppStrings.publicEmergency,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...profileCtrl.publicNumbers.map(
              (n) => _PublicNumberCard(
                number: n,
                onTap: () => profileCtrl.callNumber(n.number),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCC1C2E),
                  side: const BorderSide(color: Color(0xFFCC1C2E)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => authCtrl.logout(),
                icon: const Icon(Icons.logout, size: 20),
                label: Text(
                  AppStrings.logout,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddContactSheet(BuildContext context, ProfileController ctrl,
      {EmergencyContactModel? contact}) async {
    final isEdit = contact != null;
    final nameCtrl = TextEditingController(text: contact?.name);
    final relCtrl = TextEditingController(text: contact?.relation);
    final phoneCtrl = TextEditingController(text: contact?.phone);

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? AppStrings.editContactTitle : AppStrings.addContactTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                      labelText: AppStrings.contactName),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: relCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                      labelText: AppStrings.contactRelation),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                      labelText: AppStrings.contactPhone),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // قراءة القيم قبل الإغلاق ثم إغلاق النافذة فوراً —
                          // الحفظ يتم في الخلفية ويُعلَّم بإشعار.
                          final name = nameCtrl.text;
                          final relation = relCtrl.text;
                          final phone = phoneCtrl.text;
                          Get.back();
                          if (isEdit) {
                            ctrl.updateContact(
                              id: contact.id,
                              name: name,
                              relation: relation,
                              phone: phone,
                            );
                          } else {
                            ctrl.addContact(name, relation, phone);
                          }
                        },
                        child: Text(isEdit ? AppStrings.save : AppStrings.add),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      // تأجيل الإتلاف حتى تنتهي حركة إغلاق النافذة (يمنع كراش _dependents).
      Future.delayed(const Duration(milliseconds: 400), () {
        nameCtrl.dispose();
        relCtrl.dispose();
        phoneCtrl.dispose();
      });
    }
  }
}

class _UserCard extends StatelessWidget {
  final AuthController authCtrl;
  const _UserCard({required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.statusClosedBg,
            child: Icon(Icons.person, size: 30, color: AppColors.textMedium),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(() {
              final name = authCtrl.currentUser.value?.name ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.trim().isEmpty ? 'مستخدم' : name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authCtrl.currentUser.value?.phone ?? '',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
              );
            }),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.infoBlue, size: 20),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(
        text: authCtrl.currentUser.value?.name ?? '');

    try {
      await Get.dialog(
        Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(AppStrings.editProfile),
            content: TextField(
              controller: nameCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: AppStrings.contactName,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(AppStrings.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  // قراءة الاسم قبل الإغلاق ثم إغلاق الحوار فوراً —
                  // الحفظ يتم في الخلفية ويُعلَّم بإشعار.
                  final name = nameCtrl.text;
                  Get.back();
                  Get.find<ProfileController>()
                      .updateName(name)
                      .then((ok) {
                        if (ok) {
                          Get.snackbar('تم الحفظ', 'تم تحديث اسم المستخدم',
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      });
                },
                child: Text(AppStrings.save),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } finally {
      // تأجيل الإتلاف حتى تنتهي حركة إغلاق الحوار (يمنع كراش _dependents).
      Future.delayed(const Duration(milliseconds: 400), nameCtrl.dispose);
    }
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DottedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _EmptyContactsCard extends StatelessWidget {
  const _EmptyContactsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.contacts_outlined,
              color: AppColors.textMedium, size: 28),
          const SizedBox(height: 8),
          Text(
            AppStrings.noContacts,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.noContactsHint,
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddContactButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddContactButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter:
            const _DottedBorderPainter(color: AppColors.primary, radius: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 24),
              const SizedBox(height: 4),
              Text(
                AppStrings.addContact,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ContactCard({
    required this.contact,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.infoBlueBg,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person, size: 20, color: AppColors.infoBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  contact.relation,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
                Text(
                  contact.phone,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.infoBlue, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.primary, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PublicNumberCard extends StatelessWidget {
  final PublicEmergencyNumber number;
  final VoidCallback onTap;

  const _PublicNumberCard({required this.number, required this.onTap});  Color get _iconColor {
    switch (number.iconType) {
      case 'police':
        return AppColors.primary;
      case 'ambulance':
        return const Color(0xFF1A56DB);
      case 'fire':
        return Colors.deepOrange;
      default:
        return AppColors.primary;
    }
  }

  Color get _iconBg {
    switch (number.iconType) {
      case 'police':
        return AppColors.statusUrgentBg;
      case 'ambulance':
        return AppColors.statusProcessingBg;
      case 'fire':
        return const Color(0xFFFFF3E0);
      default:
        return AppColors.statusUrgentBg;
    }
  }

  IconData get _icon {
    switch (number.iconType) {
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.medical_services;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Text(
              number.number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _iconColor,
              ),
            ),
            const Spacer(),
            Text(
              number.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: _iconBg, shape: BoxShape.circle),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// البطاقة الطبية الطارئة (متطلب 4.7): فصيلة الدم والحساسية والأمراض
/// والأدوية وبيانات التواصل الطارئ — متاحة للمستجيبين عند الحاجة.
class _MedicalCardSection extends StatelessWidget {
  final ProfileController profileCtrl;
  const _MedicalCardSection({required this.profileCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.statusUrgentBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_liquid_outlined,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.medicalCardHint,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.infoBlue, size: 20),
                onPressed: () => _showMedicalCardSheet(context),
              ),
            ],
          ),
          Obx(() {
            final card = profileCtrl.medicalCard.value;
            if (card == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 20),
                _row(Icons.water_drop_outlined,
                    '${AppStrings.bloodType}: ${card.bloodType ?? ''}'),
                if (card.allergies.isNotEmpty)
                  _row(Icons.warning_amber_outlined,
                      '${AppStrings.allergies}: ${card.allergies.join('، ')}'),
                if (card.chronicDiseases.isNotEmpty)
                  _row(Icons.heart_broken_outlined,
                      '${AppStrings.chronicDiseases}: ${card.chronicDiseases.join('، ')}'),
                if (card.medications.isNotEmpty)
                  _row(Icons.medication_outlined,
                      '${AppStrings.medications}: ${card.medications.join('، ')}'),
                if (card.emergencyContactName != null &&
                    card.emergencyContactName!.isNotEmpty)
                  _row(Icons.contact_phone_outlined,
                      '${card.emergencyContactName} — ${card.emergencyContactPhone ?? ''}'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMedicalCardSheet(BuildContext context) async {
    final card = profileCtrl.medicalCard.value ??
        const MedicalCardModel();
    List<String> splitList(String raw) => raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final bloodCtrl = TextEditingController(text: card.bloodType);
    final allergiesCtrl =
        TextEditingController(text: card.allergies.join('، '));
    final diseasesCtrl =
        TextEditingController(text: card.chronicDiseases.join('، '));
    final medsCtrl =
        TextEditingController(text: card.medications.join('، '));
    final contactNameCtrl =
        TextEditingController(text: card.emergencyContactName);
    final contactPhoneCtrl =
        TextEditingController(text: card.emergencyContactPhone);
    const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.medicalCard,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: card.bloodType == null ||
                          card.bloodType!.isEmpty
                      ? null
                      : card.bloodType,
                  items: bloodTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setSheetState(() {
                    bloodCtrl.text = v ?? '';
                  }),
                  decoration: InputDecoration(
                    labelText: AppStrings.bloodType,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                _sheetField(allergiesCtrl, AppStrings.allergies),
                const SizedBox(height: 8),
                _sheetField(diseasesCtrl, AppStrings.chronicDiseases),
                const SizedBox(height: 8),
                _sheetField(medsCtrl, AppStrings.medications),
                const SizedBox(height: 8),
                _sheetField(contactNameCtrl, AppStrings.emergencyContactName),
                const SizedBox(height: 8),
                _sheetField(contactPhoneCtrl, AppStrings.emergencyContactPhone,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final contactPhone =
                              contactPhoneCtrl.text.trim();
                          final phoneError = contactPhone.isEmpty
                              ? null
                              : validateSyrianPhone(contactPhone);
                          if (phoneError != null) {
                            Get.snackbar('خطأ', phoneError,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: const Color(0xFFCC1C2E),
                                colorText: const Color(0xFFFFFFFF));
                            return;
                          }
                          profileCtrl.saveMedicalCard(MedicalCardModel(
                            bloodType: bloodCtrl.text.trim().isEmpty
                                ? null
                                : bloodCtrl.text.trim(),
                            allergies: splitList(allergiesCtrl.text),
                            chronicDiseases: splitList(diseasesCtrl.text),
                            medications: splitList(medsCtrl.text),
                            emergencyContactName:
                                contactNameCtrl.text.trim().isEmpty
                                    ? null
                                    : contactNameCtrl.text.trim(),
                            emergencyContactPhone: contactPhone.isEmpty
                                ? null
                                : contactPhone,
                          ));
                          Get.back();
                        },
                        child: Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    } finally {
      // تأجيل الإتلاف حتى تنتهي حركة إغلاق النافذة (يمنع كراش _dependents).
      Future.delayed(const Duration(milliseconds: 400), () {
        bloodCtrl.dispose();
        allergiesCtrl.dispose();
        diseasesCtrl.dispose();
        medsCtrl.dispose();
        contactNameCtrl.dispose();
        contactPhoneCtrl.dispose();
      });
    }
  }

  Widget _sheetField(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      textDirection: TextDirection.rtl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// تبديل لغة التطبيق بين العربية والإنجليزية (متطلب 7.4).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleService>();
    return Obx(() {
      final isEnglish = locale.isEnglish.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: _langChip(
                label: 'العربية',
                selected: !isEnglish,
                onTap: () => locale.setEnglish(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _langChip(
                label: 'English',
                selected: isEnglish,
                onTap: () => locale.setEnglish(true),
              ),
            ),
],
      ),
    );
  });
}

  Widget _langChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }
}

/// تحميل خريطة منطقتي مسبقاً للعمل أوفلاين (متطلب 4.9):
/// بلاطات FMTC (زوم 11→16، سقف 300MB) + حجم الكاش الحالي.
class _MapDownloadCard extends StatefulWidget {
  const _MapDownloadCard();

  @override
  State<_MapDownloadCard> createState() => _MapDownloadCardState();
}

class _MapDownloadCardState extends State<_MapDownloadCard> {
  @override
  void initState() {
    super.initState();
    Get.find<MapOfflineService>().refreshCacheSize();
  }

  Future<void> _startDownload() async {
    final mapCtrl = Get.find<MapController>();
    final location = mapCtrl.userLocation.value ??
        Get.find<SosController>().userLocation.value;
    if (location == null) {
      Get.snackbar(
        AppStrings.mapDownload,
        AppStrings.mapDownloadNeedLocation,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }
    await Get.find<MapOfflineService>().downloadRegion(center: location);
  }

  @override
  Widget build(BuildContext context) {
    final offline = Get.find<MapOfflineService>();
    return Obx(() {
      final sizeKiB = offline.cachedSizeKiB.value;
      final sizeMb =
          sizeKiB == null ? null : (sizeKiB / 1024).toStringAsFixed(1);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.mapDownload,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.mapDownloadHint,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium),
            ),
            const SizedBox(height: 10),
            if (offline.isDownloading.value) ...[
              LinearProgressIndicator(
                value: offline.progress.value / 100,
                backgroundColor: AppColors.statusProcessingBg,
                color: AppColors.primary,
                minHeight: 6,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.mapDownloadProgress.replaceAll(
                    '{percent}', offline.progress.value.round().toString()),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium),
              ),
              const SizedBox(height: 4),
              Text(
                offline.statusText.value,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: offline.cancelDownload,
                icon: const Icon(Icons.stop, size: 16),
                label: Text(AppStrings.mapDownloadCancel),
              ),
            ] else ...[
              Text(
                sizeMb != null
                    ? AppStrings.mapCacheSize.replaceAll('{size}', sizeMb)
                    : AppStrings.mapNoCache,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(AppStrings.mapDownloadStart),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// قسم الإتاحة (متطلب 7.4): تكبير الخط + التباين العالي.
class _AccessibilitySection extends StatelessWidget {
  const _AccessibilitySection();

  @override
  Widget build(BuildContext context) {
    final accessibility = Get.find<AccessibilityController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.accessibility,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.accessibilityHint,
          style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
        ),
        const SizedBox(height: 12),
        Obx(() => _AccessibilityRow(
              icon: Icons.format_size,
              label: AppStrings.largeText,
              value: accessibility.fontScale.value > 1,
              onChanged: (_) => accessibility.toggleFontScale(),
            )),
        const SizedBox(height: 8),
        Obx(() => _AccessibilityRow(
              icon: Icons.contrast,
              label: AppStrings.highContrast,
              value: accessibility.highContrast.value,
              onChanged: (_) => accessibility.toggleHighContrast(),
            )),
        const SizedBox(height: 8),
        Obx(() => _AccessibilityRow(
              icon: Icons.data_saver_on,
              label: AppStrings.lowDataMode,
              hint: AppStrings.lowDataModeHint,
              value: accessibility.lowDataMode.value,
              onChanged: (_) => accessibility.toggleLowDataMode(),
            )),
      ],
    );
  }
}

class _AccessibilityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccessibilityRow({
    required this.icon,
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMedium),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}