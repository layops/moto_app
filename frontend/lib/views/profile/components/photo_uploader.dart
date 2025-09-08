import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

enum PhotoType { profile, cover }

class ProfilePhotoUploader extends StatefulWidget {
  final PhotoType type;
  final Function(File)? onImageSelected;
  final Function(bool)? onUploadStateChanged;
  final Function(Map<String, dynamic>)? onUploadSuccess;
  final String? networkImageUrl;

  const ProfilePhotoUploader({
    super.key,
    required this.type,
    this.onImageSelected,
    this.onUploadStateChanged,
    this.onUploadSuccess,
    this.networkImageUrl,
  });

  @override
  State<ProfilePhotoUploader> createState() => _ProfilePhotoUploaderState();
}

class _ProfilePhotoUploaderState extends State<ProfilePhotoUploader> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() => _image = File(pickedFile.path));
        widget.onImageSelected?.call(_image!);
      }
    } catch (e) {
      _showMessage('Resim seçilirken hata oluştu: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() => _image = File(pickedFile.path));
        widget.onImageSelected?.call(_image!);
      }
    } catch (e) {
      _showMessage('Fotoğraf çekilirken hata oluştu: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
      widget.onUploadStateChanged?.call(true);
    });

    try {
      late final response;

      if (widget.type == PhotoType.profile) {
        response = await ServiceLocator.profile.uploadProfileImage(_image!);
      } else {
        response = await ServiceLocator.profile.uploadCoverImage(_image!);
      }

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('user')) {
          final userData = responseData['user'];
          await ServiceLocator.storage.saveProfileData(userData);
          widget.onUploadSuccess?.call(userData);
        }

        _showMessage(
          widget.type == PhotoType.profile
              ? 'Profil fotoğrafı başarıyla güncellendi'
              : 'Kapak fotoğrafı başarıyla güncellendi',
          isError: false,
        );
        
        // Başarılı yükleme sonrası dialog'u kapat
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showMessage(
          widget.type == PhotoType.profile
              ? 'Profil fotoğrafı yükleme hatası: ${response.statusCode}'
              : 'Kapak fotoğrafı yükleme hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      String errorMessage = 'Bilinmeyen bir hata oluştu';
      
      if (e.toString().contains('Oturum süresi doldu')) {
        errorMessage = 'Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.';
      } else if (e.toString().contains('Dosya boyutu')) {
        errorMessage = 'Dosya boyutu çok büyük. Lütfen daha küçük bir resim seçin.';
      } else if (e.toString().contains('Geçersiz dosya formatı')) {
        errorMessage = 'Desteklenmeyen dosya formatı. JPEG, PNG, GIF veya WebP kullanın.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'İnternet bağlantınızı kontrol edin.';
      }
      
      _showMessage(
        widget.type == PhotoType.profile
            ? 'Profil fotoğrafı yükleme hatası: $errorMessage'
            : 'Kapak fotoğrafı yükleme hatası: $errorMessage',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          widget.onUploadStateChanged?.call(false);
        });
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
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _removeImage() {
    setState(() => _image = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ImageProvider? avatarImage;
    if (_image != null) {
      avatarImage = FileImage(_image!);
    } else if (widget.networkImageUrl != null &&
        widget.networkImageUrl!.isNotEmpty) {
      avatarImage = NetworkImage(widget.networkImageUrl!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: ClipOval(
                child: avatarImage != null
                    ? Image(image: avatarImage, fit: BoxFit.cover)
                    : Icon(Icons.account_circle,
                        size: 150,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
            if (_image != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.error,
                  child: IconButton(
                    icon: Icon(Icons.close,
                        size: 18, color: theme.colorScheme.onError),
                    onPressed: _removeImage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCameraButton(theme),
            const SizedBox(width: 12),
            _buildGalleryButton(theme),
            const SizedBox(width: 12),
            if (_image != null) _buildUploadButton(theme),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: theme.colorScheme.surface,
            color: theme.colorScheme.primary,
          ),
        ],
      ],
    );
  }

  Widget _buildCameraButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _takePhoto,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child:
          Icon(Icons.camera_alt, size: 24, color: theme.colorScheme.onPrimary),
    );
  }

  Widget _buildGalleryButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _pickImage,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Icon(Icons.photo_library,
          size: 24, color: theme.colorScheme.onPrimary),
    );
  }

  Widget _buildUploadButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isUploading ? null : _uploadImage,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: _isUploading
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      child: _isUploading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Icon(Icons.cloud_upload, size: 24),
    );
  }
}
