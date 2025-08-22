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
  String? _currentUsername;
  bool _isLoading = true;
  String? _errorMessage;

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

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Her bir isteği bağımsız olarak çalıştır
      // Böylece birinde hata olsa bile diğerleri çalışır
      final profileFuture = ServiceLocator.user.getProfile(_currentUsername!);
      final postsFuture = ServiceLocator.user.getPosts(_currentUsername!);
      final mediaFuture = ServiceLocator.user.getMedia(_currentUsername!);
      final eventsFuture = ServiceLocator.user.getEvents(_currentUsername!);

      // Tüm istekleri await ile bekle
      _profileData = await profileFuture;
      _posts = await postsFuture;
      _media = await mediaFuture;
      _events = await eventsFuture;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Profil yüklenirken hata oluştu: $e';
        });
      }
    }
  }

  void _signOut(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfile,
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentUsername == null) {
      return Scaffold(
        body: Center(
          child: Text('Kullanıcı bulunamadı'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUsername!),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      drawer: ProfileDrawer(
        onSignOut: () => _signOut(context),
        colorScheme: colorScheme,
        theme: theme,
        profileData: _profileData ?? {},
      ),
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  username: _currentUsername!,
                  profileData: _profileData,
                  imageFile: _imageFile,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: ProfileTabBarDelegate(
                  TabBar(
                    indicatorColor: colorScheme.primary,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor:
                        colorScheme.onSurface.withOpacity(0.5),
                    tabs: const [
                      Tab(text: 'Gönderiler'),
                      Tab(text: 'Medya'),
                      Tab(text: 'Etkinlikler'),
                      Tab(text: 'Bilgi'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              PostsTab(posts: _posts, theme: theme),
              MediaTab(media: _media, theme: theme),
              EventsTab(events: _events, theme: theme),
              InfoTab(profileData: _profileData),
            ],
          ),
        ),
      ),
    );
  }
}
