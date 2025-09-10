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
  List<Map<String, dynamic>> _availableUsers = [];
  List<Map<String, dynamic>> _availableGroups = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSearchHistory();
    _loadAvailableData();
    
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

  Future<void> _loadAvailableData() async {
    try {
      final users = await ServiceLocator.search.getAvailableUsers();
      final groups = await ServiceLocator.search.getAvailableGroups();
      setState(() {
        _availableUsers = users;
        _availableGroups = groups;
      });
    } catch (e) {
      debugPrint('Mevcut veriler yüklenemedi: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    print('🔍 SearchPage - _performSearch başlatıldı: "$query"');
    
    if (query.trim().isEmpty) {
      print('🔍 SearchPage - Boş query, sonuçlar temizleniyor');
      setState(() {
        _searchResults = {'users': [], 'groups': []};
        _error = null;
        _currentQuery = '';
      });
      return;
    }

    // Minimum 2 karakter kontrolü
    if (query.trim().length < 2) {
      print('🔍 SearchPage - Query çok kısa (${query.trim().length} karakter)');
      setState(() {
        _searchResults = {'users': [], 'groups': []};
        _error = 'Arama için en az 2 karakter giriniz';
        _currentQuery = query.trim();
      });
      return;
    }

    print('🔍 SearchPage - Arama işlemi başlatılıyor: "${query.trim()}"');
    setState(() {
      _isSearching = true;
      _error = null;
      _currentQuery = query.trim();
    });

    try {
      // Arama geçmişine kaydet
      print('🔍 SearchPage - Arama geçmişine kaydediliyor...');
      await ServiceLocator.search.saveSearchHistory(_currentQuery);
      
      // Arama yap
      print('🔍 SearchPage - ServiceLocator.search.searchAll() çağrılıyor...');
      final results = await ServiceLocator.search.searchAll(_currentQuery);
      
      print('🔍 SearchPage - Arama sonuçları alındı:');
      print('   Kullanıcılar: ${results['users']?.length ?? 0}');
      print('   Gruplar: ${results['groups']?.length ?? 0}');
      print('   Kullanıcı verileri: ${results['users']}');
      print('   Grup verileri: ${results['groups']}');
      
      if (mounted) {
        print('🔍 SearchPage - setState çağrılıyor...');
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        print('🔍 SearchPage - setState tamamlandı');
        print('🔍 SearchPage - _searchResults güncel hali: $_searchResults');
        
        // Arama geçmişini yenile
        _loadSearchHistory();
      }
    } catch (e) {
      print('❌ SearchPage - Arama hatası: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchSubmitted(String query) {
    _searchDebounce?.cancel();
    _performSearch(query);
  }

  void _onSearchTextChanged(String text) {
    setState(() {
      _showSuggestions = text.trim().isNotEmpty && text.trim().length < 2;
    });
    
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
      _showSuggestions = false;
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
          
          // Öneriler (1 karakter yazıldığında göster)
          if (_showSuggestions)
            _buildSuggestions(),
          
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

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Arama İpuçları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'En az 2 karakter girin. Örnek arama terimleri:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          // Kullanıcı önerileri
          if (_availableUsers.isNotEmpty) ...[
            const Text(
              '👥 Kullanıcı Adları:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableUsers.take(5).map((user) {
                final username = user['username'] ?? '';
                final fullName = user['full_name'] ?? '';
                return ActionChip(
                  label: Text('@$username'),
                  onPressed: () {
                    _searchController.text = username;
                    _performSearch(username);
                  },
                  avatar: const Icon(Icons.person, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          
          // Grup önerileri
          if (_availableGroups.isNotEmpty) ...[
            const Text(
              '👥 Grup Adları:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableGroups.take(5).map((group) {
                final name = group['name'] ?? '';
                return ActionChip(
                  label: Text(name),
                  onPressed: () {
                    _searchController.text = name;
                    _performSearch(name);
                  },
                  avatar: const Icon(Icons.group, size: 16),
                );
              }).toList(),
            ),
          ],
          
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

