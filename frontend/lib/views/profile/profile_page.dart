import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'edit_profile_page.dart';
import 'profile_drawer.dart';
import 'profile_header.dart';
import 'profile_tab_bar.dart';
import 'profile_tabs/posts_tab.dart';
import 'profile_tabs/media_tab.dart';
import 'profile_tabs/events_tab.dart';
import 'profile_tabs/info_tab.dart';
import 'profile_tabs/followers_tab.dart';
import 'profile_tabs/following_tab.dart';
import 'photo_uploader.dart';

class ProfilePage extends StatefulWidget {
  final String? username;

  const ProfilePage({super.key, this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  Map<String, dynamic>? _profileData;
  List<dynamic>? _posts;
  List<dynamic>? _media;
  List<dynamic>? _events;
  List<dynamic>? _followers;
  List<dynamic>? _following;
  String? _currentUsername;
  bool _isLoading = true;
  String? _errorMessage;
  String? _postsError;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final username = await ServiceLocator.user.getCurrentUsername();
      if (!mounted) return;

      setState(() {
        _currentUsername = username ?? widget.username;
      });

      if (_currentUsername != null) {
        await _loadProfile();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kullanıcı bilgisi bulunamadı';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kullanıcı bilgisi alınamadı: $e';
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    if (_currentUsername == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _postsError = null;
    });

    try {
      final results = await Future.wait([
        ServiceLocator.user.getProfile(_currentUsername!).catchError((e) {
          print('Profil bilgisi getirme hatası: $e');
          return {};
        }),
        ServiceLocator.user.getPosts(_currentUsername!).catchError((e) {
          print('Gönderiler getirme hatası: $e');
          _postsError = 'Gönderiler yüklenirken hata oluştu';
          return [];
        }),
        ServiceLocator.user.getMedia(_currentUsername!).catchError((e) {
          print('Medya getirme hatası: $e');
          return [];
        }),
        ServiceLocator.user.getEvents(_currentUsername!).catchError((e) {
          print('Etkinlikler getirme hatası: $e');
          return [];
        }),
        ServiceLocator.user.getFollowers(_currentUsername!).catchError((e) {
          print('Takipçiler getirme hatası: $e');
          return [];
        }),
        ServiceLocator.user.getFollowing(_currentUsername!).catchError((e) {
          print('Takip edilenler getirme hatası: $e');
          return [];
        }),
        // Removed the getMutualFollowers call as it doesn't exist
      ]);

      if (!mounted) return;

      setState(() {
        _profileData = results[0] as Map<String, dynamic>?;
        _posts = results[1] as List<dynamic>?;
        _media = results[2] as List<dynamic>?;
        _events = results[3] as List<dynamic>?;
        _followers = results[4] as List<dynamic>?;
        _following = results[5] as List<dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Profil yüklenirken genel hata oluştu: $e';
        });
      }
    }
  }

  void _signOut(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showPhotoUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Fotoğrafı Yükle'),
        content: ProfilePhotoUploader(
          onImageSelected: (File image) {
            setState(() {
              _imageFile = image;
            });
          },
          onUploadStateChanged: (bool isUploading) {},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialData: _profileData ?? {},
        ),
      ),
    ).then((updatedData) {
      if (updatedData != null) {
        setState(() {
          _profileData = {..._profileData ?? {}, ...updatedData};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text('Profil yükleniyor...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _loadProfile, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    if (_currentUsername == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off,
                  size: 64, color: colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Kullanıcı bulunamadı', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    // Mock data for mutual followers
    final List<String> mutualFollowers = ['berriko takip ediyor'];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUsername!),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProfile,
              tooltip: 'Yenile'),
          IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _openEditProfile,
              tooltip: 'Profili Düzenle'),
        ],
      ),
      drawer: ProfileDrawer(
        onSignOut: () => _signOut(context),
        colorScheme: colorScheme,
        theme: theme,
        profileData: _profileData ?? {},
      ),
      body: DefaultTabController(
        length: 6,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: ProfileHeader(
                imageFile: _imageFile,
                coverImageUrl: _profileData?['coverImageUrl'],
                colorScheme: colorScheme,
                followerCount: _followers?.length ?? 0,
                followingCount: _following?.length ?? 0,
                username: _currentUsername!,
                displayName: _profileData?['displayName'] ?? _currentUsername!,
                bio: _profileData?['bio'] ??
                    'Dijital Medya ve Haber | Gündemi bir tıkla takip etmek için bildirimleri açın.',
                joinDate: _profileData?['joinDate'] ??
                    'Aralık 2020 tarihinde katıldı',
                website:
                    _profileData?['website'] ?? 'instagram.com/bosunatiklamatr',
                isVerified: _profileData?['isVerified'] ?? false,
                isCurrentUser: _currentUsername == widget.username,
                onEditPhoto: _showPhotoUploadDialog,
                onFollow: () {
                  // Implement follow functionality
                },
                mutualFollowers: mutualFollowers,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: ProfileTabBarDelegate(
                TabBar(
                  isScrollable: true,
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
                  tabs: const [
                    Tab(text: 'Gönderiler'),
                    Tab(text: 'Yanıtlar'),
                    Tab(text: 'Medya'),
                    Tab(text: 'Beğeniler'),
                    Tab(text: 'Takipçiler'),
                    Tab(text: 'Takip Edilenler'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              PostsTab(
                  posts: _posts ?? [],
                  theme: theme,
                  username: _currentUsername!,
                  avatarUrl: _profileData?['avatar']?.toString(),
                  error: _postsError),
              Center(child: Text('Yanıtlar', style: theme.textTheme.bodyLarge)),
              MediaTab(media: _media ?? [], theme: theme),
              Center(
                  child: Text('Beğeniler', style: theme.textTheme.bodyLarge)),
              FollowersTab(followers: _followers ?? []),
              FollowingTab(following: _following ?? []),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: UniqueKey(),
        onPressed: _showPhotoUploadDialog,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
