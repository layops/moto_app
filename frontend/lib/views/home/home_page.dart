// home_page.dart
import 'package:flutter/material.dart';
import 'home_posts_list.dart';
import '../../services/service_locator.dart';
import '../post/create_post_page.dart';
import '../../widgets/navigations/navigation_items.dart';
import '../notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  String? error;
  List<dynamic> posts = [];

  int unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchUnreadNotifications();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await ServiceLocator.token.getToken();
      if (token != null) {
        final fetchedPosts = await ServiceLocator.post.fetchPosts(token);

        // Debug için gelen postları yazdır
        print('Fetched posts: $fetchedPosts');

        // Process posts to get user details for author IDs
        final updatedPosts = await Future.wait(fetchedPosts.map((post) async {
          if (post['author'] is int) {
            final userDetails = await _fetchUserDetails(post['author']);
            return {
              ...post,
              'author': userDetails,
            };
          }
          return post;
        }));

        setState(() {
          posts = updatedPosts;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchUserDetails(int userId) async {
    try {
      return await ServiceLocator.user.fetchUser(userId);
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
      return {};
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final notifications =
          await ServiceLocator.notification.getNotifications();
      final unreadCount =
          notifications.where((n) => n['is_read'] == false).length;
      setState(() {
        unreadNotificationsCount = unreadCount;
      });
    } catch (e) {
      debugPrint('Bildirimler alınamadı: $e');
    }
  }

  void _onPostButtonPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result == true) {
      _fetchPosts();
    }
  }

  void _onNotificationPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
    _fetchUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/spiride_logo.png',
          height: 50,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
            onPressed: _onNotificationPressed,
          ),
        ],
      ),
      body: HomePostsList(
        loading: loading,
        error: error,
        posts: posts,
        onRefresh: _fetchPosts,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: _onPostButtonPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
