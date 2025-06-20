import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      print("version update checkForUpdate ");

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final packageName = packageInfo.packageName;
      
      // Check Play Store for latest version

        final newVersion = NewVersionPlus(
          androidId: packageName,
          /*iOSId: '1234567890'*/ // Replace with your App Store app ID
        );

        final status = await newVersion.getVersionStatus();
        if (status != null && status.canUpdate) {
          // Show update dialog only if a new version is available
          _showUpdateDialog(context, currentVersion, packageName);
        }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, String currentVersion, String packageName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Version: $currentVersion'),
            const SizedBox(height: 8),
            const Text('A new version of KeepSafe is available on the Play Store. Would you like to update now?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openPlayStore(packageName);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  static Future<void> _openPlayStore(String packageName) async {
    final url = Uri.parse('market://details?id=$packageName');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback to web URL if Play Store app is not available
      final webUrl = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      }
    }
  }
} 