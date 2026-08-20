import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nav_controller.dart';
import '../core/constants/app_routes.dart';
import 'home/home_screen.dart';
import 'reports/reports_list_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import '../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    MapScreen(),
    ReportsListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    return Scaffold(
      body: Obx(() => _screens[nav.currentIndex.value]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: const MainBottomNavBar(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.reportCategory),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
