import 'package:flutter/material.dart';
import '../profile/profile_page.dart';

class PostItem extends StatelessWidget {
  final dynamic post;
  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final username = post['author_username']?.toString() ?? 'Bilinmeyen';
    final avatarUrl = post['author_avatar']?.toString();
    final imageUrl = post['image']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () => _openProfile(context, username),
              child: CircleAvatar(
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
            title: GestureDetector(
              onTap: () => _openProfile(context, username),
              child: Text(username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          if (post['content'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(post['content'].toString()),
            ),
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.favorite_border), onPressed: () {}),
                IconButton(icon: const Icon(Icons.comment), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(username: username)),
    );
  }
}
