import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? actions;
  final bool showLeadingIcon;
  final IconData? leadingIcon;
  final Color? backgroundColor;
  final double? elevation;
  final TextStyle? titleStyle;
  final Widget? floatingActionButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onLeadingPressed,
    this.actions,
    this.showLeadingIcon = true,
    this.leadingIcon = Icons.arrow_back,
    this.backgroundColor,
    this.elevation = 0,
    this.titleStyle,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: elevation,
      centerTitle: true,
      title: Text(
        title,
        style: titleStyle ??
            theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      leading: showLeadingIcon
          ? IconButton(
              icon: Icon(leadingIcon),
              onPressed: onLeadingPressed ?? () => Navigator.maybePop(context),
            )
          : null,
      actions: actions,
      flexibleSpace: floatingActionButton != null
          ? Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: floatingActionButton,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);
}
