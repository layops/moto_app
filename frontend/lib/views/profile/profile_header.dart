import 'dart:io';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final Map<String, dynamic>? profileData;
  final File? imageFile;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const ProfileHeader({
    super.key,
    required this.username,
    required this.profileData,
    required this.imageFile,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          // ignore: deprecated_member_use
          color: colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.photo_camera,
              // ignore: deprecated_member_use
              color: colorScheme.onSurface.withOpacity(0.5),
              size: 40),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -50),
                child: CircleAvatar(
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
                            // ignore: deprecated_member_use
                            color: colorScheme.onSurface.withOpacity(0.5),
                          )
                        : null,
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
                  // ignore: deprecated_member_use
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
