import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_bars/base_app_bar.dart';
import '../groups/group_page.dart';
import '../../services/post/post_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/post/create_post_page.dart';
import '../profile/profile_page.dart'; // Profil sayfası import

class HomePage extends StatefulWidget {
  final String? username;

  const HomePage({super.key, this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  List<dynamic> _posts = [];
  String? _error;
  late PostService _postService;
  late AuthService _authService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _postService = Provider.of<PostService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    if (_posts.isEmpty && _error == null) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Oturum bulunamadı. Giriş yapın.');

      final posts = await _postService.fetchPosts(token);
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(
          onPostCreated: _loadPosts,
        ),
      ),
    );
  }

  void _openProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFd32f2f)),
              child: Text(
                'Menü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Ana Sayfa'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Gruplar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      appBar: BaseAppBar(
        title: 'Ana Sayfa',
        leadingButtonType: LeadingButtonType.menu,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'homePageFAB',
        onPressed: _openCreatePost,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    if (_posts.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];

          // Backend'den gelen veriye göre kullanıcı adı ve avatar
          final username = post['author_username']?.toString() ?? 'Bilinmeyen';
          final avatarUrl = post['author_avatar']?.toString();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: GestureDetector(
                onTap: () => _openProfile(username),
                child: CircleAvatar(
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person) : null,
                ),
              ),
              title: GestureDetector(
                onTap: () => _openProfile(username),
                child: Text(
                  username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post['content'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(post['content'].toString()),
                    ),
                  if (post['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.network(post['image'].toString()),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Henüz post yok'),
          ],
        ),
      ),
    );
  }
}
