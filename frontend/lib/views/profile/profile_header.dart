import 'dart:io';
import 'package:flutter/material.dart';
import 'photo_uploader.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final Map<String, dynamic>? profileData;
  final File? imageFile;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onEditPhoto;

  const ProfileHeader({
    super.key,
    required this.username,
    required this.profileData,
    required this.imageFile,
    required this.colorScheme,
    required this.theme,
    this.onEditPhoto,
  });

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                // Kamera açma işlevi
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                if (onEditPhoto != null) onEditPhoto!();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          color: colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.photo_camera,
              color: colorScheme.onSurface.withOpacity(0.5), size: 40),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -50),
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: colorScheme.surface,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              imageFile != null ? FileImage(imageFile!) : null,
                          child: imageFile == null
                              ? Icon(
                                  Icons.account_circle,
                                  size: 84,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                username,
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                profileData?['email'] ?? 'Email girilmemiş',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (profileData?['socialMedia'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  profileData!['socialMedia'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
