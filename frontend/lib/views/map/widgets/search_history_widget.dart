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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    if (searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 80 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Son Aramalar',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searchHistory.length,
              itemBuilder: (context, index) {
                final historyItem = searchHistory[index];
                return ListTile(
                  leading: Icon(
                    Icons.history,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  title: Text(historyItem, style: textTheme.bodyLarge),
                  onTap: () => onHistoryItemSelected(historyItem),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
