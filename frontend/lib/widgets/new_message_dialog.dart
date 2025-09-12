import 'package:flutter/material.dart';
import '../../../services/chat/chat_service.dart';

class NewMessageDialog extends StatefulWidget {
  final Function(User) onUserSelected;

  const NewMessageDialog({
    super.key,
    required this.onUserSelected,
  });

  @override
  State<NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _chatService.searchUsers(query.trim());
      for (var user in results) {
      }
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Yeni Mesaj',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Search Field
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchUsers(value);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Kullanıcı aramak için yazmaya başlayın',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Arama sırasında hata oluştu',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Kullanıcı bulunamadı',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi deneyin',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(User user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          backgroundImage: user.profilePicture != null
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null
              ? Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                )
              : null,
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: () => widget.onUserSelected(user),
            icon: Icon(
              Icons.message_rounded,
              color: colorScheme.onPrimary,
              size: 20,
            ),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
        onTap: () => widget.onUserSelected(user),
      ),
    );
  }
}
