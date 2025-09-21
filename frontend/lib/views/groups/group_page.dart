// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\group_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'create_group_page.dart';
import 'group_detail_page.dart';
import 'widgets/group_list_section.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _loading = true;
  List<dynamic> _myGroups = [];
  List<dynamic> _discoverGroups = [];
  String? _error;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(
            'Kullanıcı oturumu bulunamadı. Lütfen yeniden giriş yapın.');
      }

      final dio = _authService.apiClient.dio;
      final headers = {'Authorization': 'Bearer $token'};

      print('🔥 API Request başlıyor...');
      print('🔥 MyGroups URL: ${dio.options.baseUrl}groups/my_groups/');
      print('🔥 DiscoverGroups URL: ${dio.options.baseUrl}groups/discover/');
      
      final [myGroupsResponse, discoverGroupsResponse] = await Future.wait([
        dio.get('groups/my_groups/', options: Options(headers: headers)),
        dio.get('groups/discover/', options: Options(headers: headers)),
      ]);

      print('🔥 MyGroups Response Status: ${myGroupsResponse.statusCode}');
      print('🔥 MyGroups Response URL: ${myGroupsResponse.requestOptions.uri}');
      print('🔥 MyGroups Response Data: ${myGroupsResponse.data}');
      print('🔥 DiscoverGroups Response Status: ${discoverGroupsResponse.statusCode}');
      print('🔥 DiscoverGroups Response Data: ${discoverGroupsResponse.data}');

      if (myGroupsResponse.statusCode == 200 &&
          discoverGroupsResponse.statusCode == 200) {
        if (!mounted) return;
        
        final myGroupsData = myGroupsResponse.data is List ? myGroupsResponse.data : [];
        final discoverGroupsData = discoverGroupsResponse.data is List ? discoverGroupsResponse.data : [];
        
        print('🔥 Processed MyGroups Data: ${myGroupsData.length} groups');
        for (final group in myGroupsData) {
          print('🔥 - ${group['name']} (ID: ${group['id']})');
        }
        
        setState(() {
          _myGroups = myGroupsData;
          _discoverGroups = discoverGroupsData;
        });
      } else {
        throw Exception(
            'HTTP ${myGroupsResponse.statusCode} - Gruplar yüklenirken bir sorun oluştu.');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.response?.data['message'] ?? e.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Grup oluşturma sonrası özel yenileme fonksiyonu
  Future<void> _refreshAfterGroupCreation() async {
    print('🔥 Grup oluşturma sonrası yenileme başlıyor...');
    
    // Cache'i temizle
    if (_authService.apiClient != null) {
      _authService.apiClient.clearCache();
    }
    
    // State'i temizle
    setState(() {
      _myGroups = [];
      _discoverGroups = [];
      _loading = true;
      _error = null;
    });
    
    // Daha uzun bekleme ekleyerek API'nin güncellenmesini sağla
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Grupları yeniden yükle
    await _loadGroups();
    
    print('🔥 Grup oluşturma sonrası yenileme tamamlandı');
  }

  // Gruba katıldıktan sonra özel yenileme fonksiyonu
  Future<void> _refreshAfterJoin() async {
    // Kısa bir bekleme ekleyerek API'nin güncellenmesini sağla
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadGroups();
  }

  // Güçlü yenileme fonksiyonu (manuel refresh için)
  Future<void> _forceRefreshGroups() async {
    print('🔥 Manuel yenileme başlıyor...');
    
    // Cache'i temizle
    if (_authService.apiClient != null) {
      _authService.apiClient.clearCache();
    }
    
    // State'i temizle
    setState(() {
      _myGroups = [];
      _discoverGroups = [];
      _loading = true;
      _error = null;
    });
    
    // Kısa bekleme
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Grupları yeniden yükle
    await _loadGroups();
    
    print('🔥 Manuel yenileme tamamlandı');
  }

  // Gruba katıldıktan sonra optimistik güncelleme
  void _moveGroupToMyGroups(dynamic group) {
    setState(() {
      // Grubu discover listesinden çıkar
      _discoverGroups.removeWhere((g) => g['id'] == group['id']);
      // Grubu my groups listesine ekle (eğer zaten yoksa)
      if (!_myGroups.any((g) => g['id'] == group['id'])) {
        _myGroups.add(group);
      }
    });
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gruplar Yüklenemedi',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _loadGroups,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Tekrar Dene',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_error!.contains('oturum') || _error!.contains('giriş')) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LoginPage(authService: _authService)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.surfaceVariant,
                        foregroundColor: colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gruplar yükleniyor...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add_outlined,
                size: 64,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz hiç grubunuz yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'İlk grubunuzu oluşturarak başlayın!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateGroupPage(
                        onGroupCreated: _refreshAfterGroupCreation,
                        authService: _authService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Yeni Grup Oluştur',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gruplar',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: colorScheme.primary,
              ),
              onPressed: _forceRefreshGroups,
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GroupListSection(
                          title: 'Gruplarım',
                          groups: _myGroups,
                          authService: _authService,
                          isMyGroupsSection: true,
                          emptyStateWidget: _buildEmptyState(),
                        ),
                        const SizedBox(height: 32),
                        GroupListSection(
                          title: 'Keşfet',
                          groups: _discoverGroups,
                          authService: _authService,
                          isMyGroupsSection: false,
                          onJoinSuccess: _refreshAfterJoin, // Gruba katıldıktan sonra listeyi yenile
                          onGroupJoined: _moveGroupToMyGroups, // Grubu hemen taşı
                          emptyStateWidget: Center(
                            child: Text(
                              'Keşfedilecek grup bulunamadı',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        // Benzersiz heroTag eklendi
        heroTag: 'groups_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGroupPage(
                onGroupCreated: _refreshAfterGroupCreation,
                authService: _authService,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
