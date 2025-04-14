import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/providers/data_provider.dart';

class AddCredentialScreen extends StatefulWidget {
  final Credential? credentialToEdit;

  const AddCredentialScreen({
    Key? key,
    this.credentialToEdit,
  }) : super(key: key);

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fieldsControllers = <String, TextEditingController>{};
  final _fieldNameControllers = <String, TextEditingController>{};
  
  String _selectedCategory = Credential.CATEGORY_WEBSITE;
  int? _selectedFamilyMemberId;
  final List<Map<String, String>> _dynamicFields = [];
  
  bool get _isEditing => widget.credentialToEdit != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // Fill form with data from the credential being edited
      final credential = widget.credentialToEdit!;
      
      _titleController.text = credential.title;
      _selectedCategory = credential.category;
      _selectedFamilyMemberId = credential.familyMemberId;
      
      // Setup dynamic fields based on credential type
      credential.fields.forEach((key, value) {
        _fieldsControllers[key] = TextEditingController(text: value);
        _fieldNameControllers[key] = TextEditingController(text: key);
        _dynamicFields.add({'key': key, 'value': value});
      });
    } else {
      // Initialize with default fields based on category
      _updateDynamicFields();
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _fieldsControllers.values) {
      controller.dispose();
    }
    for (var controller in _fieldNameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _updateDynamicFields() {
    _dynamicFields.clear();
    
    // Create default fields based on selected category
    switch (_selectedCategory) {
      case Credential.CATEGORY_BANK:
        _dynamicFields.addAll([
          {'key': 'Account Number', 'value': ''},
          {'key': 'IFSC Code', 'value': ''},
          {'key': 'Account Type', 'value': ''},
          {'key': 'Branch', 'value': ''},
        ]);
        break;
      case Credential.CATEGORY_CARD:
        _dynamicFields.addAll([
          {'key': 'Card Number', 'value': ''},
          {'key': 'Name on Card', 'value': ''},
          {'key': 'Expiry Date', 'value': ''},
          {'key': 'CVV', 'value': ''},
          {'key': 'PIN', 'value': ''},
        ]);
        break;
      case Credential.CATEGORY_WEBSITE:
        _dynamicFields.addAll([
          {'key': 'Username/Email', 'value': ''},
          {'key': 'Password', 'value': ''},
          {'key': 'Website URL', 'value': ''},
        ]);
        break;
      case Credential.CATEGORY_APP:
        _dynamicFields.addAll([
          {'key': 'Username/Email', 'value': ''},
          {'key': 'Password', 'value': ''},
          {'key': 'App Name', 'value': ''},
        ]);
        break;
      case Credential.CATEGORY_OTHER:
        _dynamicFields.addAll([
          {'key': 'Name', 'value': ''},
          {'key': 'Value', 'value': ''},
        ]);
        break;
    }
    
    // Initialize controllers for new fields
    for (var field in _dynamicFields) {
      final key = field['key']!;
      if (!_fieldsControllers.containsKey(key)) {
        _fieldsControllers[key] = TextEditingController(text: field['value']);
      }
      if (!_fieldNameControllers.containsKey(key)) {
        _fieldNameControllers[key] = TextEditingController(text: key);
      }
    }
  }
  
  void _addNewField() {
    setState(() {
      final newKey = 'Field ${_dynamicFields.length + 1}';
      _dynamicFields.add({'key': newKey, 'value': ''});
      _fieldsControllers[newKey] = TextEditingController();
      _fieldNameControllers[newKey] = TextEditingController(text: newKey);
    });
  }
  
  void _removeField(int index) {
    // Get the key of the field we want to remove
    print('Before removal: $_dynamicFields');
    final key = _dynamicFields[index]['key']!;
    print('Removing field at index $index with key: $key');
    
    setState(() {
      // First dispose controller
      _fieldsControllers[key]?.dispose();
      // Remove controller from map
      _fieldsControllers.remove(key);
      // Remove the field from dynamic fields at the specific index
      _dynamicFields.removeAt(index);
    });
    
    print('After removal: $_dynamicFields');
  }
  
  Future<void> _saveCredential() async {
    if (_formKey.currentState!.validate()) {
      // Collect all field values
      final Map<String, String> fields = {};
      for (var field in _dynamicFields) {
        final key = field['key']!;
        fields[key] = _fieldsControllers[key]!.text;
      }
      
      // Create credential object
      final credential = Credential(
        id: _isEditing ? widget.credentialToEdit!.id : null,
        familyMemberId: _selectedFamilyMemberId,
        title: _titleController.text,
        category: _selectedCategory,
        fields: fields,
        createdAt: _isEditing ? widget.credentialToEdit!.createdAt : null,
        isFavorite: _isEditing ? widget.credentialToEdit!.isFavorite : false,
      );
      
      // Save to database via provider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      if (_isEditing) {
        await dataProvider.updateCredential(credential);
      } else {
        await dataProvider.addCredential(credential);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Credential' : 'Add Credential'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildFamilyMemberDropdown(),
              const SizedBox(height: 24),
              _buildFieldsSection(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCredential,
                child: Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }
  
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      value: _selectedCategory,
      items: Credential.CATEGORIES.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && value != _selectedCategory) {
          setState(() {
            _selectedCategory = value;
            if (!_isEditing) {
              _updateDynamicFields();
            }
          });
        }
      },
    );
  }
  
  Widget _buildFamilyMemberDropdown() {
    final dataProvider = Provider.of<DataProvider>(context);
    final familyMembers = dataProvider.familyMembers;
    
    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(
        labelText: 'Family Member',
        border: OutlineInputBorder(),
        hintText: 'Select family member (optional)',
      ),
      value: _selectedFamilyMemberId,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Me (Personal)'),
        ),
        ...familyMembers.map((member) {
          return DropdownMenuItem(
            value: member.id,
            child: Text(member.name),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedFamilyMemberId = value;
        });
      },
    );
  }
  
  Widget _buildFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fields',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _addNewField,
              icon: const Icon(Icons.add),
              label: const Text('Add Field'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(_dynamicFields.length, (index) {
            final field = _dynamicFields[index];
            final key = field['key']!;
            
            return Padding(
              key: ValueKey('field-$index-$key'),
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _fieldNameControllers[key],
                      decoration: const InputDecoration(
                        labelText: 'Field Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value != key) {
                          // Store the old controllers
                          final oldValueController = _fieldsControllers[key];
                          final oldNameController = _fieldNameControllers[key];
                          
                          // Update the field name in the dynamic fields list
                          _dynamicFields[index]['key'] = value;
                          
                          // Update the controllers map
                          _fieldsControllers[value] = oldValueController!;
                          _fieldNameControllers[value] = oldNameController!;
                          
                          // Remove old entries
                          _fieldsControllers.remove(key);
                          _fieldNameControllers.remove(key);
                          
                          // Update the controller text without triggering rebuild
                          _fieldNameControllers[value]?.text = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _fieldsControllers[key],
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: key.toLowerCase().contains('password') || 
                                  key.toLowerCase().contains('pin') ||
                                  key.toLowerCase().contains('cvv'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete field at position $index',
                    onPressed: () {
                      print('Deleting field at index $index: $key');
                      _removeField(index);
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
} 