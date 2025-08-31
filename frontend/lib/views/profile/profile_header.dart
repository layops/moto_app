import 'dart:io';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final File? imageFile;
  final String? networkImageUrl; // Backend URL desteği
  final String? coverImageUrl;
  final ColorScheme colorScheme;
  final int followerCount;
  final int followingCount;
  final String username;
  final String displayName;
  final String bio;
  final String joinDate;
  final String website;
  final bool isVerified;
  final bool isCurrentUser;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onFollow;
  final List<String> mutualFollowers;

  const ProfileHeader({
    super.key,
    this.imageFile,
    this.networkImageUrl,
    this.coverImageUrl,
    required this.colorScheme,
    required this.followerCount,
    required this.followingCount,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.joinDate = '',
    this.website = '',
    this.isVerified = false,
    this.isCurrentUser = false,
    this.onEditPhoto,
    this.onFollow,
    this.mutualFollowers = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Profil resmi için ImageProvider seçimi
    ImageProvider? avatarImage;
    if (imageFile != null) {
      avatarImage = FileImage(imageFile!);
    } else if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      avatarImage = NetworkImage(networkImageUrl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kapak fotoğrafı
        Container(
          height: 150,
          width: double.infinity,
          decoration: coverImageUrl != null && coverImageUrl!.isNotEmpty
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(coverImageUrl!),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                ),
        ),
        const SizedBox(height: 16),

        // Profil ve takip butonları
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: avatarImage,
                  backgroundColor: colorScheme.surface,
                  child: avatarImage == null
                      ? Icon(
                          Icons.account_circle,
                          size: 100,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        )
                      : null,
                ),
                if (onEditPhoto != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!isCurrentUser)
              ElevatedButton(
                onPressed: onFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Takip Et'),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Kullanıcı bilgileri
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                if (isVerified)
                  Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bio,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
            if (website.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.link,
                      size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    website,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
            if (joinDate.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    joinDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat('Takip edilen', followingCount),
                const SizedBox(width: 16),
                _buildStat('Takipçi', followerCount),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
