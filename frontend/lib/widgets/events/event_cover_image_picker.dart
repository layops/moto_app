import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EventCoverImagePicker extends StatelessWidget {
  final File? coverImageFile;
  final void Function(File) onPick;

  const EventCoverImagePicker(
      {super.key, this.coverImageFile, required this.onPick});

  Future<void> _pickImage(BuildContext context) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) onPick(File(pickedFile.path));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cover Image',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
              image: coverImageFile != null
                  ? DecorationImage(
                      image: FileImage(coverImageFile!), fit: BoxFit.cover)
                  : null,
            ),
            child: coverImageFile == null
                ? const Center(
                    child:
                        Icon(Icons.cloud_upload, size: 40, color: Colors.grey))
                : null,
          ),
        ),
      ],
    );
  }
}
