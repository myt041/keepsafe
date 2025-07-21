import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KeepSafe Terms of Service',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By downloading and using KeepSafe, you agree to these Terms of Service.',
            ),

            _buildSection(
              context,
              '2. App Usage',
              '• KeepSafe is designed for personal and family use\n'
                  '• You are responsible for the security of your PIN and device\n'
                  '• You must not use the app for illegal purposes',
            ),

            _buildSection(
              context,
              '3. Subscription Services',
              '• Pro subscriptions are billed monthly or yearly\n'
                  '• Subscriptions automatically renew unless cancelled\n'
                  '• Prices may change with notice\n'
                  '• No refunds for partial periods',
            ),

            _buildSection(
              context,
              '4. Data and Privacy',
              '• Your data is stored locally on your device\n'
                  '• We do not access your stored information\n'
                  '• You are responsible for backing up your data\n'
                  '• See our Privacy Policy for details',
            ),

            _buildSection(
              context,
              '5. Limitations',
              '• We provide the app "as is"\n'
                  '• We are not liable for data loss\n'
                  '• Service may be interrupted for maintenance',
            ),

            _buildSection(
              context,
              '6. Contact',
              'For questions: mayurdabhi041@gmail.com',
            ),

            const SizedBox(height: 32),

            // Privacy Policy Link
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For detailed information about how we handle your data, please read our Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openPrivacyPolicy(),
                    child: const Text('View Privacy Policy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://mayur.dev/setkeep-safe-privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
