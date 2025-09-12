import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../models/map_state.dart';

/// Arama sonuçları widget'ı
class SearchResultsWidget extends StatelessWidget {
  final List<SearchResult> searchResults;
  final Function(SearchResult) onResultSelected;
  final bool isVisible;

  const SearchResultsWidget({
    super.key,
    required this.searchResults,
    required this.onResultSelected,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || searchResults.isEmpty) {
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
          maxHeight: mediaQuery.size.height * 0.4,
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
                    Icons.search,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Arama Sonuçları',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${searchResults.length} sonuç',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Results List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  return _buildSearchResultItem(context, result, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, SearchResult result, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => onResultSelected(result),
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
            // Location Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.location_on,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Location Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (result.city.isNotEmpty || result.country.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _buildLocationText(result),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Coordinates
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${result.coordinates.latitude.toStringAsFixed(4)}, ${result.coordinates.longitude.toStringAsFixed(4)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationText(SearchResult result) {
    final parts = <String>[];
    
    if (result.city.isNotEmpty) {
      parts.add(result.city);
    }
    
    if (result.country.isNotEmpty) {
      parts.add(result.country);
    }
    
    return parts.join(', ');
  }
}