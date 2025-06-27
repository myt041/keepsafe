import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/providers/data_provider.dart';
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
      // Use null for photoUrl to let FamilyAvatar handle initials generation
      final member = FamilyMember(
        id: _isEditing ? widget.memberToEdit!.id : null,
        name: _nameController.text,
        relationship: _relationshipController.text,
        photoUrl: _photoUrl, // Keep existing photo if available, otherwise null
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
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Family';
    
    return Column(
      children: [
        GestureDetector(
          // onTap: _selectPhoto,
          child: FamilyAvatar(
            name: displayName,
            photoUrl: _photoUrl,
            size: 100,
          ),
        ),
        const SizedBox(height: 8),
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
        // Trigger rebuild to update the avatar display
        setState(() {});
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