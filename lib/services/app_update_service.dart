import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final packageName = packageInfo.packageName;
      
      // Check Play Store for latest version
      final latestVersion = await _getPlayStoreVersion(packageName);
      
      if (latestVersion != null && _isNewVersionAvailable(currentVersion, latestVersion)) {
        // Show update dialog only if a new version is available
        _showUpdateDialog(context, currentVersion, packageName);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static Future<String?> _getPlayStoreVersion(String packageName) async {
    try {
      final response = await http.get(
        Uri.parse('https://play.google.com/store/apps/details?id=$packageName'),
      );
      
      if (response.statusCode == 200) {
        // Extract version from Play Store page
        final RegExp versionRegExp = RegExp(r'\[\[\[\"([\d\.]+)\"\]\]\]');
        final match = versionRegExp.firstMatch(response.body);
        return match?.group(1);
      }
    } catch (e) {
      debugPrint('Error fetching Play Store version: $e');
    }
    return null;
  }

  static bool _isNewVersionAvailable(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final latestParts = latestVersion.split('.').map(int.parse).toList();
    
    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false;
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