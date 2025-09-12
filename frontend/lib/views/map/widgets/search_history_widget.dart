import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

/// Arama geçmişi widget'ı
class SearchHistoryWidget extends StatelessWidget {
  final List<String> searchHistory;
  final Function(String) onHistoryItemSelected;

  const SearchHistoryWidget({
    super.key,
    required this.searchHistory,
    required this.onHistoryItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    return Positioned(
      top: 80 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.3,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ThemeConstants.borderRadiusLarge),
                  topRight: Radius.circular(ThemeConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Son Aramalar',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // History List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: searchHistory.length,
                itemBuilder: (context, index) {
                  final query = searchHistory[index];
                  return _buildHistoryItem(context, query, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String query, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => onHistoryItemSelected(query),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // History Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.access_time,
                color: colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Query Text
            Expanded(
              child: Text(
                query,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}