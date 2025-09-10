// create_post_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/post/post_service.dart';

class CreatePostPage extends StatefulWidget {
  final VoidCallback? onPostCreated;
  final int? groupPk;
  final VoidCallback? onProfileRefresh; // Yeni eklenen callback

  const CreatePostPage({
    super.key,
    this.onPostCreated,
    this.groupPk,
    this.onProfileRefresh, // Constructor'a ekle
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedFile;
  bool _loading = false;
  String? _error;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    // Content validation
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _error = 'Gönderi içeriği boş olamaz.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final postService = Provider.of<PostService>(context, listen: false);
      await postService.createPost(
        content: content,
        file: _selectedFile,
        groupPk: widget.groupPk,
      );

      // Callback'leri çağır
      if (widget.onPostCreated != null) {
        print('CreatePostPage - onPostCreated callback çağrılıyor');
        widget.onPostCreated!();
      }
      if (widget.onProfileRefresh != null) {
        print('CreatePostPage - onProfileRefresh callback çağrılıyor');
        widget.onProfileRefresh!(); // Profili yenile
      }

      // ignore: use_build_context_synchronously
      print('CreatePostPage - Navigator.pop ile true döndürülüyor');
      Navigator.pop(context, true); // Success result döndür
    } catch (e) {
      setState(() {
        // Hata mesajını daha kullanıcı dostu hale getir
        String errorMessage = e.toString();
        if (errorMessage.contains('INTEGRITY_ERROR')) {
          _error = 'Veritabanı hatası: Lütfen tekrar deneyin.';
        } else if (errorMessage.contains('Authentication')) {
          _error = 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
        } else if (errorMessage.contains('Network')) {
          _error = 'İnternet bağlantınızı kontrol edin.';
        } else {
          _error = errorMessage.replaceFirst('Exception: ', '');
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
      appBar: AppBar(title: const Text('Yeni Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Post içeriğini yazın...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_selectedFile != null) Image.file(_selectedFile!, height: 150),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  label: const Icon(Icons.image),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Paylaş'),
                  ),
          ],
        ),
      ),
    );
  }
}
