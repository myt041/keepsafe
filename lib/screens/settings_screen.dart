import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:keepsafe/utils/strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

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
        title: const Text(AppStrings.appName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSection(AppStrings.security),
                if (hasBiometrics)
                  SwitchListTile(
                    title: Text(AppStrings.useBiometric.replaceAll('%s', biometricType)),
                    subtitle: Text(AppStrings.enableBiometric.replaceAll('%s', biometricType)),
                    value: isBiometricsEnabled,
                    onChanged: _toggleBiometrics,
                    secondary: Icon(biometricIcon),
                  ),
                ListTile(
                  leading: const Icon(Icons.pin),
                  title: const Text(AppStrings.changePin),
                  subtitle: const Text(AppStrings.updateSecurityPin),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                ),
                const Divider(),
                _buildSection(AppStrings.dataManagement),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text(AppStrings.exportData),
                  subtitle: const Text(AppStrings.backupData),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text(AppStrings.importData),
                  subtitle: const Text(AppStrings.restoreData),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text(AppStrings.clearAllData),
                  subtitle: const Text(AppStrings.deleteAllInfo),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showClearDataDialog,
                ),
                const Divider(),
                _buildSection(AppStrings.appSettings),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text(AppStrings.theme),
                  subtitle: Text(_getThemeModeName(themeProvider.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(themeProvider),
                ),
                const Divider(),
                _buildSection(AppStrings.about),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(AppStrings.appVersion),
                  subtitle: Text(_packageInfo?.version ?? AppStrings.loading),
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text(AppStrings.shareApp),
                  subtitle: const Text(AppStrings.tellAboutApp),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _shareApp,
                ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text(AppStrings.rateUs),
                  subtitle: const Text(AppStrings.rateOnStore),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _rateApp,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text(AppStrings.privacyPolicy),
                  subtitle: const Text(AppStrings.viewPrivacyPolicy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _viewPrivacyPolicy,
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined),
                  title: const Text(AppStrings.connectUs),
                  subtitle: const Text(AppStrings.sendFeedback),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _connectUs,
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
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
          const SnackBar(content: Text(AppStrings.biometricEnabled)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.biometricDisabled)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.biometricFailed.replaceAll('%s', value ? 'enable' : 'disable').replaceAll('%s', e.toString())),
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
              title: const Text(AppStrings.changePin),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: AppStrings.changePin,
                      errorText: showCurrentPinError ? AppStrings.invalidPin : null,
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
                      labelText: AppStrings.changePin,
                      errorText: showNewPinError ? AppStrings.pinsNotMatch : null,
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
                      labelText: AppStrings.changePin,
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
                  child: const Text(AppStrings.cancel),
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
                      _showSuccessSnackBar(AppStrings.pinUpdated);
                    } catch (e) {
                      setState(() {
                        showCurrentPinError = true;
                      });
                    }
                  },
                  child: const Text(AppStrings.change),
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
          title: const Text(AppStrings.clearAllData),
          content: const Text(AppStrings.clearDataWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text(AppStrings.delete),
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
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.resetAuth();
        
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        await dataProvider.clearAllData();
        
        if (mounted) {
          _showSuccessSnackBar(AppStrings.dataCleared);
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error clearing data: $e');
        _showErrorDialog(AppStrings.dataClearFailed.replaceAll('%s', e.toString()));
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
        title: const Text(AppStrings.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return AppStrings.systemDefault;
      case ThemeMode.light:
        return AppStrings.lightTheme;
      case ThemeMode.dark:
        return AppStrings.darkTheme;
      default:
        return AppStrings.systemDefault;
    }
  }

  Future<void> _showThemeDialog(ThemeProvider themeProvider) async {
    final ThemeMode? result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(AppStrings.selectTheme),
          children: [
            _buildThemeOption(
              context,
              title: AppStrings.systemDefault,
              subtitle: AppStrings.followSystem,
              icon: Icons.brightness_auto,
              themeMode: ThemeMode.system,
              currentMode: themeProvider.themeMode,
            ),
            _buildThemeOption(
              context,
              title: AppStrings.lightTheme,
              subtitle: AppStrings.lightTheme,
              icon: Icons.brightness_high,
              themeMode: ThemeMode.light,
              currentMode: themeProvider.themeMode,
            ),
            _buildThemeOption(
              context,
              title: AppStrings.darkTheme,
              subtitle: AppStrings.darkTheme,
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
              const Icon(
                Icons.check,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final String filePath = await dataProvider.exportAllData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.backupCreated),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: AppStrings.ok,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
        
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: '${AppStrings.appName} Data Backup',
          text: 'Your ${AppStrings.appName} data backup. Keep this file secure!',
        );
        
        _showSuccessSnackBar(AppStrings.dataExported);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(AppStrings.dataExportFailed.replaceAll('%s', e.toString()));
    }
  }

  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.importData),
          content: const Text(AppStrings.importDataWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.continueText),
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
        _showErrorDialog(AppStrings.dataImportFailed.replaceAll('%s', 'Invalid file selected'));
        return;
      }
      
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      try {
        await dataProvider.importData(filePath);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          final bool hasData = dataProvider.credentials.isNotEmpty || dataProvider.familyMembers.isNotEmpty;
          
          if (!hasData) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(AppStrings.importData),
                  content: const Text(AppStrings.backupCompatibilityIssue),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.ok),
                    ),
                  ],
                );
              },
            );
          } else {
            _showSuccessSnackBar(AppStrings.dataImported);
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
            _showBackupCompatibilityDialog();
          } else {
            _showErrorDialog(AppStrings.dataImportFailed.replaceAll('%s', e.toString()));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(AppStrings.dataImportFailed.replaceAll('%s', e.toString()));
      }
    }
  }
  
  void _showBackupCompatibilityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.importData),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.backupCompatibilityIssue),
              SizedBox(height: 16),
              Text(
                AppStrings.recommendation,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppStrings.createNewBackup),
              Text(AppStrings.manualRecreate),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.understand),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Check out ${AppStrings.appName} - ${AppStrings.appDescription}: ${AppStrings.playStoreUrl}',
        subject: '${AppStrings.appName} - ${AppStrings.appDescription}',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'share'));
    }
  }

  Future<void> _rateApp() async {
    final Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse(AppStrings.playStoreUrl);
    } else if (Platform.isIOS) {
      url = Uri.parse(AppStrings.appStoreUrl);
    } else {
      url = Uri.parse(AppStrings.appWebsite);
    }
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'app store'));
      }
    } catch (e) {
      debugPrint('Error opening app store: $e');
      _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'app store'));
    }
  }

  Future<void> _viewPrivacyPolicy() async {
    final Uri url = Uri.parse(AppStrings.privacyPolicyUrl);
    
    try {
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
          _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'privacy policy'));
        }
      } else {
        _showErrorDialog('${AppStrings.couldNotLaunch.replaceAll('%s', 'privacy policy')}. Please try opening it manually: ${AppStrings.privacyPolicyUrl}');
      }
    } catch (e) {
      debugPrint('Error opening privacy policy: $e');
      _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'privacy policy'));
    }
  }

  Future<void> _connectUs() async {
    try {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(AppStrings.connectWithUs),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text(AppStrings.email),
                  subtitle: const Text(AppStrings.supportEmail),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: AppStrings.supportEmail,
                      query: 'subject=${AppStrings.emailSubject}&body=',
                    );
                    
                    Navigator.of(context).pop();
                    
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (mounted) {
                        _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'email client'));
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text(AppStrings.website),
                  subtitle: const Text(AppStrings.websiteUrl),
                  onTap: () async {
                    final Uri websiteUri = Uri.parse(AppStrings.websiteUrl);
                    
                    Navigator.of(context).pop();
                    
                    if (await canLaunchUrl(websiteUri)) {
                      await launchUrl(websiteUri);
                    } else {
                      if (mounted) {
                        _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'website'));
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error in connect us: $e');
      _showErrorDialog(AppStrings.couldNotLaunch.replaceAll('%s', 'connect options'));
    }
  }
} 