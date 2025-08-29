// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\create_group_page.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/group/group_service.dart';

class CreateGroupPage extends StatefulWidget {
  final VoidCallback onGroupCreated;
  final AuthService authService;

  const CreateGroupPage({
    super.key,
    required this.onGroupCreated,
    required this.authService,
  });

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  bool _loading = false;
  String? _error;

  late GroupService _groupService;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(authService: widget.authService);
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _groupService.createGroup(_name, _description);
      widget.onGroupCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grup başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('Exception:')
            ? e.toString().split('Exception: ')[1]
            : 'Grup oluşturulurken bir hata oluştu: $e';
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
        title: const Text('Yeni Grup Oluştur',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorSchemes.surfaceColor,
        foregroundColor: AppColorSchemes.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: ThemeConstants.paddingLarge,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeni Bir Grup Başlat',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorSchemes.textPrimary,
                      )),
              const SizedBox(height: 8),
              Text('Motosiklet tutkunlarıyla bir araya gelin',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: ThemeConstants.paddingMedium,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_error != null) const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Grup Adı',
                  hintText: 'Örn: İstanbul Motosiklet Grubu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                  ),
                  filled: true,
                  fillColor: AppColorSchemes.lightBackground,
                  prefixIcon: const Icon(Icons.group),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Grup adı zorunludur'
                    : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Grubunuzu tanımlayan bir açıklama yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        ThemeConstants.borderRadiusMedium),
                  ),
                  filled: true,
                  fillColor: AppColorSchemes.lightBackground,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorSchemes.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ThemeConstants.borderRadiusMedium),
                          ),
                        ),
                        child: const Text('Grubu Oluştur',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ),
              const Spacer(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'İpucu: Grubunuzu ilgi çekici bir isim ve açıklama ile oluşturun daha fazla üye çekin!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColorSchemes.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      // Benzersiz heroTag eklendi ve _loading durumunda butonu tamamen kaldırdık
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
              heroTag: 'create_group_fab',
              child: const Icon(Icons.check),
              onPressed: _createGroup,
            ),
    );
  }
}
