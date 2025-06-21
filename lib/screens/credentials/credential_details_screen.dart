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
      _refreshCredential();
    });
  }
  
  Future<void> _refreshCredential() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(
              _credential.isFavorite ? Icons.star : Icons.star_border,
              color: _credential.isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: _credential.isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCredential,
            tooltip: 'Edit credential',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteCredential,
            tooltip: 'Delete credential',
          ),
        ],
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
        child: _isLoading
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
    
    return Card(
      elevation: 2,
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
                  _getCategoryIcon(_credential.category),
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _credential.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(_credential.category),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  avatar: Icon(
                    _getCategoryIcon(_credential.category),
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Chip(
                  label: Text('Owner: $ownerName'),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                  avatar: const Icon(
                    Icons.person_outline,
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFieldsList() {
    return Card(
      elevation: 2,
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
                  Icons.list_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
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
                          Icon(
                            _getFieldIcon(key),
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            key,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      isSecret 
                          ? _buildSecretField(value)
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    value,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_outlined),
                                  onPressed: () => _copyToClipboard(value),
                                  tooltip: 'Copy to clipboard',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    padding: const EdgeInsets.all(12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecretField(String value) {
    return _SecretFieldWidget(value: value);
  }
  
  Widget _buildMetadata() {
    final createdAt = _formatDate(_credential.createdAt);
    final updatedAt = _formatDate(_credential.updatedAt);
    
    return Card(
      elevation: 2,
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
                  'Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              icon: Icons.calendar_today,
              title: 'Created',
              subtitle: createdAt,
            ),
            const Divider(),
            _buildInfoTile(
              icon: Icons.update,
              title: 'Last updated',
              subtitle: updatedAt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case Credential.CATEGORY_WEBSITE:
        return Icons.language;
      case Credential.CATEGORY_APP:
        return Icons.phone_android;
      case Credential.CATEGORY_BANK:
        return Icons.account_balance;
      case Credential.CATEGORY_CARD:
        return Icons.credit_card;
      default:
        return Icons.star;
    }
  }

  IconData _getFieldIcon(String fieldName) {
    final lowerFieldName = fieldName.toLowerCase();
    if (lowerFieldName.contains('password')) return Icons.lock;
    if (lowerFieldName.contains('email')) return Icons.email;
    if (lowerFieldName.contains('username')) return Icons.person;
    if (lowerFieldName.contains('url')) return Icons.link;
    if (lowerFieldName.contains('phone')) return Icons.phone;
    if (lowerFieldName.contains('pin')) return Icons.pin;
    if (lowerFieldName.contains('cvv')) return Icons.security;
    return Icons.info;
  }
}

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
        Expanded(
          child: Text(
            _showSecret ? widget.value : obscured,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        IconButton(
          icon: Icon(
            _showSecret ? Icons.visibility_off : Icons.visibility,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => setState(() => _showSecret = !_showSecret),
          tooltip: _showSecret ? 'Hide' : 'Show',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Copied to clipboard'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Copy to clipboard',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
} 
