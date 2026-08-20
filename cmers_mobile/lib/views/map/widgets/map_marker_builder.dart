import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// يبني ماركرات مخصصة كـ Widgets (flutter_map) — تُرسم محلياً بدون أصول خارجية.
class MapMarkerBuilder {
  static Widget hospitalMarker() {
    return _pin(
      background: const Color(0xFF1A56DB),
      icon: Icons.medical_services,
      label: AppStrings.hospital,
      labelColor: const Color(0xFF1A56DB),
      circular: false,
    );
  }

  static Widget dangerMarker() {
    return _pin(
      background: AppColors.primary,
      icon: Icons.warning_amber_rounded,
      label: AppStrings.dangerZone,
      labelColor: AppColors.primary,
      circular: true,
    );
  }

  /// ماركر مركز الإيواء (متطلب 4.6).
  static Widget shelterMarker() {
    return _pin(
      background: AppColors.shelterColor,
      icon: Icons.roofing_rounded,
      label: AppStrings.shelters,
      labelColor: AppColors.shelterColor,
      circular: true,
    );
  }

  /// ماركر نقطة التجمع الآمنة (متطلب 4.6).
  static Widget safePointMarker() {
    return _pin(
      background: AppColors.safePointColor,
      icon: Icons.flag_rounded,
      label: AppStrings.safePoints,
      labelColor: AppColors.safePointColor,
      circular: true,
    );
  }

  /// ماركر مركز خدمة (شرطة...) — اسم فقط باللون الأزرق مع نقطة صغيرة.
  static Widget serviceCenterMarker(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.infoBlue.withValues(alpha: 0.6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.infoBlue,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.infoBlue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _pin({
    required Color background,
    required IconData icon,
    required String label,
    required Color labelColor,
    required bool circular,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: background,
            shape: circular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                circular ? null : BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}