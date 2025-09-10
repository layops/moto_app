import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../models/search_models.dart';
import 'search_results_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late TabController _tabController;
  
  bool _isSearching = false;
  String _currentQuery = '';
  Map<String, List<Map<String, dynamic>>> _searchResults = {
    'users': [],
    'groups': [],
  };
  String? _error;
  List<String> _searchHistory = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSearchHistory();
    
    // Sayfa açıldığında arama kutusuna odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final history = await ServiceLocator.search.getSearchHistory();
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      debugPrint('Arama geçmişi yüklenemedi: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = {'users': [], 'groups': []};
        _error = null;
      });
      return;
    }

    // Minimum 2 karakter kontrolü
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = {'users': [], 'groups': []};
        _error = 'Arama için en az 2 karakter giriniz';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _currentQuery = query.trim();
    });

    try {
      // Arama geçmişine kaydet
      await ServiceLocator.search.saveSearchHistory(_currentQuery);
      
      // Arama yap
      final results = await ServiceLocator.search.searchAll(_currentQuery);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
      // Arama geçmişini yenile
      _loadSearchHistory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  void _onSearchSubmitted(String query) {
    _searchDebounce?.cancel();
    _performSearch(query);
  }

  void _onSearchTextChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(text);
    });
  }

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = {'users': [], 'groups': []};
      _error = null;
      _currentQuery = '';
    });
  }

  void _clearHistory() async {
    await ServiceLocator.search.clearSearchHistory();
    setState(() {
      _searchHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kullanıcılar', icon: Icon(Icons.person)),
            Tab(text: 'Gruplar', icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya grup ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onSubmitted: _onSearchSubmitted,
              onChanged: (value) {
                setState(() {}); // Suffix icon'u güncellemek için
                _onSearchTextChanged(value);
              },
            ),
          ),
          
          // Arama geçmişi (sadece arama yapılmamışsa göster)
          if (_currentQuery.isEmpty && _searchHistory.isNotEmpty)
            _buildSearchHistory(),
          
          // Arama sonuçları
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son Aramalar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: const Text('Temizle'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.take(5).map((query) {
              return ActionChip(
                label: Text(query),
                onPressed: () => _onHistoryItemTap(query),
                avatar: const Icon(Icons.history, size: 16),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_currentQuery.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Arama yapmak için yukarıdaki kutuya yazın',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: LoadingWidget(message: 'Aranıyor...'));
    }

    if (_error != null) {
      return Center(
        child: CustomErrorWidget(
          message: _error!,
          onRetry: () => _performSearch(_currentQuery),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        SearchResultsWidget(
          results: _searchResults['users'] ?? [],
          type: SearchResultType.users,
          query: _currentQuery,
        ),
        SearchResultsWidget(
          results: _searchResults['groups'] ?? [],
          type: SearchResultType.groups,
          query: _currentQuery,
        ),
      ],
    );
  }
}

