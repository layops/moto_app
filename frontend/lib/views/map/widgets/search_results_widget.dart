import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../models/map_state.dart';

/// Arama sonuçları widget'ı
class SearchResultsWidget extends StatelessWidget {
  final List<SearchResult> searchResults;
  final bool isLoading;
  final Function(SearchResult) onResultSelected;

  const SearchResultsWidget({
    super.key,
    required this.searchResults,
    required this.isLoading,
    required this.onResultSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    if (searchResults.isEmpty && !isLoading) {
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
        child: isLoading
            ? _buildLoadingWidget(context)
            : _buildResultsList(context),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final result = searchResults[index];
        final displayName = result.displayName.length > 50
            ? '${result.displayName.substring(0, 50)}...'
            : result.displayName;

        return ListTile(
          leading: Icon(Icons.location_on, color: colorScheme.primary),
          title: Text(
            displayName,
            style: textTheme.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: result.city.isNotEmpty || result.country.isNotEmpty
              ? Text(
                  '${result.city}${result.city.isNotEmpty && result.country.isNotEmpty ? ', ' : ''}${result.country}',
                  style: textTheme.bodyMedium,
                )
              : null,
          onTap: () => onResultSelected(result),
        );
      },
    );
  }
}
