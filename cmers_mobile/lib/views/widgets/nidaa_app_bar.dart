import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';

class NidaaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final bool transparent;
  final VoidCallback? onBack;

  const NidaaAppBar({
    super.key,
    this.showBack = false,
    this.transparent = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : AppColors.white,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_forward_ios,
                  color: AppColors.textDark, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : const SizedBox.shrink(),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.star, color: AppColors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.appName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none,
              color: transparent ? AppColors.white : AppColors.textDark,
              size: 24),
          onPressed: () => Get.toNamed(AppRoutes.alertsList),
        ),
        if (!transparent)
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.textDark,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.person, color: AppColors.white, size: 18),
            ),
            onPressed: () {},
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}