import 'package:flutter/material.dart';
import 'home_posts_list.dart';
import '../../services/service_locator.dart';
import '../post/create_post_page.dart'; // Örnek olarak ekledim

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  String? error;
  List<dynamic> posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await ServiceLocator.token.getToken();
      if (token != null) {
        // Genel post akışını çekmek için PostService'i kullanıyoruz.
        final fetchedPosts = await ServiceLocator.post.fetchPosts(token);
        setState(() {
          posts = fetchedPosts;
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

  void _onPostButtonPressed() async {
    // Post oluşturma sayfasına navigasyon
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    // Eğer post oluşturulduysa, ana sayfayı yenile
    if (result == true) {
      _fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menü')),
            ListTile(
              title: const Text('Profil'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              title: const Text('Ayarlar'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: HomePostsList(
        loading: loading,
        error: error,
        posts: posts,
        onRefresh: _fetchPosts,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onPostButtonPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
