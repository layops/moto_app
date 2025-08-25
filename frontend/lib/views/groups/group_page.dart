import 'package:flutter/material.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import '../event/events_page.dart';
import 'create_group_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _loading = true;
  List<dynamic> _groups = [];
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

      // Burada _authService.apiClient.dio olarak düzelttik
      final dio = _authService.apiClient.dio;

      final response = await dio.get(
        'groups/',
        options: Options(headers: {'Authorization': 'Token $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _groups = response.data is List ? response.data : [];
        });
      } else {
        throw Exception(
            'HTTP ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String errorMessage = 'Gruplar yüklenirken hata oluştu';

      if (statusCode == 401) {
        errorMessage = 'Oturum süreniz doldu. Lütfen yeniden giriş yapın.';
      } else {
        errorMessage = 'API isteği başarısız: ${e.message}';
      }

      setState(() => _error = errorMessage);
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadGroups,
                child: const Text('Tekrar Dene'),
              ),
              if (_error!.contains('Oturum') || _error!.contains('giriş'))
                const SizedBox(height: 10),
              if (_error!.contains('Oturum') || _error!.contains('giriş'))
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginPage(authService: _authService),
                    ),
                  ),
                  child: const Text('Giriş Yap'),
                ),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Henüz grup yok',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateGroupPage(
                        onGroupCreated: () {
                          _loadGroups();
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Yeni Grup Oluştur'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];

          if (group is! Map<String, dynamic>) {
            return const ListTile(
              title: Text('Geçersiz grup verisi'),
            );
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(
                group['name']?.toString() ?? 'İsimsiz Grup',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  Text(group['description']?.toString() ?? 'Açıklama yok'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventsPage.forGroup(
                      groupId: (group['id'] is int)
                          ? group['id'] as int
                          : int.tryParse(group['id'].toString()) ?? 0,
                      groupName: group['name']?.toString() ?? 'Grup',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
