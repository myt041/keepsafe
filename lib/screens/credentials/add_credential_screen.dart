import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/models/credential.dart';
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
  final _showPasswordStates = <String, bool>{};
  final _fieldNameFocusNodes = <String, FocusNode>{};
  final List<Map<String, String>> _dynamicFields = [];
  
  String _selectedCategory = Credential.CATEGORY_WEBSITE;
  int? _selectedFamilyMemberId;
  bool get _isEditing => widget.credentialToEdit != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      print('=== EDIT MODE INITIALIZATION ===');
      print('Credential to edit: ${widget.credentialToEdit?.toMap()}');
      // Fill form with data from the credential being edited
      final credential = widget.credentialToEdit!;
      
      _titleController.text = credential.title;
      _selectedCategory = credential.category;
      _selectedFamilyMemberId = credential.familyMemberId;
      
      print('Initialized with:');
      print('- Title: ${credential.title}');
      print('- Category: ${credential.category}');
      print('- Family Member ID: ${credential.familyMemberId}');
      print('- Fields: ${credential.fields}');
      
      // Setup dynamic fields based on credential type
      if (credential.fields.isEmpty) {
        // If fields are empty, initialize with default fields for the category
        _updateDynamicFields();
      } else {
        credential.fields.forEach((key, value) {
          _fieldsControllers[key] = TextEditingController(text: value);
          _fieldNameControllers[key] = TextEditingController(text: key);
          _fieldNameFocusNodes[key] = FocusNode();
          _dynamicFields.add({'key': key, 'value': value});
          // Initialize show password state for password fields
          if (_isPasswordField(key)) {
            _showPasswordStates[key] = false;
          }
        });
      }
      print('Dynamic fields initialized: $_dynamicFields');
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
    for (var node in _fieldNameFocusNodes.values) {
      node.dispose();
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

  bool _isPasswordField(String fieldName) {
    final lowerFieldName = fieldName.toLowerCase();
    return lowerFieldName.contains('password') || 
           lowerFieldName.contains('pin') ||
           lowerFieldName.contains('cvv');
  }

  void _addNewField() {
    setState(() {
      final newKey = 'Field ${_dynamicFields.length + 1}';
      _dynamicFields.add({'key': newKey, 'value': ''});
      _fieldsControllers[newKey] = TextEditingController();
      _fieldNameControllers[newKey] = TextEditingController(text: newKey);
      _fieldNameFocusNodes[newKey] = FocusNode();
    });
  }

  void _removeField(int index) {
    final key = _dynamicFields[index]['key']!;
    print('Deleting field at index $index: $key');
    
    setState(() {
      _fieldsControllers[key]?.dispose();
      _fieldsControllers.remove(key);
      _dynamicFields.removeAt(index);
    });
  }

  void _updateFieldName(String oldKey, String newKey, int index) {
    if (newKey.isEmpty) {
      // If the new key is empty, revert to the old key
      _fieldNameControllers[oldKey]?.text = oldKey;
      return;
    }

    // Store the old controllers
    final oldValueController = _fieldsControllers[oldKey];
    final oldNameController = _fieldNameControllers[oldKey];
    final oldFocusNode = _fieldNameFocusNodes[oldKey];
    
    if (oldValueController != null && oldNameController != null && oldFocusNode != null) {
      setState(() {
        // Update the field name in the dynamic fields list
        _dynamicFields[index] = {
          'key': newKey,
          'value': oldValueController.text
        };
        
        // Update the controllers map
        _fieldsControllers[newKey] = oldValueController;
        _fieldNameControllers[newKey] = oldNameController;
        _fieldNameFocusNodes[newKey] = oldFocusNode;
        
        // Handle password field state
        if (_isPasswordField(oldKey)) {
          _showPasswordStates[newKey] = _showPasswordStates[oldKey] ?? false;
          _showPasswordStates.remove(oldKey);
        }
        
        // Remove old entries
        _fieldsControllers.remove(oldKey);
        _fieldNameControllers.remove(oldKey);
        _fieldNameFocusNodes.remove(oldKey);
      });
      
      print('=== FIELD NAME CHANGE ===');
      print('Old key: $oldKey');
      print('New value: $newKey');
      print('Current dynamic fields: $_dynamicFields');
      print('Updated controllers:');
      print('- Fields controllers: ${_fieldsControllers.keys}');
      print('- Name controllers: ${_fieldNameControllers.keys}');
    }
  }

  Future<void> _saveCredential() async {
    if (_formKey.currentState!.validate()) {
      try {
        print('=== SAVING CREDENTIAL ===');
        print('Is editing mode: $_isEditing');
        
        // Update any pending field name changes
        for (int i = 0; i < _dynamicFields.length; i++) {
          final field = _dynamicFields[i];
          final oldKey = field['key']!;
          final newKey = _fieldNameControllers[oldKey]?.text ?? oldKey;
          
          if (newKey != oldKey) {
            print('Updating field name before save: $oldKey -> $newKey');
            _updateFieldName(oldKey, newKey, i);
          }
        }
        
        // Collect all field values
        final Map<String, String> fields = {};
        for (var field in _dynamicFields) {
          final key = field['key']!;
          final controller = _fieldsControllers[key];
          if (controller != null) {
            fields[key] = controller.text;
          }
        }
        
        print('Collected fields: $fields');
        
        // Create credential object
        final now = DateTime.now();
        final credential = Credential(
          id: _isEditing ? widget.credentialToEdit!.id : null,
          familyMemberId: _selectedFamilyMemberId,
          title: _titleController.text,
          category: _selectedCategory,
          fields: fields,
          createdAt: _isEditing ? widget.credentialToEdit!.createdAt : now,
          updatedAt: now,
          isFavorite: _isEditing ? widget.credentialToEdit?.isFavorite ?? false : false,
        );
        
        print('Credential object created: ${credential.toMap()}');
        
        // Save to database via provider
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        if (_isEditing) {
          print('Updating existing credential...');
          await dataProvider.updateCredential(credential);
          print('Credential updated successfully');
        } else {
          print('Adding new credential...');
          await dataProvider.addCredential(credential);
          print('Credential added successfully');
        }
        
        Navigator.pop(context);
      } catch (e, stackTrace) {
        print('=== ERROR SAVING CREDENTIAL ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving credential: ${e.toString()}')),
        );
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
            final isPassword = _isPasswordField(key);
            
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
                      focusNode: _fieldNameFocusNodes[key],
                      decoration: const InputDecoration(
                        labelText: 'Field Name',
                        border: OutlineInputBorder(),
                      ),
                      onEditingComplete: () {
                        final newKey = _fieldNameControllers[key]?.text ?? key;
                        print('newKey:  newKey $newKey  old key $key');

                        if (newKey != key) {
                          _updateFieldName(key, newKey, index);
                        }
                      },
                      onFieldSubmitted: (value) {
                        if (value != key) {
                          _updateFieldName(key, value, index);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _fieldsControllers[key],
                      decoration: InputDecoration(
                        labelText: 'Value',
                        border: const OutlineInputBorder(),
                        suffixIcon: isPassword ? IconButton(
                          icon: Icon(
                            _showPasswordStates[key] ?? false
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPasswordStates[key] = !(_showPasswordStates[key] ?? false);
                            });
                          },
                        ) : null,
                      ),
                      obscureText: isPassword && !(_showPasswordStates[key] ?? false),
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