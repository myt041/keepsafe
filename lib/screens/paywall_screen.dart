import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:keepsafe/providers/subscription_provider.dart';
import 'package:keepsafe/screens/terms_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends StatelessWidget {
  final int currentFamilyMembers;
  final int maxFreeMembers;

  const PaywallScreen({
    Key? key,
    required this.currentFamilyMembers,
    required this.maxFreeMembers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App logo
              SizedBox(
                height: 100,
                child: Image.asset(
                  'assets/images/app_logo.jpeg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock Pro Features',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Benefits list
              _BenefitList(),
              const SizedBox(height: 24),
              // Current usage
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You\'ve added $currentFamilyMembers/$maxFreeMembers family members',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              // Subscription options
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  if (subscriptionProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!subscriptionProvider.hasProducts) {
                    return const Text('Loading subscription options...');
                  }

                  return Column(
                    children: [
                      // Monthly subscription
                      if (subscriptionProvider.monthlyProduct != null)
                        _buildSubscriptionOption(
                          context,
                          subscriptionProvider.monthlyProduct!,
                          subscriptionProvider,
                          'Monthly',
                          null,
                        ),

                      const SizedBox(height: 12),

                      // Yearly subscription
                      if (subscriptionProvider.yearlyProduct != null)
                        _buildSubscriptionOption(
                          context,
                          subscriptionProvider.yearlyProduct!,
                          subscriptionProvider,
                          'Yearly',
                          subscriptionProvider.getYearlySavings(),
                        ),

                      const SizedBox(height: 12),

                      // Restore purchase (iOS)
                      TextButton(
                        onPressed: () async {
                          final success =
                              await subscriptionProvider.restorePurchases();
                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Restore Purchase'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              // Terms & Privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TermsScreen(),
                        ),
                      );
                    },
                    child: const Text('Terms'),
                  ),
                  const Text('|'),
                  TextButton(
                    onPressed: () async {
                      const url =
                          'https://mayur.dev/setkeep-safe-privacy-policy';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    child: const Text('Privacy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionOption(
    BuildContext context,
    ProductDetails product,
    SubscriptionProvider subscriptionProvider,
    String period,
    double? savings,
  ) {
    final theme = Theme.of(context);
    final isRecommended = period == 'Yearly' && savings != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color:
            isRecommended ? theme.colorScheme.primary.withOpacity(0.05) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final success =
                await subscriptionProvider.purchaseSubscription(product.id);
            if (success && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pro $period',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${savings!.toStringAsFixed(0)}% OFF',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.price,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BenefitRow(
          icon: Icons.group,
          text: 'Unlimited family members',
        ),
        const SizedBox(height: 12),
        _BenefitRow(
          icon: Icons.password,
          text: 'Password generator (coming soon)',
        ),
        const SizedBox(height: 12),
        _BenefitRow(
          icon: Icons.star,
          text: 'Access to all upcoming advanced features',
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
