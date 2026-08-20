import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/danger_zone_model.dart';
import '../../../models/hospital_model.dart';
import '../../../models/safe_point_model.dart';
import '../../../models/service_center_model.dart';
import '../../../models/shelter_model.dart';

void showZoneInfoSheet(
  BuildContext context,
  DangerZoneModel zone, {
  HospitalModel? nearestHospital,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ZoneInfoSheet(
      zone: zone,
      nearestHospital: nearestHospital,
    ),
  );
}

void showHospitalInfoSheet(
    BuildContext context, HospitalModel hospital) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _HospitalInfoSheet(hospital: hospital),
  );
}

void showServiceCenterInfoSheet(
    BuildContext context, ServiceCenterModel center) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ServiceCenterInfoSheet(center: center),
  );
}

void showShelterInfoSheet(BuildContext context, ShelterModel shelter) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ShelterInfoSheet(shelter: shelter),
  );
}

void showSafePointInfoSheet(BuildContext context, SafePointModel point) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SafePointInfoSheet(point: point),
  );
}

class _ZoneInfoSheet extends StatelessWidget {
  final DangerZoneModel zone;
  final HospitalModel? nearestHospital;

  const _ZoneInfoSheet({required this.zone, this.nearestHospital});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'سبب الخطر',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            zone.cause,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تعليمات السلامة',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...zone.safetyInstructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: AppColors.severityLow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instruction,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (nearestHospital != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _openDirections(
                  nearestHospital!.position.latitude,
                  nearestHospital!.position.longitude,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.infoBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.directions,
                    color: AppColors.white),
                label: Text(
                  'المسار إلى أقرب مشفى (${nearestHospital!.name})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ServiceCenterInfoSheet extends StatelessWidget {
  final ServiceCenterModel center;

  const _ServiceCenterInfoSheet({required this.center});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.infoBlueBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_police,
                    color: AppColors.infoBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  center.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _openDirections(center.position.latitude,
                  center.position.longitude),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.infoBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.directions, color: AppColors.white),
              label: const Text(
                'المسار إلى المركز',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ShelterInfoSheet extends StatelessWidget {
  final ShelterModel shelter;

  const _ShelterInfoSheet({required this.shelter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.shelterColorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.roofing_rounded,
                    color: AppColors.shelterColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shelter.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shelter.phone != null && shelter.phone!.isNotEmpty) ...[
            Text(
              'الهاتف: ${shelter.phone}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
          ],
          if (shelter.capacity != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 15, color: AppColors.textMedium),
                const SizedBox(width: 6),
                Text(
                  'الطاقة الاستيعابية: ${shelter.capacity} شخص',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _openDirections(shelter.position.latitude,
                  shelter.position.longitude),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.shelterColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.directions, color: AppColors.white),
              label: const Text(
                'المسار إلى مركز الإيواء',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SafePointInfoSheet extends StatelessWidget {
  final SafePointModel point;

  const _SafePointInfoSheet({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.safePointBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded,
                    color: AppColors.safePointColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  point.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (point.description != null && point.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              point.description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _openDirections(point.position.latitude,
                  point.position.longitude),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.safePointColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.directions, color: AppColors.white),
              label: const Text(
                'المسار إلى نقطة التجمع',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _HospitalInfoSheet extends StatelessWidget {
  final HospitalModel hospital;

  const _HospitalInfoSheet({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.infoBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services,
                    color: AppColors.infoBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (hospital.phone != null) ...[
            const SizedBox(height: 12),
            Text(
              'الهاتف: ${hospital.phone}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _openDirections(hospital.position.latitude,
                  hospital.position.longitude),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.infoBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.directions, color: AppColors.white),
              label: const Text(
                'المسار إلى المشفى',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}