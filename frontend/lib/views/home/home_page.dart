// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../widgets/app_bars/base_app_bar.dart';
// import '../../services/auth/auth_service.dart';
// import '../../services/post/post_service.dart';
// import '../../services/post/create_post_page.dart';
// import 'home_drawer.dart';
// import 'home_posts_list.dart';

// class HomePage extends StatefulWidget {
//   final String? username;
//   const HomePage({super.key, this.username});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   bool _loading = true;
//   List<dynamic> _posts = [];
//   String? _error;
//   late PostService _postService;
//   late AuthService _authService;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _postService = Provider.of<PostService>(context, listen: false);
//     _authService = Provider.of<AuthService>(context, listen: false);
//     if (_posts.isEmpty && _error == null) _loadPosts();
//   }

//   Future<void> _loadPosts() async {
//     setState(() => _loading = true);
//     try {
//       final token = await _authService.getToken();
//       if (token == null) throw Exception('Oturum bulunamadı');
//       _posts = await _postService.fetchPosts(token);
//       _error = null;
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   void _openCreatePost() => Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => CreatePostPage(onPostCreated: _loadPosts),
//         ),
//       );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const HomeDrawer(),
//       appBar: const BaseAppBar(
//         title: 'Ana Sayfa',
//         leadingButtonType: LeadingButtonType.menu,
//       ),
//       body: HomePostsList(
//         loading: _loading,
//         error: _error,
//         posts: _posts,
//         onRefresh: _loadPosts,
//       ),
//       floatingActionButton: FloatingActionButton(
//         heroTag: 'homePageFAB',
//         onPressed: _openCreatePost,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }




// home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_bars/base_app_bar.dart';
import '../../services/auth/auth_service.dart';
import '../../services/post/post_service.dart';
import '../../services/post/create_post_page.dart';
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
      if (token == null) throw Exception('Oturum bulunamadı');
      
      // Genel postları çekmek için groupPk parametresini kullanmayın (veya null olarak geçin)
      _posts = await _postService.fetchPosts(token); 
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openCreatePost() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePostPage(
            onPostCreated: _loadPosts,
            groupPk: null, // Anasayfadan atılan postlar için groupPk'yı null olarak iletin
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