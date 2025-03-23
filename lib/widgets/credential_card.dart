import 'package:flutter/material.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/utils/theme.dart';

class CredentialCard extends StatelessWidget {
  final Credential credential;
  final VoidCallback onTap;

  const CredentialCard({
    Key? key,
    required this.credential,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            credential.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (credential.isFavorite)
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      credential.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPreviewInfo(context),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    late IconData iconData;
    late Color iconColor;

    switch (credential.category) {
      case Credential.CATEGORY_BANK:
        iconData = Icons.account_balance;
        iconColor = Colors.blue;
        break;
      case Credential.CATEGORY_CARD:
        iconData = Icons.credit_card;
        iconColor = Colors.green;
        break;
      case Credential.CATEGORY_WEBSITE:
        iconData = Icons.language;
        iconColor = Colors.purple;
        break;
      case Credential.CATEGORY_APP:
        iconData = Icons.apps;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.lock;
        iconColor = AppTheme.primaryColor;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildPreviewInfo(BuildContext context) {
    final previewEntries = credential.fields.entries.take(2).toList();
    
    if (previewEntries.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: previewEntries.map((entry) {
        return Row(
          children: [
            Text(
              '${entry.key}: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _maskSensitiveInfo(entry.value),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }).toList(),
    );
  }

  String _maskSensitiveInfo(String value) {
    if (value.isEmpty) {
      return '';
    }
    
    // For short values, just show dots
    if (value.length <= 8) {
      return '••••••••';
    }
    
    // For longer values, show first 2 and last 2 characters
    return '${value.substring(0, 2)}••••${value.substring(value.length - 2)}';
  }
} 