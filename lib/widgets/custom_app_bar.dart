import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.primary, // 👈 dynamic
      centerTitle: centerTitle,

      /// 🔹 Leading
      leading: showBack
          ? IconButton(
        icon: Icon(Icons.arrow_back,
            color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      )
          : leading,

      /// 🔹 Title
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      /// 🔹 Actions
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}