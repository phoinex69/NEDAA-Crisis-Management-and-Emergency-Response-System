import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/alerts_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/alert_model.dart';
import '../widgets/nidaa_app_bar.dart';

/// قائمة التنبيهات الفورية (متطلب 4.5) — تعرض كل تنبيهات الجهات المختصة
/// بترتيب زمني تنازلي مع لون حسب الخطورة، وتُحدَّث تلقائياً كل 60 ثانية.
class AlertsListScreen extends GetView<AlertsController> {
  const AlertsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const NidaaAppBar(showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppStrings.alertsTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppStrings.alertsSubtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadAlerts,
              child: Obx(() {
                final alerts = controller.alerts;
                if (alerts.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.notifications_off_outlined,
                          size: 64, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          AppStrings.noAlerts,
                          style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  static const Map<String, IconData> _typeIcons = {
    'weather': Icons.thunderstorm_outlined,
    'disaster': Icons.warning_amber_rounded,
    'road': Icons.route_outlined,
    'safety': Icons.health_and_safety_outlined,
    'other': Icons.notifications_active_outlined,
  };

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical':
        return AppColors.severityCritical;
      case 'high':
        return AppColors.severityHigh;
      case 'medium':
        return AppColors.severityMedium;
      case 'low':
        return AppColors.severityLow;
      default:
        return AppColors.infoBlue;
    }
  }

  Color get _severityBg {
    if (alert.severity == null) return AppColors.infoBlueBg;
    switch (alert.severity) {
      case 'critical':
        return AppColors.statusUrgentBg;
      case 'high':
        return AppColors.statusUrgentBg;
      case 'medium':
        return const Color(0xFFFFF7E6);
      case 'low':
        return AppColors.safePointBg;
      default:
        return AppColors.infoBlueBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[alert.type] ?? _typeIcons['other']!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _severityBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _severityColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (alert.severity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _severityBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _severityLabel(alert.severity!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _severityColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _timeAgo(alert.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return AppStrings.severityCritical;
      case 'high':
        return AppStrings.severityHigh;
      case 'medium':
        return AppStrings.severityMedium;
      case 'low':
        return AppStrings.severityLow;
      default:
        return severity;
    }
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return AppStrings.now;
    if (diff.inMinutes < 60) {
      return AppStrings.minutesAgo.replaceFirst('{n}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return AppStrings.hoursAgo.replaceFirst('{n}', '${diff.inHours}');
    }
    return AppStrings.daysAgo.replaceFirst('{n}', '${diff.inDays}');
  }
}