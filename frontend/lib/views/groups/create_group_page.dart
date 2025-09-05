// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\create_group_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imagePicker = ImagePicker();
  String _name = '';
  String _description = '';
  File? _selectedImage;
  bool _loading = false;
  String? _error;

  late GroupService _groupService;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(authService: widget.authService);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fotoğraf seçilirken hata oluştu: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fotoğraf çekilirken hata oluştu: $e';
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _groupService.createGroup(_name, _description, profilePicture: _selectedImage);
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
              
              // Profil Fotoğrafı Seçimi
              _buildProfilePictureSection(),
              const SizedBox(height: 20),
              
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

  Widget _buildProfilePictureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grup Profil Fotoğrafı',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColorSchemes.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Grubunuzu temsil eden bir fotoğraf seçin (opsiyonel)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColorSchemes.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_selectedImage != null) ...[
          // Seçilen fotoğrafı göster
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
              border: Border.all(color: AppColorSchemes.primaryColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _removeImage,
                        iconSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Fotoğraf seçme butonları
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeriden Seç'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Çek'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          Text(
            'Maksimum dosya boyutu: 5MB • Desteklenen formatlar: JPG, PNG, WebP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColorSchemes.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
