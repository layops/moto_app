// home_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home_posts_list.dart';
import '../../services/service_locator.dart';
import '../../services/performance/performance_optimizer.dart';
import '../post/create_post_page.dart';
import '../../widgets/navigations/navigation_items.dart';
import '../notifications/notifications_page.dart';
import '../search/search_page.dart';
import '../leaderboard/leaderboard_page.dart';
import '../../widgets/common/modern_fab.dart';

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
    print('HomePage - _fetchPosts başlatıldı');
    if (!mounted) {
      print('HomePage - Widget mounted değil, _fetchPosts iptal edildi');
      return;
    }
    
    setState(() {
      loading = true;
      error = null;
    });
    print('HomePage - Loading state true yapıldı');

    try {
      final token = await ServiceLocator.token.getToken();
      print('HomePage - Token alındı: ${token != null ? "Token mevcut" : "Token yok"}');
      
      if (token != null) {
        print('HomePage - PostService.fetchPosts çağrılıyor...');
        final fetchedPosts = await ServiceLocator.post.fetchPosts(token);
        print('HomePage - fetchPosts tamamlandı, ${fetchedPosts.length} post alındı');

        // Debug için gelen postları yazdır (sadece debug modda)
        if (kDebugMode) {
          print('HomePage - Fetched posts count: ${fetchedPosts.length}');
          for (int i = 0; i < fetchedPosts.length && i < 2; i++) {
            final post = fetchedPosts[i] as Map<String, dynamic>;
            final content = post['content']?.toString() ?? '';
            final contentPreview = content.length > 15 ? '${content.substring(0, 15)}...' : content;
            print('HomePage - Post ${post['id']}: "$contentPreview"');
          }
        }

        // Process posts to get user details for author IDs - Optimized for performance
        print('HomePage - Post processing başlatılıyor...');
        final updatedPosts = await _processPostsWithUserDetails(fetchedPosts);
        print('HomePage - Post processing tamamlandı, ${updatedPosts.length} post işlendi');

        if (!mounted) {
          print('HomePage - Widget mounted değil, state güncelleme iptal edildi');
          return;
        }
        
        setState(() {
          posts = updatedPosts;
        });
        print('HomePage - State güncellendi, posts sayısı: ${posts.length}');
      }
    } catch (e) {
      print('HomePage - _fetchPosts hatası: $e');
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (!mounted) {
        print('HomePage - Widget mounted değil, loading state güncelleme iptal edildi');
        return;
      }
      setState(() {
        loading = false;
      });
      print('HomePage - Loading state false yapıldı');
    }
  }

  /// Optimized method to process posts with user details using PerformanceOptimizer
  Future<List<dynamic>> _processPostsWithUserDetails(List<dynamic> fetchedPosts) async {
    return await PerformanceOptimizer.runInBackground(
      () => PerformanceOptimizer.processBatch(
        fetchedPosts,
        (post) async {
          if (post['author'] is int) {
            try {
              final userDetails = await _fetchUserDetails(post['author']);
              return {
                ...post,
                'author': userDetails,
              };
            } catch (e) {
              // Fallback to original post if user details fetch fails
              return post;
            }
          }
          return post;
        },
        batchSize: 3, // Reduced batch size for better performance
        delayBetweenBatches: const Duration(milliseconds: 5),
      ),
      debugLabel: 'Process Posts with User Details',
    );
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
      if (!mounted) return;
      setState(() {
        unreadNotificationsCount = unreadCount;
      });
    } catch (e) {
      debugPrint('Bildirimler alınamadı: $e');
    }
  }

  void _onPostButtonPressed() async {
    print('HomePage - _onPostButtonPressed başlatıldı');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
    print('HomePage - Navigator.pop result: $result');

    // Gönderi oluşturulduysa anasayfayı yenile
    if (result == true) {
      print('HomePage - Gönderi oluşturuldu, anasayfa yenileniyor...');
      
      // Önce cache'i manuel olarak temizle
      ServiceLocator.post.clearCache();
      print('HomePage - Cache manuel olarak temizlendi');
      
      // Sonra postları yeniden yükle
      await _fetchPosts();
      print('HomePage - _fetchPosts tamamlandı');
      
      // Bildirimleri de yenile
      _fetchUnreadNotifications();
      print('HomePage - _fetchUnreadNotifications tamamlandı');
    } else {
      print('HomePage - Gönderi oluşturulmadı veya iptal edildi');
    }
  }

  void _onNotificationPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
    _fetchUnreadNotifications();
  }

  void _onSearchPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void _onLeaderboardPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/spiride_logo.png',
          height: 50,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.leaderboard_rounded,
              color: colorScheme.primary,
            ),
            onPressed: _onLeaderboardPressed,
            tooltip: 'Liderlik Tablosu',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
              ),
              onPressed: _onSearchPressed,
              tooltip: 'Arama',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: colorScheme.primary,
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount.toString(),
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
              onPressed: _onNotificationPressed,
            ),
          ),
        ],
      ),
      body: HomePostsList(
        loading: loading,
        error: error,
        posts: posts,
        onRefresh: _fetchPosts,
      ),
      floatingActionButton: ModernFAB(
        onPressed: _onPostButtonPressed,
        icon: Icons.add,
        tooltip: 'Yeni Gönderi Oluştur',
      ),
    );
  }
}
