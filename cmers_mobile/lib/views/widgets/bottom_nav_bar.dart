import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/nav_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    return Obx(() => BottomNavigationBar(
          currentIndex: nav.currentIndex.value,
          onTap: nav.changeTab,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: AppStrings.navMap,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.description_outlined),
              activeIcon: const Icon(Icons.description),
              label: AppStrings.navReports,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppStrings.navProfile,
            ),
          ],
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ));
  }
}
