import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/nidaa_app_bar.dart';
import '../widgets/report_card.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  late final ReportsController _controller = Get.find<ReportsController>();

  @override
  void initState() {
    super.initState();
    _controller.startRealtimeUpdates();
  }

  @override
  void dispose() {
    _controller.stopRealtimeUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const NidaaAppBar(),
      body: Column(
        children: [
          _FilterTabs(controller: _controller),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.refreshReports,
              child: Obx(() {
                final reports = _controller.filteredReports;
                if (reports.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.description_outlined,
                          size: 64, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          AppStrings.noReportsList,
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
                  itemCount: reports.length,
                  itemBuilder: (_, i) => ReportCard(
                    report: reports[i],
                    showProgress: reports[i].progressValue != null,
                    onTap: () => _controller.openReportDetails(reports[i]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final ReportsController controller;
  const _FilterTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = [
      AppStrings.allReports,
      AppStrings.processing,
      AppStrings.closed,
    ];

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                filters.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => controller.setFilter(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: controller.selectedFilterIndex.value == i
                            ? AppColors.primary
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: controller.selectedFilterIndex.value == i
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        filters[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: controller.selectedFilterIndex.value == i
                              ? AppColors.white
                              : AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )),
    );
  }
}