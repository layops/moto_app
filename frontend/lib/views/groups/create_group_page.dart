import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupPage extends StatefulWidget {
  final VoidCallback onGroupCreated;

  const CreateGroupPage({super.key, required this.onGroupCreated});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  bool _loading = false;
  String? _error;

  final Dio dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('auth_token'); // Token'ı nasıl saklıyorsan ona göre ayarla
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _error = "Lütfen giriş yapın.";
          _loading = false;
        });
        return;
      }

      final response = await dio.post(
        //'http://172.19.34.247:8000/api/groups/',  // EMRE
        'http://172.17.62.146:8000/api/groups/',    // OZAN
        data: {
          'name': _name,
          'description': _description,
        },
        options: Options(
          headers: {'Authorization': 'Token $token'},
        ),
      );

      if (response.statusCode == 201) {
        widget.onGroupCreated();
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _error = 'Grup oluşturulamadı: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Hata: $e';
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
      appBar: AppBar(title: const Text('Yeni Grup Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Grup Adı'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Grup adı zorunludur'
                    : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createGroup,
                      child: const Text('Oluştur'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
