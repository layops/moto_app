// home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_bars/base_app_bar.dart';
import '../../services/auth/auth_service.dart';
import '../../services/post/post_service.dart';
import '../post/create_post_page.dart';
import 'home_drawer.dart';
import 'home_posts_list.dart';

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
    if (_posts.isEmpty && _error == null) _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final token = await _authService.getToken();
      print('Token: $token'); // Debug için

      if (token == null) throw Exception('Oturum bulunamadı');

      // Debug için URL'yi kontrol et
      print('API URL: https://spiride.onrender.com/api/posts');

      // Genel postları çekmek için groupPk parametresini kullanmayın
      _posts = await _postService.fetchPosts(token);
      print('Postlar başarıyla alındı: ${_posts.length} adet');
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Hata detayı: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openCreatePost() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePostPage(
            onPostCreated: _loadPosts,
            groupPk: null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      appBar: const BaseAppBar(
        title: 'Ana Sayfa',
        leadingButtonType: LeadingButtonType.menu,
      ),
      body: HomePostsList(
        loading: _loading,
        error: _error,
        posts: _posts,
        onRefresh: _loadPosts,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        child: const Icon(Icons.add),
      ),
    );
  }
}
