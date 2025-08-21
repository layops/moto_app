import 'package:flutter/material.dart';
import '../settings/settings_page.dart';

class ProfileDrawer extends StatelessWidget {
  final VoidCallback onSignOut;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const ProfileDrawer({
    super.key,
    required this.onSignOut,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Text(
              'Profil Menüsü',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.edit, color: colorScheme.onSurface),
            title: Text('Profil Düzenle', style: theme.textTheme.bodyLarge),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: colorScheme.onSurface),
            title: Text('Ayarlar', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          Divider(color: colorScheme.onSurface.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.onSurface),
            title: Text('Çıkış Yap', style: theme.textTheme.bodyLarge),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}
