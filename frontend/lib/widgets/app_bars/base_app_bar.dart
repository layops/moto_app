import 'package:flutter/material.dart';

enum LeadingButtonType {
  none,
  back,
  menu,
}

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final LeadingButtonType leadingButtonType;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const BaseAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leadingButtonType = LeadingButtonType.back,
    this.onBack,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return AppBar(
      backgroundColor: const Color(0xFFd32f2f), // Kırmızı tema rengi
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      leading: _buildLeading(context),
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    switch (leadingButtonType) {
      case LeadingButtonType.back:
        return IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        );
      case LeadingButtonType.menu:
        return Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenu ?? () => Scaffold.of(context).openDrawer(),
          ),
        );
      case LeadingButtonType.none:
        return null;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
