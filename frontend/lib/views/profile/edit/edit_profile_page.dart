import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfilePage({super.key, required this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _motorcycleModelController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.initialData['display_name'] ?? '');
    _bioController =
        TextEditingController(text: widget.initialData['bio'] ?? '');
    _motorcycleModelController = TextEditingController(
        text: widget.initialData['motorcycle_model'] ?? '');
    _locationController =
        TextEditingController(text: widget.initialData['location'] ?? '');
    _websiteController =
        TextEditingController(text: widget.initialData['website'] ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _motorcycleModelController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final updatedData = {
          'display_name': _displayNameController.text.trim(),
          'bio': _bioController.text.trim(),
          'motorcycle_model': _motorcycleModelController.text.trim(),
          'location': _locationController.text.trim(),
          'website': _websiteController.text.trim(),
        };

        final response =
            await ServiceLocator.profile.updateProfile(updatedData);

        if (response.statusCode == 200) {
          if (!mounted) return;
          Navigator.pop(context, updatedData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Güncelleme hatası: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        String errorMessage = 'Kaydetme hatası: $e';
        if (e.toString().contains('Oturum süresi doldu')) {
          errorMessage = 'Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.';

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            }
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  String? _validateWebsite(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    if (!urlPattern.hasMatch(value)) {
      return 'Geçerli bir URL girin (örn: https://example.com)';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > 160) {
      return 'Bio 160 karakterden uzun olamaz';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Kaydet',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Görünen İsim',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  hintText: 'Görünen isminiz',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'Görünen isim'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hakkımda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 160,
                decoration: const InputDecoration(
                  hintText: 'Kendinizden bahsedin',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: _validateBio,
              ),
              const SizedBox(height: 16),
              const Text(
                'Motosiklet Modeli',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motorcycleModelController,
                decoration: const InputDecoration(
                  hintText: 'Motosiklet modeliniz',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Bulunduğunuz şehir',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Web Sitesi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  hintText: 'Web siteniz veya sosyal medya linki',
                  border: OutlineInputBorder(),
                ),
                validator: _validateWebsite,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Profili Kaydet',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
