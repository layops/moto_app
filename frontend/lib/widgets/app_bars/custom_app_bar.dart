import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? actions;
  final bool showLeadingIcon;
  final IconData leadingIcon;
  final Color? backgroundColor;
  final double? elevation;
  final TextStyle? titleStyle;
  final Widget? bottomWidget; // Daha açıklayıcı isim

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
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ??
          theme.appBarTheme.backgroundColor ??
          theme.colorScheme.surface,
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
              onPressed: onLeadingPressed ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
            )
          : null,
      actions: actions,
      flexibleSpace: bottomWidget != null
          ? Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: bottomWidget,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottomWidget != null ? 20 : 0));
}
