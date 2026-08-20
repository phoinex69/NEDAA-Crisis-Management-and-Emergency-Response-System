import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/report_model.dart';

class ReportCategoryScreen extends StatelessWidget {
  const ReportCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportsController>();

    final categories = [
      _CategoryItem(
        label: AppStrings.catAmbulance,
        icon: Icons.local_hospital,
        color: AppColors.white,
        bgColor: const Color(0xFF059669),
        category: ReportCategory.ambulance,
      ),
      _CategoryItem(
        label: AppStrings.catFire,
        icon: Icons.local_fire_department,
        color: AppColors.white,
        bgColor: AppColors.primary,
        category: ReportCategory.fire,
      ),
      _CategoryItem(
        label: AppStrings.catPolice,
        icon: Icons.local_police,
        color: AppColors.white,
        bgColor: const Color(0xFF1A56DB),
        category: ReportCategory.police,
      ),
      _CategoryItem(
        label: AppStrings.catRescue,
        icon: Icons.support_agent,
        color: AppColors.white,
        bgColor: const Color(0xFF0D9488),
        category: ReportCategory.rescue,
      ),
      _CategoryItem(
        label: AppStrings.catNaturalDisaster,
        icon: Icons.thunderstorm,
        color: AppColors.white,
        bgColor: const Color(0xFF4F46E5),
        category: ReportCategory.naturalDisaster,
      ),
      _CategoryItem(
        label: AppStrings.catBuildingCollapse,
        icon: Icons.apartment,
        color: AppColors.white,
        bgColor: const Color(0xFF78350F),
        category: ReportCategory.buildingCollapse,
      ),
      _CategoryItem(
        label: AppStrings.catRoadClosure,
        icon: Icons.traffic,
        color: AppColors.white,
        bgColor: const Color(0xFF6B7280),
        category: ReportCategory.roadClosure,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.appName,
          style: const TextStyle(
            fontSize: 22,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.categoryTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.categorySubtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.2,
                ),
                itemCount: categories.length,
                itemBuilder: (_, i) => _CategoryCard(
                  item: categories[i],
                  onTap: () =>
                      controller.selectCategory(categories[i].category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final ReportCategory category;

  _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.category,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;
  final VoidCallback onTap;

  const _CategoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
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