import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/providers/data_provider.dart';

class AddCredentialScreen extends StatefulWidget {
  final Credential? credentialToEdit;
  final int? selectedFamilyMemberId;

  const AddCredentialScreen({
    Key? key,
    this.credentialToEdit,
    this.selectedFamilyMemberId,
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
      // Fill form with data from the credential being edited
      final credential = widget.credentialToEdit!;
      
      _titleController.text = credential.title;
      _selectedCategory = credential.category;
      _selectedFamilyMemberId = credential.familyMemberId;
      
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
    } else {
      // Initialize with default fields based on category
      _selectedFamilyMemberId = widget.selectedFamilyMemberId;
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

  void _addNewField() async {
    // Show dialog to ask user about field type
    final String? fieldType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Field'),
          content: const Text('What type of field would you like to add?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('normal'),
              child: const Text('Normal Field'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('password'),
              child: const Text('Password Field'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (fieldType == null) return; // User cancelled

    setState(() {
      final newKey = fieldType == 'password' 
          ? 'Password ${_dynamicFields.length + 1}'
          : 'Field ${_dynamicFields.length + 1}';
      
      _dynamicFields.add({'key': newKey, 'value': ''});
      _fieldsControllers[newKey] = TextEditingController();
      _fieldNameControllers[newKey] = TextEditingController(text: newKey);
      _fieldNameFocusNodes[newKey] = FocusNode();
      
      // Initialize password field state if it's a password field
      if (fieldType == 'password') {
        _showPasswordStates[newKey] = false;
      }
    });

    // Focus on the newly created field name after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newKey = _dynamicFields.last['key']!;
      _fieldNameFocusNodes[newKey]?.requestFocus();
    });
  }

  void _removeField(int index) {
    final key = _dynamicFields[index]['key']!;
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
    }
  }

  Future<void> _saveCredential() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Update any pending field name changes
        for (int i = 0; i < _dynamicFields.length; i++) {
          final field = _dynamicFields[i];
          final oldKey = field['key']!;
          final newKey = _fieldNameControllers[oldKey]?.text ?? oldKey;
          
          if (newKey != oldKey) {
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
        
        // Save to database via provider
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        if (_isEditing) {
          await dataProvider.updateCredential(credential);
        } else {
          await dataProvider.addCredential(credential);
        }
        
        Navigator.pop(context);
      } catch (e, stackTrace) {
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
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBasicInfoCard(),
                const SizedBox(height: 24),
                _buildFieldsSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: isDark ? Colors.black.withOpacity(0.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildFamilyMemberDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Title',
        hintText: 'Enter a title for this credential',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.title),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
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
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.category),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      value: _selectedCategory,
      items: Credential.CATEGORIES.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            overflow: TextOverflow.ellipsis,
          ),
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
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Family Member',
        hintText: 'Select family member (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.person),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      value: _selectedFamilyMemberId,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text(
            'Me (Personal)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...familyMembers.map((member) {
          return DropdownMenuItem(
            value: member.id,
            child: Text(
              member.name,
              overflow: TextOverflow.ellipsis,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 4 : 2,
      shadowColor: isDark ? Colors.black.withOpacity(0.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fields',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _addNewField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: List.generate(_dynamicFields.length, (index) {
                final field = _dynamicFields[index];
                final key = field['key']!;
                final isPassword = _isPasswordField(key);
                
                return Card(
                  elevation: isDark ? 3 : 1,
                  shadowColor: isDark ? Colors.black.withOpacity(0.4) : null,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fieldNameControllers[key],
                                focusNode: _fieldNameFocusNodes[key],
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Field Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.label),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                ),
                                onEditingComplete: () {
                                  final newKey = _fieldNameControllers[key]?.text ?? key;
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
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Theme.of(context).colorScheme.error,
                              tooltip: 'Delete field',
                              onPressed: () => _removeField(index),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fieldsControllers[key],
                          decoration: InputDecoration(
                            labelText: 'Value',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.edit),
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
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          obscureText: isPassword && !(_showPasswordStates[key] ?? false),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveCredential,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isEditing ? Icons.save : Icons.add_circle_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'Update' : 'Save',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 