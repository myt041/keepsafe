import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/providers/data_provider.dart';
import 'package:keepsafe/screens/credentials/add_credential_screen.dart';
import 'package:keepsafe/utils/theme.dart';

class CredentialDetailsScreen extends StatefulWidget {
  final Credential credential;

  const CredentialDetailsScreen({
    Key? key,
    required this.credential,
  }) : super(key: key);

  @override
  State<CredentialDetailsScreen> createState() => _CredentialDetailsScreenState();
}

class _CredentialDetailsScreenState extends State<CredentialDetailsScreen> {
  late Credential _credential;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _credential = widget.credential;
  }
  
  void _editCredential() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCredentialScreen(
          credentialToEdit: _credential,
        ),
      ),
    ).then((_) {
      // Refresh credential data after edit
      _refreshCredential();
    });
  }
  
  Future<void> _refreshCredential() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    // Find the updated credential in the provider
    final credentials = dataProvider.credentials;
    final updatedCredential = credentials.firstWhere(
      (c) => c.id == _credential.id,
      orElse: () => _credential,
    );
    
    setState(() {
      _credential = updatedCredential;
      _isLoading = false;
    });
  }
  
  Future<void> _toggleFavorite() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.toggleFavorite(_credential);
    await _refreshCredential();
  }
  
  Future<void> _deleteCredential() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: const Text(
          'Are you sure you want to delete this credential? This action cannot be undone.',
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
      await dataProvider.deleteCredential(_credential.id!);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
  
  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential Details'),
        actions: [
          IconButton(
            icon: Icon(
              _credential.isFavorite ? Icons.star : Icons.star_border,
              color: _credential.isFavorite ? Colors.yellow : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCredential,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCredential,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFieldsList(),
                  const SizedBox(height: 24),
                  _buildMetadata(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildHeader() {
    final dataProvider = Provider.of<DataProvider>(context);
    String ownerName = 'Me';
    
    if (_credential.familyMemberId != null) {
      final familyMember = dataProvider.familyMembers.firstWhere(
        (m) => m.id == _credential.familyMemberId,
        orElse: () => FamilyMember(name: 'Unknown', relationship: ''),
      );
      ownerName = familyMember.name;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _credential.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Chip(
              label: Text(_credential.category),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('Owner: $ownerName'),
              backgroundColor: AppTheme.accentColor.withOpacity(0.1),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFieldsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...(_credential.fields.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;
          final isSecret = key.toLowerCase().contains('password') || 
                          key.toLowerCase().contains('pin') ||
                          key.toLowerCase().contains('cvv');
          
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: isSecret 
                            ? _buildSecretField(value)
                            : Text(
                                value,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(value),
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList()),
      ],
    );
  }
  
  Widget _buildSecretField(String value) {
    return _SecretFieldWidget(value: value);
  }
  
  Widget _buildMetadata() {
    final createdAt = _formatDate(_credential.createdAt);
    final updatedAt = _formatDate(_credential.updatedAt);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Created'),
          subtitle: Text(createdAt),
          leading: const Icon(Icons.calendar_today),
        ),
        ListTile(
          title: const Text('Last updated'),
          subtitle: Text(updatedAt),
          leading: const Icon(Icons.update),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Stateful widget for handling secret fields
class _SecretFieldWidget extends StatefulWidget {
  final String value;
  
  const _SecretFieldWidget({required this.value});
  
  @override
  _SecretFieldWidgetState createState() => _SecretFieldWidgetState();
}

class _SecretFieldWidgetState extends State<_SecretFieldWidget> {
  bool _showSecret = false;
  
  @override
  Widget build(BuildContext context) {
    final obscured = '•' * widget.value.length;
    
    return Row(
      children: [
        Text(
          _showSecret ? widget.value : obscured,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        IconButton(
          icon: Icon(
            _showSecret ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _showSecret = !_showSecret),
          tooltip: _showSecret ? 'Hide' : 'Show',
        ),
      ],
    );
  }
} 