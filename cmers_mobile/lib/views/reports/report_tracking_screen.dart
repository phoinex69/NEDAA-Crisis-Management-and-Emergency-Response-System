import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';

import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/report_model.dart';
import '../../services/map_offline_service.dart';

class ReportTrackingScreen extends StatefulWidget {
  const ReportTrackingScreen({super.key});

  @override
  State<ReportTrackingScreen> createState() => _ReportTrackingScreenState();
}

class _ReportTrackingScreenState extends State<ReportTrackingScreen> {
  @override
  void initState() {
    super.initState();
    final base = Get.find<ReportsController>().selectedReport.value;
    if (base != null) {
      Get.find<ReportsController>().startReportLiveTracking(base.id);
    }
  }

  @override
  void dispose() {
    Get.find<ReportsController>().stopReportLiveTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.trackingTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final base = controller.selectedReport.value;
        if (base == null) {
          return Center(
            child: Text(
              AppStrings.noReports,
              style: const TextStyle(color: AppColors.textLight),
            ),
          );
        }        final report = controller.allReports.firstWhere(
          (r) => r.id == base.id,
          orElse: () => base,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHeader(report: report),
              const SizedBox(height: 14),
              _ResponseCard(report: report),
              if (report.status != ReportStatus.closed) ...[
                const SizedBox(height: 14),
                _LiveProgressCard(report: report),
              ],
              const SizedBox(height: 14),
              _LiveMapCard(report: report),
              if (report.description != null &&
                  report.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _DescriptionCard(description: report.description!),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final ReportModel report;

  const _StatusHeader({required this.report});

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

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _statusColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.displayTimeAgo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة الجهة المستجيبة ووقت الوصول المتوقع وعدد المتضررين ومصداقية البلاغ.
class _ResponseCard extends StatelessWidget {
  final ReportModel report;

  const _ResponseCard({required this.report});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.support_agent,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.respondingAgency?.isNotEmpty == true
                      ? report.respondingAgency!
                      : AppStrings.noAgencyYet,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (report.etaMinutes != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.etaInMinutes
                            .replaceAll('{m}', '${report.etaMinutes}'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.people_outline,
                  label: report.victimsCount != null
                      ? AppStrings.peopleCount
                          .replaceAll('{n}', '${report.victimsCount}')
                      : AppStrings.victimsUnknown,
                ),
              ),
              if (report.credibilityScore != null) ...[
                Container(width: 1, height: 34, color: AppColors.cardBorder),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoTile(
                    icon: Icons.verified_outlined,
                    label: AppStrings.credibility.replaceAll(
                        '{n}', '${(report.credibilityScore! * 100).round()}'),
                  ),
                ),
              ],
              if (report.isWitness) ...[
                Container(width: 1, height: 34, color: AppColors.cardBorder),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoTile(
                    icon: Icons.visibility_outlined,
                    label: AppStrings.witness,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMedium),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMedium),
          ),
        ),
      ],
    );
  }
}

class _LiveProgressCard extends StatelessWidget {
  final ReportModel report;

  const _LiveProgressCard({required this.report});

  String get _stage {
    final progress = report.progressValue ?? 0.0;
    if (progress >= 1.0) return AppStrings.stageClosed;
    if (progress < 0.5) return AppStrings.stageAssessing;
    return AppStrings.relevantAuthorities;
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.sync,
                  size: 18, color: AppColors.statusProcessing),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _stage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusProcessing,
                  ),
                ),
              ),
              Text(
                '${((report.progressValue ?? 0.0) * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.progressValue,
              backgroundColor: AppColors.statusProcessingBg,
              color: AppColors.statusProcessing,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bolt,
                  size: 14, color: AppColors.severityMedium),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.autoUpdateNote,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveMapCard extends StatelessWidget {
  final ReportModel report;

  const _LiveMapCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final position = report.position;
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
          Text(
            AppStrings.liveMap,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: position != null
                ? SizedBox(
                    height: 200,
                    child: fm.FlutterMap(
                      options: fm.MapOptions(
                        initialCenter: position,
                        initialZoom: 14,
                        interactionOptions: const fm.InteractionOptions(
                          flags: fm.InteractiveFlag.drag &
                              fm.InteractiveFlag.pinchZoom &
                              fm.InteractiveFlag.doubleTapZoom,
                        ),
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: MapOfflineService.tileUrl,
                          subdomains: MapOfflineService.subdomains,
                          userAgentPackageName: 'com.nidaa.app',
                          tileProvider: MapOfflineService.tileProvider(),
                        ),
                        fm.MarkerLayer(
                          markers: [
                            fm.Marker(
                              point: position,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    height: 120,
                    color: AppColors.background,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppStrings.locationNotAvailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
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
          Text(
            AppStrings.reportDetails,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}