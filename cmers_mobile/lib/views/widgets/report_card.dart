import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/report_model.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final bool showProgress;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.report,
    this.showProgress = false,
    this.onTap,
  });

  Color get _statusColor {
    switch (report.status) {
      case ReportStatus.received:
      case ReportStatus.underReview:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return AppColors.statusProcessing;
      case ReportStatus.closed:
        return AppColors.statusClosed;
    }
  }

  Color get _statusBg {
    switch (report.status) {
      case ReportStatus.received:
      case ReportStatus.underReview:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return AppColors.statusProcessingBg;
      case ReportStatus.closed:
        return AppColors.statusClosedBg;
    }
  }

  Widget get _categoryIcon {
    switch (report.category) {
      case ReportCategory.ambulance:
        return _iconCircle(
            Icons.local_hospital, const Color(0xFF059669), const Color(0xFFECFDF5));
      case ReportCategory.fire:
        return _iconCircle(Icons.local_fire_department, Colors.deepOrange,
            const Color(0xFFFFF3E0));
      case ReportCategory.police:
        return _iconCircle(Icons.local_police, const Color(0xFF1A56DB), const Color(0xFFE8F0FF));
      case ReportCategory.rescue:
        return _iconCircle(
            Icons.support_agent, AppColors.primary, AppColors.statusUrgentBg);
      case ReportCategory.naturalDisaster:
        return _iconCircle(Icons.thunderstorm, const Color(0xFF4F46E5), const Color(0xFFEEF2FF));
      case ReportCategory.buildingCollapse:
        return _iconCircle(Icons.apartment, const Color(0xFF78350F), const Color(0xFFFFF7ED));
      case ReportCategory.roadClosure:
        return _iconCircle(
            Icons.traffic, AppColors.textMedium, AppColors.statusClosedBg);
      case ReportCategory.other:
        return _iconCircle(
            Icons.more_horiz, AppColors.textLight, AppColors.statusClosedBg);
    }
  }

  Color get _severityColor {
    switch (report.severity) {
      case SeverityLevel.critical:
        return AppColors.severityCritical;
      case SeverityLevel.high:
        return AppColors.statusUrgent;
      case SeverityLevel.medium:
        return AppColors.severityMedium;
      case SeverityLevel.low:
        return AppColors.severityLow;
    }
  }

  Widget _iconCircle(IconData icon, Color color, Color bg) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      );

  Color get _leftBorderColor {
    switch (report.status) {
      case ReportStatus.received:
      case ReportStatus.underReview:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return AppColors.statusProcessing;
      case ReportStatus.closed:
        return AppColors.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                report.statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (report.isWitness) ...[
                                  const Icon(Icons.visibility_outlined,
                                      size: 13, color: AppColors.statusProcessing),
                                  const SizedBox(width: 2),
                                  Text(
                                    AppStrings.witness,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusProcessing,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (report.severity != SeverityLevel.medium) ...[
                                  Icon(
                                    report.severity == SeverityLevel.critical ||
                                            report.severity == SeverityLevel.high
                                        ? Icons.priority_high_rounded
                                        : Icons.remove_circle_outline,
                                    size: 13,
                                    color: _severityColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    report.severityLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _severityColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: AppColors.textLight),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    report.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _categoryIcon,
                          const SizedBox(height: 6),
                          Text(
                            report.displayTimeAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showProgress && report.progressValue != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: report.progressValue,
                        backgroundColor: AppColors.statusProcessingBg,
                        color: AppColors.statusProcessing,
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      child: Text(
                        AppStrings.relevantAuthorities,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.statusProcessing,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: _leftBorderColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
