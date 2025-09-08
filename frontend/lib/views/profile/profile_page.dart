import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'components/photo_uploader.dart';
import 'components/profile_drawer.dart';
import 'components/profile_header.dart';
import 'components/profile_tab_bar.dart';
import 'tabs/posts_tab.dart';
import 'tabs/media_tab.dart';
import 'tabs/followers_tab.dart';
import 'tabs/following_tab.dart';
import 'edit/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String? username;

  const ProfilePage({super.key, this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _avatarFile;
  File? _coverFile; // Yeni eklenen
  Map<String, dynamic>? _profileData;
  List<dynamic>? _posts;
  List<dynamic>? _media;
  List<dynamic>? _followers;
  List<dynamic>? _following;
  String? _currentUsername;
  bool _isLoading = true;
  String? _errorMessage;
  String? _postsError;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCurrentUser = false;
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
        setState(() => _currentUsername = currentUser);
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
        _loadProfileData(),
        _loadPosts(),
        _loadMedia(),
        _loadFollowers(),
        _loadFollowing(),
      ]);

      if (!mounted) return;

      setState(() {
        _profileData = results[0] as Map<String, dynamic>?;
        _posts = results[1] as List<dynamic>? ?? [];
        _media = results[2] as List<dynamic>? ?? [];
        _followers = results[3] as List<dynamic>? ?? [];
        _following = results[4] as List<dynamic>? ?? [];
        _isCurrentUser = isCurrentUser;
        _isLoading = false;
        _followerCount = _followers?.length ?? 0;
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

  Future<Map<String, dynamic>?> _loadProfileData() async {
    try {
      return await ServiceLocator.profile.getProfile(_currentUsername!);
    } catch (e) {
      debugPrint('Profil verisi yüklenirken hata: $e');
      return null;
    }
  }

  Future<List<dynamic>> _loadPosts() async {
    try {
      return await ServiceLocator.user.getPosts(_currentUsername!);
    } catch (e) {
      debugPrint('Gönderiler yüklenirken hata: $e');
      _postsError = 'Gönderiler yüklenirken hata oluştu';
      return [];
    }
  }

  Future<List<dynamic>> _loadMedia() async {
    try {
      return await ServiceLocator.user.getMedia(_currentUsername!);
    } catch (e) {
      debugPrint('Medya yüklenirken hata: $e');
      return [];
    }
  }

  Future<List<dynamic>> _loadFollowers() async {
    try {
      return await ServiceLocator.user.getFollowers(_currentUsername!);
    } catch (e) {
      debugPrint('Takipçiler yüklenirken hata: $e');
      return [];
    }
  }

  Future<List<dynamic>> _loadFollowing() async {
    try {
      return await ServiceLocator.user.getFollowing(_currentUsername!);
    } catch (e) {
      debugPrint('Takip edilenler yüklenirken hata: $e');
      return [];
    }
  }

  void _signOut(BuildContext context) async {
    try {
      await ServiceLocator.auth.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage(authService: ServiceLocator.auth)),
        (route) => false,
      );
    } catch (_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage(authService: ServiceLocator.auth)),
        (route) => false,
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading || _isCurrentUser || _currentUsername == null) return;

    setState(() => _isFollowLoading = true);

    try {
      final userProfile =
          await ServiceLocator.profile.getProfile(_currentUsername!);
      final userId = userProfile?['id'];
      if (userId == null) throw Exception('Kullanıcı ID bulunamadı');

      await ServiceLocator.follow.followToggleUser(_currentUsername!);

      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('İşlem başarısız: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  void _showAvatarUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Fotoğrafı Yükle'),
        content: ProfilePhotoUploader(
          type: PhotoType.profile, // <-- type eklendi
          networkImageUrl: _profileData?['profile_photo'],
          onImageSelected: (File image) => setState(() => _avatarFile = image),
          onUploadSuccess: (Map<String, dynamic> updatedUser) {
            setState(() {
              _profileData?['profile_photo'] = updatedUser['profile_photo'];
              _avatarFile = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profil fotoğrafı başarıyla güncellendi!')),
            );
          },
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

  // Yeni eklenen metod
  void _showCoverUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kapak Fotoğrafı Yükle'),
        content: ProfilePhotoUploader(
          type: PhotoType.cover, // <-- type eklendi
          networkImageUrl: _profileData?['cover_photo'],
          onImageSelected: (File image) => setState(() => _coverFile = image),
          onUploadSuccess: (Map<String, dynamic> updatedUser) {
            setState(() {
              _profileData?['cover_photo'] = updatedUser['cover_photo'];
              _coverFile = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Kapak fotoğrafı başarıyla güncellendi!')),
            );
          },
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
        builder: (_) => EditProfilePage(initialData: _profileData ?? {}),
      ),
    );

    if (updatedData != null) {
      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );
    }
  }

  Widget _buildLoading() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
          const SizedBox(height: 16),
          Text('Profil yükleniyor...', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _loadProfile, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildUserNotFound() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off,
              size: 64, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Kullanıcı bulunamadı', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Debug mesajı
    print('ProfilePage build() çağrıldı!');

    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return Scaffold(body: _buildError());
    if (_currentUsername == null) return Scaffold(body: _buildUserNotFound());

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
              profileData: _profileData ?? {},
            )
          : null,
      body: DefaultTabController(
        length: 6,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: ProfileHeader(
                avatarFile: _avatarFile,
                avatarUrl: _profileData?['profile_photo'],
                coverFile: _coverFile, // Yeni eklenen
                coverUrl: _profileData?['cover_photo'],
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
                onEditAvatar: _isCurrentUser
                    ? _showAvatarUploadDialog
                    : null, // Callback güncellendi
                onEditCover: _isCurrentUser
                    ? _showCoverUploadDialog
                    : null, // Yeni eklenen
                onFollow: _isCurrentUser ? null : _toggleFollow,
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
                username: _currentUsername!,
                avatarUrl: _profileData?['profile_photo'],
                displayName: _profileData?['display_name'],
                error: _postsError,
              ),
              Center(child: Text('Yanıtlar', style: theme.textTheme.bodyLarge)),
              MediaTab(media: _media ?? []),
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
