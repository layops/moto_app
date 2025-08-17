// create_post_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'post_service.dart';

class CreatePostPage extends StatefulWidget {
  final VoidCallback? onPostCreated;
  final int? groupPk; // groupPk'yi null olabilecek şekilde ekleyin

  const CreatePostPage({super.key, this.onPostCreated, this.groupPk}); // Constructor'a ekleyin

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final postService = Provider.of<PostService>(context, listen: false);
      await postService.createPost(
        content: _contentController.text,
        file: _selectedFile,
        groupPk: widget.groupPk, // Widget'tan gelen groupPk'yı iletin
      );

      if (widget.onPostCreated != null) widget.onPostCreated!();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
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
                  icon: const Icon(Icons.image),
                  label: const Text('Medya Seç'),
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