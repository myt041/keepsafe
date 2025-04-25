import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Check for update availability
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Show update dialog
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
                const Text('A new version of KeepSafe is available. Would you like to update now?'),
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
                  await _performUpdate();
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static Future<void> _performUpdate() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      
      if (result == AppUpdateResult.success) {
        debugPrint('Update successful');
      } else {
        debugPrint('Update failed: $result');
      }
    } catch (e) {
      debugPrint('Error performing update: $e');
    }
  }
} 