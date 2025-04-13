import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/providers/auth_provider.dart';
import 'package:keepsafe/providers/theme_provider.dart';
import 'package:keepsafe/utils/theme.dart';
import 'package:local_auth/local_auth.dart';
import 'package:keepsafe/providers/data_provider.dart';
import 'package:keepsafe/screens/splash_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hasBiometrics = authProvider.isBiometricsAvailable;
    final isBiometricsEnabled = authProvider.isBiometricsEnabled;
    
    String biometricType = 'Biometric';
    IconData biometricIcon = Icons.fingerprint;
    
    if (authProvider.availableBiometrics.contains(BiometricType.face)) {
      biometricType = 'Face ID';
      biometricIcon = Icons.face;
    } else if (authProvider.availableBiometrics.contains(BiometricType.fingerprint)) {
      biometricType = 'Fingerprint';
      biometricIcon = Icons.fingerprint;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSection('Security'),
                if (hasBiometrics)
                  SwitchListTile(
                    title: Text('Use $biometricType'),
                    subtitle: Text('Enable $biometricType authentication'),
                    value: isBiometricsEnabled,
                    onChanged: _toggleBiometrics,
                    secondary: Icon(biometricIcon),
                  ),
                ListTile(
                  leading: const Icon(Icons.pin),
                  title: const Text('Change PIN'),
                  subtitle: const Text('Update your security PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                ),
                const Divider(),
                _buildSection('Data Management'),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Export Data'),
                  subtitle: const Text('Backup your data to a file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore data from a backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all your stored information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showClearDataDialog,
                ),
                const Divider(),
                _buildSection('App Settings'),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeModeName(themeProvider.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(themeProvider),
                ),
                const Divider(),
                _buildSection('About'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share App'),
                  subtitle: const Text('Tell others about KeepSafe'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _shareApp,
                ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Rate Us'),
                  subtitle: const Text('Rate us on the app store'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _rateApp,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _viewPrivacyPolicy,
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined),
                  title: const Text('Connect Us'),
                  subtitle: const Text('Send us feedback or get support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _connectUs,
                ),
                // Open Source Licenses temporarily hidden
                /* ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'KeepSafe',
                      applicationVersion: '1.0.0',
                    );
                  },
                ), */
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Future<void> _toggleBiometrics(bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await authProvider.toggleBiometrics(value);
      
      if (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication enabled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication disabled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${value ? 'enable' : 'disable'} biometrics: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showChangePinDialog() async {
    String currentPin = '';
    String newPin = '';
    String confirmPin = '';
    bool showCurrentPinError = false;
    bool showNewPinError = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      errorText: showCurrentPinError ? 'Invalid PIN' : null,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    onChanged: (value) {
                      currentPin = value;
                      if (showCurrentPinError) {
                        setState(() {
                          showCurrentPinError = false;
                        });
                      }
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'New PIN',
                      errorText: showNewPinError ? 'PINs do not match' : null,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    onChanged: (value) {
                      newPin = value;
                      if (showNewPinError) {
                        setState(() {
                          showNewPinError = false;
                        });
                      }
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Confirm New PIN',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    onChanged: (value) {
                      confirmPin = value;
                      if (showNewPinError) {
                        setState(() {
                          showNewPinError = false;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    if (newPin != confirmPin) {
                      setState(() {
                        showNewPinError = true;
                      });
                      return;
                    }

                    if (currentPin.length != 4 || newPin.length != 4) {
                      return;
                    }

                    try {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.changePinCode(currentPin, newPin);
                      if (mounted) Navigator.of(context).pop();
                      _showSuccessSnackBar('PIN updated successfully');
                    } catch (e) {
                      setState(() {
                        showCurrentPinError = true;
                      });
                    }
                  },
                  child: const Text('CHANGE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will permanently delete all your stored credentials and family members. This action cannot be undone.',
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
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Reset auth state
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.resetAuth();
        
        // Clear all data from database
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.clearAllData();
        
        if (mounted) {
          _showSuccessSnackBar('All data has been cleared');
          
          // Navigate to splash screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error clearing data: $e');
        _showErrorDialog('Failed to clear data: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to get theme mode name
  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System default';
    }
  }

  // Show theme selection dialog
  Future<void> _showThemeDialog(ThemeProvider themeProvider) async {
    final ThemeMode? result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Theme'),
          children: [
            _buildThemeOption(
              context,
              title: 'System default',
              subtitle: 'Follow system settings',
              icon: Icons.brightness_auto,
              themeMode: ThemeMode.system,
              currentMode: themeProvider.themeMode,
            ),
            _buildThemeOption(
              context,
              title: 'Light',
              subtitle: 'Light theme',
              icon: Icons.brightness_high,
              themeMode: ThemeMode.light,
              currentMode: themeProvider.themeMode,
            ),
            _buildThemeOption(
              context,
              title: 'Dark',
              subtitle: 'Dark theme',
              icon: Icons.brightness_4,
              themeMode: ThemeMode.dark,
              currentMode: themeProvider.themeMode,
            ),
          ],
        );
      },
    );

    if (result != null) {
      await themeProvider.setThemeMode(result);
    }
  }

  // Build a theme option for the dialog
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode themeMode,
    required ThemeMode currentMode,
  }) {
    final isSelected = themeMode == currentMode;

    return SimpleDialogOption(
      onPressed: () => Navigator.of(context).pop(themeMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : null,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  // Export data to a file and share it
  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      // Export the data
      final String filePath = await dataProvider.exportAllData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Notify user about backup improvements
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your backup has been created and can be imported on other devices where you have KeepSafe installed.',
              style: TextStyle(fontSize: 13),
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
        
        // Share the exported file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'KeepSafe Data Backup',
          text: 'Your KeepSafe data backup. Keep this file secure!',
        );
        
        _showSuccessSnackBar('Data exported successfully');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to export data: ${e.toString()}');
    }
  }

  // Import data from a file
  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'Importing data will replace all your current data. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONTINUE'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isLoading = true;
      });
      
      // Pick a file using any file type to avoid platform filter issues
      final result = await FilePicker.platform.pickFiles();
      
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final file = result.files.first;
      final filePath = file.path;
      
      if (filePath == null) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Invalid file selected');
        return;
      }
      
      // Import the data - let the import service validate the file contents
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      try {
        await dataProvider.importData(filePath);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Check if this was a legacy import (which creates empty data)
          final bool hasData = dataProvider.credentials.isNotEmpty || dataProvider.familyMembers.isNotEmpty;
          
          if (!hasData) {
            // Show special message for legacy/empty imports
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Import Partial Success'),
                  content: const Text(
                    'Your backup file was recognized but could not be fully decrypted due to compatibility issues. '
                    'A new empty vault has been created. You may need to manually add your data.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else {
            _showSuccessSnackBar('Data imported successfully');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (e.toString().contains('Key length not 128/192/256 bits') || 
              e.toString().contains('corrupted') ||
              e.toString().contains('different device')) {
            
            // Show dialog with option to create new backup
            _showBackupCompatibilityDialog();
          } else {
            _showErrorDialog('Failed to import data: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to import data: ${e.toString()}');
      }
    }
  }
  
  // Show dialog explaining the backup compatibility issue
  void _showBackupCompatibilityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup Compatibility Issue'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The backup file could not be imported because it was created on a different device or with a different app version.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Recommendation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• Create a new backup on your original device using the latest app version\n'
                '• If that\'s not possible, you\'ll need to manually recreate your data on this device',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK, I UNDERSTAND'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Check out KeepSafe - Your Personal Secure Vault for storing confidential information securely: https://play.google.com/store/apps/details?id=com.mayur.keepsafe',
        subject: 'KeepSafe - Your Personal Secure Vault',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      _showErrorDialog('Failed to share app: ${e.toString()}');
    }
  }

  Future<void> _rateApp() async {
    final Uri url;
    if (Platform.isAndroid) {
      // Android Play Store URL
      url = Uri.parse('https://play.google.com/store/apps/details?id=com.mayur.keepsafe');
    } else if (Platform.isIOS) {
      // iOS App Store URL
      url = Uri.parse('https://apps.apple.com/app/id123456789'); // Replace with your iOS app ID
    } else {
      // Fallback to a website
      url = Uri.parse('https://keepsafe.app');
    }
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Could not launch the app store');
      }
    } catch (e) {
      debugPrint('Error opening app store: $e');
      _showErrorDialog('Failed to open app store: ${e.toString()}');
    }
  }

  Future<void> _viewPrivacyPolicy() async {
    // Use the actual Google Docs privacy policy URL
    final Uri url = Uri.parse('https://docs.google.com/document/d/10PCio1f6F87L1LOcse6tNymGmeFsB5EUKyt_q3Y0j34/edit?usp=sharing');
    
    try {
      // Add more debugging info
      debugPrint('Attempting to launch URL: $url');
      final canLaunch = await canLaunchUrl(url);
      debugPrint('Can launch URL: $canLaunch');
      
      if (canLaunch) {
        final result = await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        debugPrint('Launch result: $result');
        if (!result) {
          _showErrorDialog('Failed to launch the URL: $url');
        }
      } else {
        // Fallback to another approach
        _showErrorDialog('Could not launch the privacy policy. Please try opening it manually: https://docs.google.com/document/d/10PCio1f6F87L1LOcse6tNymGmeFsB5EUKyt_q3Y0j34/edit?usp=sharing');
      }
    } catch (e) {
      debugPrint('Error opening privacy policy: $e');
      _showErrorDialog('Failed to open privacy policy: ${e.toString()}');
    }
  }

  Future<void> _connectUs() async {
    try {
      // Show a dialog with contact options
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Connect With Us'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: const Text('mayurdabhi041@gmail.com'),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'mayurdabhi041@gmail.com',
                      query: 'subject=KeepSafe Feedback&body=',
                    );
                    
                    Navigator.of(context).pop();
                    
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (mounted) {
                        _showErrorDialog('Could not launch email client');
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Website'),
                  subtitle: const Text('https://mayur.dev/'),
                  onTap: () async {
                    final Uri websiteUri = Uri.parse('https://mayur.dev/');
                    
                    Navigator.of(context).pop();
                    
                    if (await canLaunchUrl(websiteUri)) {
                      await launchUrl(websiteUri);
                    } else {
                      if (mounted) {
                        _showErrorDialog('Could not launch website');
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error in connect us: $e');
      _showErrorDialog('Failed to open connect options: ${e.toString()}');
    }
  }
} 