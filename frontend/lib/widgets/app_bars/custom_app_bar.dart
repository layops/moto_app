import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onLeadingPressed;
  final Widget? trailing;
  final bool showLeadingIcon;
  final IconData? leadingIcon;
  final Color? backgroundColor;
  final double? elevation;
  final TextStyle? titleStyle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onLeadingPressed,
    this.trailing,
    this.showLeadingIcon = true,
    this.leadingIcon = Icons.menu,
    this.backgroundColor,
    this.elevation = 0.5,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? theme.colorScheme.background,
      elevation: elevation,
      centerTitle: true,
      title: Text(
        title,
        style: titleStyle ??
            theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
      ),
      leading: showLeadingIcon
          ? IconButton(
              icon: Icon(leadingIcon),
              onPressed:
                  onLeadingPressed ?? () => Scaffold.of(context).openDrawer(),
            )
          : null,
      actions: trailing != null ? [trailing!] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
