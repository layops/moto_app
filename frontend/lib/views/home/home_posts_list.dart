import 'package:flutter/material.dart';
import '../../widgets/post/post_item.dart';
import 'home_empty_state.dart';

class HomePostsList extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<dynamic> posts;
  final Future<void> Function() onRefresh;

  const HomePostsList({
    super.key,
    required this.loading,
    required this.error,
    required this.posts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildLoading();
    if (error != null) return _buildError(context);
    if (posts.isEmpty) return const HomeEmptyState();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) => PostItem(post: posts[index]),
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => onRefresh(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
}
