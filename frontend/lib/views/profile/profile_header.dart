import 'dart:io';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final File? imageFile;
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
    required this.imageFile,
    this.coverImageUrl,
    required this.colorScheme,
    required this.followerCount,
    required this.followingCount,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.joinDate,
    required this.website,
    this.isVerified = false,
    this.isCurrentUser = false,
    this.onEditPhoto,
    this.onFollow,
    this.mutualFollowers = const [], // Changed to const
  });

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kapak fotoğrafı
        Container(
          height: 200,
          width: double.infinity,
          decoration: coverImageUrl != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(coverImageUrl!),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
          child: coverImageUrl == null
              ? Center(
                  child: Icon(
                    Icons.photo_camera,
                    color: colorScheme.onSurface.withOpacity(0.3),
                    size: 40,
                  ),
                )
              : null,
        ),

        // Profil içeriği
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil fotoğrafı ve takip butonu
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profil fotoğrafı
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: colorScheme.surface,
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.transparent,
                            backgroundImage: imageFile != null
                                ? FileImage(imageFile!)
                                : null,
                            child: imageFile == null
                                ? Icon(
                                    Icons.account_circle,
                                    size: 104,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5),
                                  )
                                : null,
                          ),
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
                  ),

                  // Takip butonu
                  if (!isCurrentUser)
                    ElevatedButton(
                      onPressed: onFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Takip Et'),
                    ),
                ],
              ),

              // Kullanıcı bilgileri
              Transform.translate(
                offset: const Offset(0, -30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İsim ve kullanıcı adı
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

                    // Bio
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    // Website
                    if (website.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 18,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            website,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Katılma tarihi
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
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

                    // Takipçi ve takip edilen sayıları
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _formatNumber(followingCount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: ' Takip edilen',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _formatNumber(followerCount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: ' Takipçi',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Ortak takipçiler
                    if (mutualFollowers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: mutualFollowers.take(3).join(', '),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: mutualFollowers.length > 3
                                  ? ' ve ${mutualFollowers.length - 3} kişi daha takip ediyor'
                                  : ' takip ediyor',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
