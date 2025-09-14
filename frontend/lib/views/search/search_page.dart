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

  // Gelişmiş filtreleme özellikleri
  String _selectedFilter = 'all'; // 'all', 'users', 'groups'
  String _sortBy = 'relevance'; // 'relevance', 'name', 'date'
  bool _showOnlineOnly = false;
  bool _showActiveOnly = false;

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
      // debugPrint('Arama geçmişi yüklenemedi: $e');
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
      // debugPrint('Mevcut veriler yüklenemedi: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = {'users': [], 'groups': []};
        _error = null;
        _currentQuery = '';
      });
      return;
    }

    // Minimum 2 karakter kontrolü
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = {'users': [], 'groups': []};
        _error = 'Arama için en az 2 karakter giriniz';
        _currentQuery = query.trim();
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
      
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        
        // Arama geçmişini yenile
        _loadSearchHistory();
      }
    } catch (e) {
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
          
          // Filtreleme seçenekleri (arama yapıldığında göster)
          if (_currentQuery.isNotEmpty)
            _buildFilterOptions(),

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

  /// Filtreleme seçenekleri UI'ı
  Widget _buildFilterOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filtre türü seçici
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filtre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tümü')),
                DropdownMenuItem(value: 'users', child: Text('Kullanıcılar')),
                DropdownMenuItem(value: 'groups', child: Text('Gruplar')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  _applyFilters();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Sıralama seçici
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                labelText: 'Sırala',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'relevance', child: Text('İlgililik')),
                DropdownMenuItem(value: 'name', child: Text('İsim')),
                DropdownMenuItem(value: 'date', child: Text('Tarih')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                  _applyFilters();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Filtre butonu
          IconButton(
            onPressed: _showAdvancedFilters,
            icon: const Icon(Icons.tune),
            tooltip: 'Gelişmiş Filtreler',
          ),
        ],
      ),
    );
  }

  /// Gelişmiş filtreler dialog'unu göster
  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => _AdvancedFiltersDialog(
        showOnlineOnly: _showOnlineOnly,
        showActiveOnly: _showActiveOnly,
        onFiltersChanged: (onlineOnly, activeOnly) {
          setState(() {
            _showOnlineOnly = onlineOnly;
            _showActiveOnly = activeOnly;
          });
          _applyFilters();
        },
      ),
    );
  }

  /// Filtreleri uygula
  void _applyFilters() {
    if (_currentQuery.isEmpty) return;

    // Mevcut sonuçları filtrele
    List<Map<String, dynamic>> filteredUsers = List.from(_searchResults['users'] ?? []);
    List<Map<String, dynamic>> filteredGroups = List.from(_searchResults['groups'] ?? []);

    // Online kullanıcılar filtresi
    if (_showOnlineOnly) {
      filteredUsers = filteredUsers.where((user) => user['is_online'] == true).toList();
    }

    // Aktif gruplar filtresi
    if (_showActiveOnly) {
      filteredGroups = filteredGroups.where((group) => 
        group['is_active'] == true && group['member_count'] > 0).toList();
    }

    // Sıralama uygula
    _sortResults(filteredUsers, filteredGroups);

    setState(() {
      _searchResults = {
        'users': filteredUsers,
        'groups': filteredGroups,
      };
    });
  }

  /// Sonuçları sırala
  void _sortResults(List<Map<String, dynamic>> users, List<Map<String, dynamic>> groups) {
    switch (_sortBy) {
      case 'name':
        users.sort((a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''));
        groups.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'date':
        users.sort((a, b) => (b['last_login'] ?? '').compareTo(a['last_login'] ?? ''));
        groups.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        break;
      case 'relevance':
      default:
        // İlgililik sıralaması - backend'den gelen sıralama korunur
        break;
    }
  }

  /// Filtreleme durumuna göre sonuçları filtrele
  List<Map<String, dynamic>> _getFilteredResults(List<Map<String, dynamic>> results, String type) {
    if (_selectedFilter == 'all') return results;
    if (_selectedFilter == type) return results;
    return [];
  }
}

/// Gelişmiş filtreler dialog'u
class _AdvancedFiltersDialog extends StatefulWidget {
  final bool showOnlineOnly;
  final bool showActiveOnly;
  final Function(bool onlineOnly, bool activeOnly) onFiltersChanged;

  const _AdvancedFiltersDialog({
    required this.showOnlineOnly,
    required this.showActiveOnly,
    required this.onFiltersChanged,
  });

  @override
  State<_AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<_AdvancedFiltersDialog> {
  late bool _showOnlineOnly;
  late bool _showActiveOnly;

  @override
  void initState() {
    super.initState();
    _showOnlineOnly = widget.showOnlineOnly;
    _showActiveOnly = widget.showActiveOnly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Gelişmiş Filtreler'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Sadece Online Kullanıcılar'),
            subtitle: const Text('Sadece şu anda online olan kullanıcıları göster'),
            value: _showOnlineOnly,
            onChanged: (value) {
              setState(() {
                _showOnlineOnly = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Sadece Aktif Gruplar'),
            subtitle: const Text('Sadece aktif ve üyesi olan grupları göster'),
            value: _showActiveOnly,
            onChanged: (value) {
              setState(() {
                _showActiveOnly = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFiltersChanged(_showOnlineOnly, _showActiveOnly);
            Navigator.pop(context);
          },
          child: const Text('Uygula'),
        ),
      ],
    );
  }
}

