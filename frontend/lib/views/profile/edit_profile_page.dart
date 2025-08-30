import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfilePage({super.key, required this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lastController;
  late TextEditingController _autographModelController;
  late TextEditingController _gulagStyleController;
  late TextEditingController _lucertoPseudoController;
  late TextEditingController _socialMediaController;

  // Justification preferences
  bool _actualization = false;
  bool _learnPlatform = false;
  bool _changeActivities = false;
  bool _justifications = false;
  bool _privacySettings = false;
  bool _showLocations = false;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _lastController =
        TextEditingController(text: widget.initialData['last'] ?? '');
    _autographModelController =
        TextEditingController(text: widget.initialData['autographModel'] ?? '');
    _gulagStyleController =
        TextEditingController(text: widget.initialData['gulagStyle'] ?? '');
    _lucertoPseudoController =
        TextEditingController(text: widget.initialData['lucertoPseudo'] ?? '');
    _socialMediaController =
        TextEditingController(text: widget.initialData['socialMedia'] ?? '');

    // Initialize preferences
    _actualization = widget.initialData['actualization'] ?? false;
    _learnPlatform = widget.initialData['learnPlatform'] ?? false;
    _changeActivities = widget.initialData['changeActivities'] ?? false;
    _justifications = widget.initialData['justifications'] ?? false;
    _privacySettings = widget.initialData['privacySettings'] ?? false;
    _showLocations = widget.initialData['showLocations'] ?? false;
    _showNotes = widget.initialData['showNotes'] ?? false;
  }

  @override
  void dispose() {
    _lastController.dispose();
    _autographModelController.dispose();
    _gulagStyleController.dispose();
    _lucertoPseudoController.dispose();
    _socialMediaController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'last': _lastController.text,
        'autographModel': _autographModelController.text,
        'gulagStyle': _gulagStyleController.text,
        'lucertoPseudo': _lucertoPseudoController.text,
        'socialMedia': _socialMediaController.text,
        'actualization': _actualization,
        'learnPlatform': _learnPlatform,
        'changeActivities': _changeActivities,
        'justifications': _justifications,
        'privacySettings': _privacySettings,
        'showLocations': _showLocations,
        'showNotes': _showNotes,
      };
      Navigator.pop(context, updatedData);
    }
  }

  void _saveReference() {
    // This button can have a different function, like just printing data
    final data = {
      'last': _lastController.text,
      'autographModel': _autographModelController.text,
      'gulagStyle': _gulagStyleController.text,
      'lucertoPseudo': _lucertoPseudoController.text,
      'socialMedia': _socialMediaController.text,
      'actualization': _actualization,
      'learnPlatform': _learnPlatform,
      'changeActivities': _changeActivities,
      'justifications': _justifications,
      'privacySettings': _privacySettings,
      'showLocations': _showLocations,
      'showNotes': _showNotes,
    };
    debugPrint('Save Reference data: $data');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference saved locally')),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateSocialMedia(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('@')) {
      return 'Instagram handle must start with @';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editor Zone
              const Text(
                'Editor Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Status: Name',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Last
              const Text(
                'Last',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                controller: _lastController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your last name',
                ),
                validator: (value) => _validateRequired(value, 'Last name'),
              ),
              const SizedBox(height: 16),

              // Autograph Model
              const Text(
                'Autograph Model',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                controller: _autographModelController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter autograph model',
                ),
                validator: (value) =>
                    _validateRequired(value, 'Autograph model'),
              ),
              const SizedBox(height: 16),

              // Gulag Style
              const Text(
                'Gulag Style',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                controller: _gulagStyleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter gulag style',
                ),
                validator: (value) => _validateRequired(value, 'Gulag style'),
              ),
              const SizedBox(height: 16),

              // Lucerto Pseudo
              const Text(
                'Lucerto Pseudo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                controller: _lucertoPseudoController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter lucerto pseudo',
                ),
                validator: (value) =>
                    _validateRequired(value, 'Lucerto pseudo'),
              ),
              const SizedBox(height: 16),

              // Social Media (Instagram)
              const Text(
                'Social Media (Instagram)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                controller: _socialMediaController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '@username',
                  prefixText: '@',
                ),
                validator: _validateSocialMedia,
              ),
              const SizedBox(height: 24),

              // Set
              const Text(
                'Set',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              const SizedBox(height: 24),

              // Justification Preferences
              const Text(
                'Justification Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Actualization
              SwitchListTile(
                title: const Text(
                  'Actualization',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Create a collection of text messages.'),
                value: _actualization,
                onChanged: (value) {
                  setState(() {
                    _actualization = value;
                  });
                },
              ),

              // Learn the platform
              SwitchListTile(
                title: const Text(
                  'Learn the platform',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Get on HTML videos across translations.'),
                value: _learnPlatform,
                onChanged: (value) {
                  setState(() {
                    _learnPlatform = value;
                  });
                },
              ),

              // Change Activities
              SwitchListTile(
                title: const Text(
                  'Change Activities',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Try to describe any space questions.'),
                value: _changeActivities,
                onChanged: (value) {
                  setState(() {
                    _changeActivities = value;
                  });
                },
              ),

              // Justifications
              SwitchListTile(
                title: const Text(
                  'Justifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Make the information about the topic.'),
                value: _justifications,
                onChanged: (value) {
                  setState(() {
                    _justifications = value;
                  });
                },
              ),

              // Privacy Settings
              SwitchListTile(
                title: const Text(
                  'Privacy Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                    'Show dialog details. Ensure creating my input dialog data below.'),
                value: _privacySettings,
                onChanged: (value) {
                  setState(() {
                    _privacySettings = value;
                  });
                },
              ),

              // Show Locations
              SwitchListTile(
                title: const Text(
                  'Show Locations',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Remove existing my input messages.'),
                value: _showLocations,
                onChanged: (value) {
                  setState(() {
                    _showLocations = value;
                  });
                },
              ),

              // Show Notes
              SwitchListTile(
                title: const Text(
                  'Show Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Identify existing my input notes.'),
                value: _showNotes,
                onChanged: (value) {
                  setState(() {
                    _showNotes = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Submit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saveReference,
                      child: const Text('Save Reference'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
