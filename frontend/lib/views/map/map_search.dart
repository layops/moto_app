part of map_page;

extension MapSearch on _MapPageState {
  void _onSearchTextChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocation();
    });
  }

  void _searchLocation() async {
    final String searchText = _searchController.text.trim();
    if (searchText.isEmpty || searchText.length < 3) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _searchResults = [];
      });
    }

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': searchText,
          'format': 'json',
          'limit': '5',
          'addressdetails': '1',
          'countrycodes': 'tr',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MotoApp/1.0 (location search)'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => _searchResults = data);
        _saveSearchHistory(searchText);
        if (data.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hiç sonuç bulunamadı.'),
              duration: Duration(seconds: 2),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else if (response.statusCode == 429) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çok hızlı arama yapıldı. Lütfen bekleyin.'),
              duration: Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        if (mounted) setState(() => _searchResults = []);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arama sırasında hata oluştu.'),
              duration: Duration(seconds: 2),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama zaman aşımına uğradı.'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İnternet bağlantınızı kontrol edin.'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectSearchResult(dynamic result) {
    if (result != null) {
      final double? lat = double.tryParse(result['lat'].toString());
      final double? lon = double.tryParse(result['lon'].toString());
      if (lat == null || lon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geçersiz konum sonucu.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() {
        _selectedPosition = LatLng(lat, lon);
        _searchResults = [];
        _searchController.clear();
        _isSearchFocused = false;
      });

      _mapController.move(_selectedPosition!, 15.0);
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() => _searchHistory = history);
    } catch (e) {
      _searchHistory = [];
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
      await prefs.setStringList('search_history', _searchHistory);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    return Positioned(
      top: 16 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusXLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: "Konum ara... (örn: İstanbul, Kadıköy)",
            border: InputBorder.none,
            hintStyle: textTheme.bodyMedium,
            prefixIcon: Icon(Icons.search, color: textTheme.bodyMedium?.color),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: textTheme.bodyMedium?.color),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _isSearchFocused = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: _onSearchTextChanged,
          onSubmitted: (_) => _searchLocation(),
          onTap: () {
            setState(() => _isSearchFocused = true);
          },
        ),
      ),
    );
  }

  Widget _buildSearchHistory(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    if (_searchHistory.isEmpty || _searchResults.isNotEmpty || _isLoading || !_isSearchFocused) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 80 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
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
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final historyItem = _searchHistory[index];
                return ListTile(
                  leading: Icon(Icons.history,
                      color: colorScheme.onSurface.withOpacity(0.5)),
                  title: Text(historyItem, style: textTheme.bodyLarge),
                  onTap: () {
                    _searchController.text = historyItem;
                    setState(() => _isSearchFocused = false);
                    _searchLocation();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    if (_searchResults.isEmpty && !_isLoading) return const SizedBox.shrink();

    return Positioned(
      top: 80 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoading
            ? Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final displayName =
                      result['display_name'] as String? ?? 'Bilinmeyen konum';
                  final address = result['address'] as Map<String, dynamic>?;
                  final city = address?['city'] ??
                      address?['town'] ??
                      address?['village'] ??
                      '';
                  final country = address?['country'] ?? '';

                  return ListTile(
                    leading:
                        Icon(Icons.location_on, color: colorScheme.primary),
                    title: Text(
                      displayName.length > 50
                          ? '${displayName.substring(0, 50)}...'
                          : displayName,
                      style: textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: city.isNotEmpty || country.isNotEmpty
                        ? Text(
                            '$city${city.isNotEmpty && country.isNotEmpty ? ', ' : ''}$country',
                            style: textTheme.bodyMedium,
                          )
                        : null,
                    onTap: () => _selectSearchResult(result),
                  );
                },
              ),
      ),
    );
  }
}
