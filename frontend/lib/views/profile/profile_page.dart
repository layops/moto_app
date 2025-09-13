import 'dart:io';
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/services/chat/chat_service.dart';
import 'package:motoapp_frontend/views/messages/chat_detail_page.dart';
import 'components/photo_uploader.dart';
import 'components/profile_drawer.dart';
import 'components/profile_header.dart';
import 'components/profile_tab_bar.dart';
import 'tabs/posts_tab.dart';
import 'tabs/media_tab.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/info_tab.dart';
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
  List<dynamic>? _achievements;
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

      // Önce profil verilerini yükle
      final profileData = await _loadProfileData();
      
      if (!mounted) return;
      
      setState(() {
        _profileData = profileData;
        _isCurrentUser = isCurrentUser;
        _followerCount = profileData?['followers_count'] ?? 0;
        _isFollowing = profileData?['is_following'] ?? false;
        _isLoading = false;
      });

      // Sonra diğer verileri paralel olarak yükle
      final results = await Future.wait([
        _loadPosts(),
        _loadMedia(),
        _loadAchievements(),
      ]);

      if (!mounted) return;

      setState(() {
        _posts = results[0] as List<dynamic>? ?? [];
        _media = results[1] as List<dynamic>? ?? [];
        _achievements = results[2] as List<dynamic>? ?? [];
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

  Future<List<dynamic>> _loadAchievements() async {
    try {
      final achievements = await ServiceLocator.gamification.getUserAchievements();
      debugPrint('DEBUG: Loaded achievements: $achievements');
      return achievements;
    } catch (e) {
      debugPrint('Başarımlar yüklenirken hata: $e');
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
      print('🔄 ProfilePage - Takip işlemi başlatılıyor: $_currentUsername');
      
      // Kullanıcı profilini al (cache'den olabilir)
      final userProfile =
          await ServiceLocator.profile.getProfile(_currentUsername!);
      final userId = userProfile?['id'];
      if (userId == null) throw Exception('Kullanıcı ID bulunamadı');

      print('🔄 ProfilePage - Takip toggle çağrılıyor...');
      
      // Takip işlemini gerçekleştir
      final isNowFollowing = await ServiceLocator.follow.followToggleUser(_currentUsername!);
      
      print('✅ ProfilePage - Takip işlemi tamamlandı: $isNowFollowing');

      if (mounted) {
        setState(() {
          _isFollowing = isNowFollowing;
          _followerCount += _isFollowing ? 1 : -1;
        });
        
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Takip edildi!' : 'Takipten çıkıldı!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ ProfilePage - Takip hatası: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () {
                // Tekrar deneme
                _toggleFollow();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  void _openMessageDialog() {
    if (_currentUsername == null || _profileData == null) return;
    
    // User objesi oluştur
    final user = User(
      id: _profileData!['id'],
      username: _currentUsername!,
      firstName: _profileData!['first_name'],
      lastName: _profileData!['last_name'],
      profilePicture: _profileData!['profile_picture'],
    );
    
    // Chat detail sayfasına git
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(otherUser: user),
      ),
    );
  }

  void _showAvatarUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Fotoğrafı Yükle'),
        content: ProfilePhotoUploader(
          type: PhotoType.profile, // <-- type eklendi
          networkImageUrl: _profileData?['profile_photo_url'] ?? _profileData?['profile_picture'],
          onImageSelected: (File image) => setState(() => _avatarFile = image),
          onUploadSuccess: (Map<String, dynamic> updatedUser) async {
            // Cache'leri temizle
            await _clearProfileCache();
            
            setState(() {
              _profileData?['profile_photo_url'] = updatedUser['profile_photo_url'] ?? updatedUser['profile_picture'];
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
          networkImageUrl: _profileData?['cover_photo_url'] ?? _profileData?['cover_picture'],
          onImageSelected: (File image) => setState(() => _coverFile = image),
          onUploadSuccess: (Map<String, dynamic> updatedUser) {
            setState(() {
              _profileData?['cover_photo_url'] = updatedUser['cover_photo_url'] ?? updatedUser['cover_picture'];
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
      // Cache'leri temizle ve profil verilerini yeniden yükle
      await _clearProfileCache();
      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );
    }
  }

  /// Profil cache'ini temizle
  Future<void> _clearProfileCache() async {
    try {
      if (_currentUsername != null) {
        // UserService cache'ini temizle
        ServiceLocator.user.clearUserCache(_currentUsername!);
        
        // API Client cache'ini temizle
        ServiceLocator.api.clearCacheForPath('users/$_currentUsername/profile/');
        
        // LocalStorage'daki profil verilerini temizle
        await ServiceLocator.storage.clearProfileData();
        
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
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
    

    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return Scaffold(body: _buildError());
    if (_currentUsername == null) return Scaffold(body: _buildUserNotFound());

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _currentUsername!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.95),
                colorScheme.surface.withOpacity(0.8),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadProfile,
              tooltip: 'Yenile',
            ),
          ),
          if (_isCurrentUser)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: _openEditProfile,
                tooltip: 'Profili Düzenle',
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
      drawer: _isCurrentUser
          ? ProfileDrawer(
              onSignOut: () => _signOut(context),
              profileData: _profileData ?? {},
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: DefaultTabController(
          length: 5,
          child: CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 100), // AppBar için boşluk
                  child: ProfileHeader(
                    avatarFile: _avatarFile,
                    avatarUrl: _profileData?['profile_photo_url'] ?? _profileData?['profile_picture'],
                    coverFile: _coverFile,
                    coverUrl: _profileData?['cover_photo_url'] ?? _profileData?['cover_picture'],
                    followerCount: _followerCount,
                    followingCount: _profileData?['following_count'] ?? 0,
                    username: _currentUsername!,
                    displayName: _profileData?['display_name'] ?? _currentUsername!,
                    bio: _profileData?['bio'] ?? '',
                    joinDate: _profileData?['join_date'] != null
                        ? '${_profileData!['join_date']} tarihinde katıldı'
                        : '',
                    website: _profileData?['website'] ?? '',
                    isVerified: _profileData?['is_verified'] ?? false,
                    isCurrentUser: _isCurrentUser,
                    isFollowing: _isFollowing,
                    isFollowLoading: _isFollowLoading,
                    onEditAvatar: _isCurrentUser
                        ? _showAvatarUploadDialog
                        : null,
                    onEditCover: _isCurrentUser
                        ? _showCoverUploadDialog
                        : null,
                    onFollow: _isCurrentUser ? null : _toggleFollow,
                    onMessage: _isCurrentUser ? null : _openMessageDialog,
                  ),
                ),
              ),
              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Gönderiler'),
                      Tab(text: 'Yanıtlar'),
                      Tab(text: 'Medya'),
                      Tab(text: 'Başarımlar'),
                      Tab(text: 'Bilgi'),
                    ],
                  ),
                ),
              ),
              // Tab Content
              SliverFillRemaining(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: TabBarView(
                    children: [
                      PostsTab(
                        posts: _posts ?? [],
                        username: _currentUsername!,
                        avatarUrl: _profileData?['profile_photo'],
                        displayName: _profileData?['display_name'],
                        error: _postsError,
                      ),
                      Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.reply_outlined,
                                size: 48,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Yanıtlar',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Henüz yanıt yok',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      MediaTab(media: _media ?? []),
                      AchievementsTab(achievements: _achievements),
                      InfoTab(profileData: _profileData),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
