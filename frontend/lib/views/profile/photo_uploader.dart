import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class ProfilePhotoUploader extends StatefulWidget {
  const ProfilePhotoUploader({super.key});

  @override
  State<ProfilePhotoUploader> createState() => _ProfilePhotoUploaderState();
}

class _ProfilePhotoUploaderState extends State<ProfilePhotoUploader> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      if (!mounted) return;
      _showMessage('Lütfen önce bir fotoğraf seçin');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final currentUser = await ServiceLocator.user.getCurrentUsername();
      if (currentUser == null) throw Exception('Kullanıcı bilgisi bulunamadı');

      final response = await ServiceLocator.profile.uploadProfileImage(
        _image!,
        currentUser,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Profil fotoğrafı başarıyla güncellendi', isError: false);
      } else {
        _showMessage(
          'Yükleme hatası: ${response.data?.toString() ?? 'Bilinmeyen hata'}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Hata oluştu: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : Icon(
                    Icons.account_circle,
                    size: 150,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGalleryButton(theme),
            SizedBox(width: 16),
            _buildUploadButton(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildGalleryButton(ThemeData theme) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.photo_library),
      label: const Text('Galeri'),
      onPressed: _pickImage,
      style: ElevatedButton.styleFrom(
        padding: ThemeConstants.paddingMedium,
      ),
    );
  }

  Widget _buildUploadButton(ThemeData theme) {
    return ElevatedButton.icon(
      icon: _isUploading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.cloud_upload),
      label: Text(_isUploading ? 'Yükleniyor' : 'Yükle'),
      onPressed: _isUploading ? null : _uploadImage,
      style: ElevatedButton.styleFrom(
        padding: ThemeConstants.paddingMedium,
        backgroundColor: _isUploading
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
