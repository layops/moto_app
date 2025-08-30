import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfilePage({super.key, required this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _motorController;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.initialData['email'] ?? '');
    _locationController =
        TextEditingController(text: widget.initialData['location'] ?? '');
    _motorController =
        TextEditingController(text: widget.initialData['motor'] ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _locationController.dispose();
    _motorController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'email': _emailController.text,
        'location': _locationController.text,
        'motor': _motorController.text,
      };
      Navigator.pop(context, updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email girin';
                  if (!value.contains('@')) return 'Geçerli email girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motorController,
                decoration: const InputDecoration(
                  labelText: 'Motor Modeli',
                  prefixIcon: Icon(Icons.motorcycle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
