import 'package:flutter/material.dart';
import '../../settings/settings_page.dart';
import '../edit/edit_profile_page.dart';
import 'photo_uploader.dart';

class ProfileDrawer extends StatelessWidget {
  final VoidCallback onSignOut;
  final Map<String, dynamic> profileData;

  const ProfileDrawer({
    super.key,
    required this.onSignOut,
    required this.profileData,
  });

  void _showPhotoUploadDialog(BuildContext context, {required PhotoType type}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == PhotoType.profile
            ? 'Profil Fotoğrafı Yükle'
            : 'Kapak Fotoğrafı Yükle'),
        content: ProfilePhotoUploader(
          type: type,
          networkImageUrl: type == PhotoType.profile
              ? profileData['profile_picture'] ?? ''
              : profileData['cover_picture'] ?? '',
          onUploadSuccess: (userData) {
            // Upload sonrası profileData güncellemesi yapılabilir
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Profil Menüsü',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profileData['email'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.photo_camera, color: colorScheme.onSurface),
            title: Text('Profil Fotoğrafı Yükle',
                style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              _showPhotoUploadDialog(context, type: PhotoType.profile);
            },
          ),
          ListTile(
            leading: Icon(Icons.image, color: colorScheme.onSurface),
            title:
                Text('Kapak Fotoğrafı Yükle', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              _showPhotoUploadDialog(context, type: PhotoType.cover);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: colorScheme.onSurface),
            title: Text('Profil Düzenle', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(initialData: profileData),
                ),
              );
            },
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
            leading: Icon(Icons.help, color: colorScheme.onSurface),
            title: Text('Yardım', style: theme.textTheme.bodyLarge),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info, color: colorScheme.onSurface),
            title: Text('Hakkında', style: theme.textTheme.bodyLarge),
            onTap: () {},
          ),
          Divider(color: colorScheme.onSurface.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('Çıkış Yap',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              onSignOut();
            },
          ),
        ],
      ),
    );
  }
}
