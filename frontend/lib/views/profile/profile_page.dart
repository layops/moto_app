import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/profile/photo_uploader.dart';
import 'edit_profile_page.dart';
import 'profile_drawer.dart';
import 'profile_header.dart';
import 'profile_tab_bar.dart';
import 'profile_tabs/posts_tab.dart';
import 'profile_tabs/media_tab.dart';
import 'profile_tabs/followers_tab.dart';
import 'profile_tabs/following_tab.dart';

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
  bool _isCurrentUser = false;

  // Takip işlemleri için ek alanlar
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  int _followerCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_currentUsername == null) {
      try {
        final currentUser = await ServiceLocator.user.getCurrentUsername();
        if (!mounted) return;
        setState(() {
          _currentUsername = currentUser;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Kullanıcı bilgisi alınamadı: $e';
          });
        }
        return;
      }
    }

    if (_currentUsername == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kullanıcı bulunamadı';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _postsError = null;
    });

    try {
      final currentUsername = await ServiceLocator.user.getCurrentUsername();
      final isCurrentUser = _currentUsername == currentUsername;

      final results = await Future.wait([
        ServiceLocator.profile
            .getProfile(_currentUsername!)
            .catchError((_) => null),
        ServiceLocator.user.getPosts(_currentUsername!).catchError((e) {
          debugPrint('Gönderiler getirme hatası: $e');
          _postsError = 'Gönderiler yüklenirken hata oluştu';
          return <dynamic>[];
        }),
        ServiceLocator.user.getMedia(_currentUsername!).catchError((e) {
          debugPrint('Medya getirme hatası: $e');
          return <dynamic>[];
        }),
        ServiceLocator.user.getEvents(_currentUsername!).catchError((e) {
          debugPrint('Etkinlikler getirme hatası: $e');
          return <dynamic>[];
        }),
        ServiceLocator.user.getFollowers(_currentUsername!).catchError((e) {
          debugPrint('Takipçiler getirme hatası: $e');
          return <dynamic>[];
        }),
        ServiceLocator.user.getFollowing(_currentUsername!).catchError((e) {
          debugPrint('Takip edilenler getirme hatası: $e');
          return <dynamic>[];
        }),
      ]);

      if (!mounted) return;

      final profileData = results[0] as Map<String, dynamic>?;

      setState(() {
        _profileData = profileData;
        _posts = results[1] as List<dynamic>? ?? [];
        _media = results[2] as List<dynamic>? ?? [];
        _events = results[3] as List<dynamic>? ?? [];
        _followers = results[4] as List<dynamic>? ?? [];
        _following = results[5] as List<dynamic>? ?? [];
        _isCurrentUser = isCurrentUser;
        _isLoading = false;

        _followerCount = _followers?.length ?? 0;

        // Başlangıçta takip durumu belirleme (backend’den çek)
        _isFollowing =
            _followers?.any((f) => f['username'] == currentUsername) == true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Profil yüklenirken hata: $e';
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    try {
      await ServiceLocator.auth.logout();
      ServiceLocator.navigator.pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => LoginPage(authService: ServiceLocator.auth)),
        (route) => false,
      );
    } catch (_) {
      ServiceLocator.navigator.pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => LoginPage(authService: ServiceLocator.auth)),
        (route) => false,
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading || _isCurrentUser || _currentUsername == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final userProfile =
          await ServiceLocator.profile.getProfile(_currentUsername!);
      final userId = userProfile?['id'];
      if (userId == null) throw Exception('Kullanıcı ID bulunamadı');

      if (_isFollowing) {
        await ServiceLocator.follow.unfollowUser(userId as int);
        setState(() {
          _isFollowing = false;
          if (_followerCount > 0) _followerCount -= 1;
        });
      } else {
        await ServiceLocator.follow.followUser(userId as int);
        setState(() {
          _isFollowing = true;
          _followerCount += 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  void _showPhotoUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Fotoğrafı Yükle'),
        content: ProfilePhotoUploader(
          networkImageUrl: _profileData?['profile_photo'],
          onImageSelected: (File image) {
            setState(() {
              _imageFile = image;
            });
          },
          onUploadSuccess: (Map<String, dynamic> updatedUser) {
            setState(() {
              _profileData?['profile_photo'] = updatedUser['profile_photo'];
              _imageFile = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profil fotoğrafı başarıyla güncellendi!')),
            );
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

  void _openEditProfile() async {
    final isLoggedIn = await ServiceLocator.auth.isLoggedIn();
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage(authService: ServiceLocator.auth)),
        (route) => false,
      );
      return;
    }

    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialData: _profileData ?? {},
        ),
      ),
    );

    if (updatedData != null) {
      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla güncellendi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          if (_isCurrentUser)
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _openEditProfile,
                tooltip: 'Profili Düzenle'),
        ],
      ),
      drawer: _isCurrentUser
          ? ProfileDrawer(
              onSignOut: () => _signOut(context),
              colorScheme: colorScheme,
              theme: theme,
              profileData: _profileData ?? {},
            )
          : null,
      body: DefaultTabController(
        length: 6,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: ProfileHeader(
                imageFile: _imageFile,
                networkImageUrl: _profileData?['profile_photo'],
                coverImageUrl: _profileData?['cover_photo'],
                colorScheme: colorScheme,
                followerCount: _followerCount,
                followingCount: _following?.length ?? 0,
                username: _currentUsername!,
                displayName: _profileData?['display_name'] ?? _currentUsername!,
                bio: _profileData?['bio'] ?? '',
                joinDate: _profileData?['date_joined'] != null
                    ? '${DateTime.parse(_profileData!['date_joined']).year} yılında katıldı'
                    : '',
                website: _profileData?['website'] ?? '',
                isVerified: _profileData?['is_verified'] ?? false,
                isCurrentUser: _isCurrentUser,
                isFollowing: _isFollowing,
                isFollowLoading: _isFollowLoading,
                onEditPhoto: _isCurrentUser ? _showPhotoUploadDialog : null,
                onFollow: _isCurrentUser ? null : _toggleFollow,
                mutualFollowers: [],
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
                  avatarUrl: _profileData?['profile_photo'],
                  displayName: _profileData?['display_name'],
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
    );
  }
}
