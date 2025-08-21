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
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  Map<String, dynamic>? _profileData;
  List<dynamic>? _posts;
  List<dynamic>? _media;
  List<dynamic>? _events;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ServiceLocator.user.getProfile(widget.username);
      final posts = await ServiceLocator.user.getPosts(widget.username);
      final media = await ServiceLocator.user.getMedia(widget.username);
      final events = await ServiceLocator.user.getEvents(widget.username);

      if (!mounted) return;
      setState(() {
        _profileData = data;
        _posts = posts;
        _media = media;
        _events = events;
      });
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  void _signOut(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      drawer: ProfileDrawer(
        onSignOut: () => _signOut(context),
        colorScheme: colorScheme,
        theme: theme,
        profileData: _profileData ?? {}, // Burada profil verisini gönderiyoruz
      ),
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  username: widget.username,
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
                        // ignore: deprecated_member_use
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
