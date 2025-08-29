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
      final headers = {'Authorization': 'Token $token'};

      final [myGroupsResponse, discoverGroupsResponse] = await Future.wait([
        dio.get('groups/my_groups/', options: Options(headers: headers)),
        dio.get('groups/discover/', options: Options(headers: headers)),
      ]);

      if (myGroupsResponse.statusCode == 200 &&
          discoverGroupsResponse.statusCode == 200) {
        setState(() {
          _myGroups =
              myGroupsResponse.data is List ? myGroupsResponse.data : [];
          _discoverGroups = discoverGroupsResponse.data is List
              ? discoverGroupsResponse.data
              : [];
        });
      } else {
        throw Exception(
            'HTTP ${myGroupsResponse.statusCode} - Gruplar yüklenirken bir sorun oluştu.');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.toString());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Henüz hiç grubunuz yok',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('İlk grubunuzu oluşturarak başlayın!',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateGroupPage(
                    onGroupCreated: _loadGroups,
                    authService: _authService,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruplar'),
        backgroundColor: AppColorSchemes.surfaceColor,
        foregroundColor: AppColorSchemes.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                          isMyGroupsSection: true,
                          emptyStateWidget: _buildEmptyState(),
                        ),
                        const SizedBox(height: 32),
                        GroupListSection(
                          title: 'Keşfet',
                          groups: _discoverGroups,
                          isMyGroupsSection: false,
                          emptyStateWidget: const Center(
                            child: Text('Keşfedilecek grup bulunamadı',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        // Benzersiz heroTag eklendi
        heroTag: 'groups_fab',
        backgroundColor: AppColorSchemes.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGroupPage(
                onGroupCreated: _loadGroups,
                authService: _authService,
              ),
            ),
          );
        },
      ),
    );
  }
}
