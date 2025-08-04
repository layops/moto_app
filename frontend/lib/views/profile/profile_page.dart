import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/widgets/navigations/main_wrapper.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final void Function(File)? onImageUploaded;

  const ProfilePage({
    super.key,
    this.onImageUploaded,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      widget.onImageUploaded?.call(_imageFile!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yükleme hatası: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.findAncestorWidgetOfExactType<MainWrapper>()?.email ??
        'Misafir';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage:
                      _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? Icon(
                          Icons.account_circle,
                          size: 120,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                FloatingActionButton.small(
                  onPressed: _pickImage,
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              email,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 40),
            if (_imageFile != null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadImage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isLoading ? 'Yükleniyor...' : 'Fotoğrafı Kaydet'),
              ),
          ],
        ),
      ),
    );
  }
}
