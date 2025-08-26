import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:motoapp_frontend/views/event/events_page.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'create_group_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _loading = true;
  List<dynamic> _groups = [];
  List<dynamic> _discoverGroups = []; // Keşfedilecek gruplar için yeni liste
  String? _error;
  late AuthService _authService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
    if (_groups.isEmpty && _error == null) {
      _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
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
      final response = await dio.get(
        'groups/',
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _groups = response.data is List ? response.data : [];
          // Geçici olarak keşfedilecek grupları da aynı veriyle dolduruyoruz
          // Gerçek uygulamada bu farklı bir API endpoint'inden gelmeli
          _discoverGroups = List.from(_groups);
        });
      } else {
        throw Exception(
            'HTTP ${response.statusCode} - ${response.statusMessage}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruplar'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGroups),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_groups',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGroupPage(
                onGroupCreated: () => _loadGroups(),
                authService: _authService, // Bu satırı ekleyin
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadGroups, child: const Text('Tekrar Dene')),
              if (_error!.contains('oturum') || _error!.contains('giriş'))
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LoginPage(authService: _authService)),
                    );
                  },
                  child: const Text('Giriş Yap'),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Groups Section
            _buildSectionTitle('My Groups'),
            const SizedBox(height: 16),
            _groups.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: _groups
                        .map((group) => _buildGroupCard(group, true))
                        .toList(),
                  ),

            const SizedBox(height: 32),

            // Discover Groups Section
            _buildSectionTitle('Discover Groups'),
            const SizedBox(height: 16),
            _discoverGroups.isEmpty
                ? const Center(child: Text('Keşfedilecek grup bulunamadı'))
                : Column(
                    children: _discoverGroups
                        .map((group) => _buildGroupCard(group, false))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColorSchemes.textPrimary,
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Henüz grup yok', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateGroupPage(
                    onGroupCreated: _loadGroups,
                    authService: _authService, // Bu satırı ekleyin
                  ),
                ),
              );
            },
            child: const Text('Yeni Grup Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(dynamic group, bool isMyGroup) {
    if (group is! Map<String, dynamic>) {
      return const Card(
        child: ListTile(title: Text('Geçersiz grup verisi')),
      );
    }

    final groupId = (group['id'] is int)
        ? group['id'] as int
        : int.tryParse(group['id'].toString()) ?? 0;
    final groupName = group['name']?.toString() ?? 'Grup';
    final description = group['description']?.toString() ?? 'Açıklama yok';

    // Geçici veriler - gerçek uygulamada API'den gelmeli
    final location = group['location']?.toString() ?? 'San Francisco, CA';
    final memberCount = group['member_count']?.toString() ?? '1,247';
    final activeTime = group['active_time']?.toString() ?? '2 hours ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColorSchemes.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMyGroup)
                  ElevatedButton(
                    onPressed: () {
                      // Gruba katılma işlevi
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorSchemes.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ThemeConstants.borderRadiusMedium),
                      ),
                    ),
                    child: const Text('Join'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$memberCount members',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Active $activeTime',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
