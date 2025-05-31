import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/providers/data_provider.dart';
import 'package:keepsafe/utils/theme.dart';
import 'package:keepsafe/widgets/family_avatar.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  final FamilyMember? memberToEdit;

  const AddFamilyMemberScreen({
    Key? key,
    this.memberToEdit,
  }) : super(key: key);

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  String? _photoUrl;
  
  bool get _isEditing => widget.memberToEdit != null;

  // List of common relationships
  final List<String> _relationshipOptions = [
    'Spouse',
    'Parent',
    'Child',
    'Sibling',
    'Grandparent',
    'Relative',
    'Friend',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // Fill form with data from the family member being edited
      final member = widget.memberToEdit!;
      
      _nameController.text = member.name;
      _relationshipController.text = member.relationship;
      _photoUrl = member.photoUrl;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _saveFamily() async {
    if (_formKey.currentState!.validate()) {
      // Generate a default avatar URL if none exists
      String? avatarUrl = _photoUrl;
      if (avatarUrl == null || avatarUrl.isEmpty) {
        avatarUrl = _getAvatarUrl(_nameController.text);
      }
      
      final member = FamilyMember(
        id: _isEditing ? widget.memberToEdit!.id : null,
        name: _nameController.text,
        relationship: _relationshipController.text,
        photoUrl: avatarUrl,
      );
      
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      if (_isEditing) {
        await dataProvider.updateFamilyMember(member);
      } else {
        await dataProvider.addFamilyMember(member);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
  
  String _getAvatarUrl(String name) {
    // Properly encode the name for URL
    final encodedName = Uri.encodeComponent(name.trim());
    return 'https://ui-avatars.com/api/?name=$encodedName&size=200&background=random';
  }
  
  Future<void> _selectPhoto() async {
    final ImagePicker picker = ImagePicker();
    
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Photo'),
        content: const Text('Choose how you want to add a photo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('TAKE PHOTO'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('FROM GALLERY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
    
    if (source == null) return;
    
    try {
      // For now, let's use a placeholder image to avoid platform-specific issues
      if (source == ImageSource.camera) {
        setState(() {
          _photoUrl = _getAvatarUrl(_nameController.text);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera functionality will be available in the next update')),
        );
        return;
      }
      
      // For gallery selection, use a placeholder for now
      setState(() {
        _photoUrl = _getAvatarUrl(_nameController.text);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery selection will be available in the next update')),
      );
      
      // Commented out for now to avoid the platform exception
      /*
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      // Get the documents directory
      final Directory appDir = await path_provider.getApplicationDocumentsDirectory();
      final String familyImagesDir = path.join(appDir.path, 'family_images');
      
      // Create the directory if it doesn't exist
      final Directory familyDir = Directory(familyImagesDir);
      if (!await familyDir.exists()) {
        await familyDir.create(recursive: true);
      }
      
      // Generate a unique filename using timestamp and original file extension
      final String fileName = 'family_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final String localPath = path.join(familyImagesDir, fileName);
      
      // Copy the image to the app's documents directory
      final File localImage = File(localPath);
      await localImage.writeAsBytes(await image.readAsBytes());
      
      // Update state with the local file path
      setState(() {
        _photoUrl = localImage.path;
      });
      */
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select photo: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteMember() async {
    if (!_isEditing) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text(
          'Are you sure you want to delete ${_nameController.text}? '
          'This will also delete all credentials associated with this family member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.deleteFamilyMember(widget.memberToEdit!.id!);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Family Member' : 'Add Family Member'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMember,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPhotoSelector(),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildRelationshipField(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveFamily,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoSelector() {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Family';
    
    return Column(
      children: [
        GestureDetector(
          onTap: _selectPhoto,
          child: hasPhoto
              ? FamilyAvatar(
                  name: displayName,
                  photoUrl: _photoUrl,
                  size: 100,
                )
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _selectPhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
        ),
      ],
    );
  }
  
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Name',
        hintText: 'Enter full name',
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
        }
        return null;
      },
      onChanged: (_) {
        // If we have a generated photo URL, update it when the name changes
        if (_photoUrl != null && _photoUrl!.contains('ui-avatars.com')) {
          setState(() {
            _photoUrl = _getAvatarUrl(_nameController.text);
          });
        }
      },
    );
  }
  
  Widget _buildRelationshipField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _relationshipController,
          decoration: const InputDecoration(
            labelText: 'Relationship',
            hintText: 'E.g., Spouse, Parent, Child',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter relationship';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _relationshipOptions.map((relationship) {
            return ActionChip(
              label: Text(relationship),
              onPressed: () {
                setState(() {
                  _relationshipController.text = relationship;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
} 