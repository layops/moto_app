import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:motoapp_frontend/services/api_service.dart';

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
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final apiService = await ApiService.create();

      FormData formData = FormData.fromMap({
        "profile_image": await MultipartFile.fromFile(_image!.path,
            filename: _image!.path.split('/').last),
      });

      final response = await apiService.post('profile/upload-photo/', formData);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf başarıyla yüklendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_image != null)
          Image.file(_image!, width: 150, height: 150, fit: BoxFit.cover)
        else
          const Icon(Icons.account_circle, size: 150),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Fotoğraf Seç'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadImage,
          child: _isUploading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Fotoğrafı Yükle'),
        ),
      ],
    );
  }
}
