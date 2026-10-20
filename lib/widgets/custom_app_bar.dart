import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = false,
    this.leading,
    this.actions,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.appBarBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.appBarText,
      centerTitle: centerTitle,
      shape: const Border(
        bottom: BorderSide(color: AppColors.appBarBorder),
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.appBarIcon),
              onPressed: () => Navigator.pop(context),
            )
          : leading,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.appBarText,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
