import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../event/events_page.dart';

class GroupService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://172.19.34.247:8000/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<dynamic>> fetchUserGroups() async {
    try {
      // Token'ı SharedPreferences'ten al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception(
            'Kullanıcı oturumu bulunamadı. Lütfen yeniden giriş yapın.');
      }

      // Token'ı header'a ekle
      dio.options.headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      final response = await dio.get('api/groups/');

      if (response.statusCode == 200) {
        return response.data as List;
      } else {
        throw Exception(
            'HTTP ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Özel durum yönetimi
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        throw Exception('Yetkisiz erişim. Lütfen yeniden giriş yapın.');
      } else {
        throw Exception('API isteği başarısız: ${e.message}');
      }
    }
  }
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final GroupService _service = GroupService();
  bool _loading = true;
  List<dynamic> _groups = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchUserGroups();
      setState(() {
        // ignore: unnecessary_type_check
        _groups = data is List ? data : [];
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('Yetkisiz')) {
          _error = 'Oturum süreniz doldu. Lütfen yeniden giriş yapın.';
          // 3 saniye sonra otomatik login sayfasına yönlendir
          Future.delayed(const Duration(seconds: 3), () {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          _error =
              'Gruplar yüklenirken hata oluştu: ${e.toString().split('\n').first}';
        }
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
              if (_error!.contains('Oturum')) const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return const Center(
        child: Text(
          'Henüz grup yok',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];

          // Grup verisinin Map olup olmadığını kontrol et
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
                    builder: (_) => EventsPage(
                      groupId: group['id'] ?? '0',
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
