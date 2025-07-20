import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/services/encryption_service.dart';
import 'package:keepsafe/services/backup_password_service.dart';
import 'package:crypto/crypto.dart' as crypto;

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final EncryptionService _encryptionService = EncryptionService();

  /// Export all user data to an encrypted JSON file
  Future<String> exportData({
    required List<Credential> credentials,
    required List<FamilyMember> familyMembers,
  }) async {
    try {
      debugPrint(
          'Starting export process with ${credentials.length} credentials and ${familyMembers.length} family members');

      // Create a data map containing all user data
      final Map<String, dynamic> dataMap = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'credentials': credentials.map((c) => c.toMap()).toList(),
        'familyMembers': familyMembers.map((m) => m.toMap()).toList(),
      };

      // Convert data map to JSON
      final String jsonData = jsonEncode(dataMap);
      debugPrint('Original JSON data length: ${jsonData.length}');

      // Encrypt the JSON data
      final String encryptedData = await _encryptionService.encrypt(jsonData);
      debugPrint('Encrypted data length: ${encryptedData.length}');

      // Create a file name with timestamp
      final String fileName =
          'keepsafe_backup_${DateTime.now().millisecondsSinceEpoch}.kse';
      debugPrint('Generated filename: $fileName');

      // Save the encrypted data to a file in the app documents directory
      final String filePath = await _saveToFile(encryptedData, fileName);
      debugPrint('File saved to: $filePath');

      // Verify the saved file can be read back
      try {
        final File savedFile = File(filePath);
        final String fileContents = await savedFile.readAsString();
        debugPrint(
            'Successfully read saved file, length: ${fileContents.length}');

        if (fileContents == encryptedData) {
          debugPrint('File contents match original encrypted data: SUCCESS');
        } else {
          debugPrint(
              'WARNING: File contents do not match original encrypted data');
        }
      } catch (e) {
        debugPrint('Error verifying saved file: $e');
      }

      return filePath;
    } catch (e) {
      debugPrint('Error during data export: $e');
      rethrow;
    }
  }

  /// Export all user data to an encrypted JSON file with backup password
  Future<String> exportDataWithBackupPassword({
    required List<Credential> credentials,
    required List<FamilyMember> familyMembers,
    required String backupPassword,
  }) async {
    try {
      debugPrint(
          'Starting export process with backup password - ${credentials.length} credentials and ${familyMembers.length} family members');

      // Get the current salt for embedding in the backup
      final backupPasswordService = BackupPasswordService();
      final salt = await backupPasswordService.getCurrentSalt();

      // Create a data map containing all user data
      final Map<String, dynamic> dataMap = {
        'exportDate': DateTime.now().toIso8601String(),
        'version':
            '2.0.0', // New version to indicate backup password encryption
        'encryptionType': 'backup_password',
        'salt': salt, // Embed the salt for cross-device compatibility
        'credentials': credentials.map((c) => c.toMap()).toList(),
        'familyMembers': familyMembers.map((m) => m.toMap()).toList(),
      };

      // Convert data map to JSON
      final String jsonData = jsonEncode(dataMap);
      debugPrint('Original JSON data length: ${jsonData.length}');

      // Encrypt the JSON data with backup password and salt
      final String encryptedData = await _encryptionService
          .encryptWithBackupPasswordAndSalt(jsonData, backupPassword, salt);
      debugPrint(
          'Backup password encrypted data length: ${encryptedData.length}');

      // Create a combined format: salt:encryptedData for cross-device compatibility
      final String combinedData = '$salt:$encryptedData';
      debugPrint('Combined data length: ${combinedData.length}');

      // Create a file name with timestamp and salt hash for cross-device identification
      final String saltHash =
          crypto.sha256.convert(utf8.encode(salt)).toString().substring(0, 8);
      final String fileName =
          'keepsafe_backup_secure_${DateTime.now().millisecondsSinceEpoch}_salt_$saltHash.kse';
      debugPrint('Generated filename: $fileName');

      // Save the combined data to a file in the app documents directory
      final String filePath = await _saveToFile(combinedData, fileName);
      debugPrint('File saved to: $filePath');

      return filePath;
    } catch (e) {
      debugPrint('Error during backup password data export: $e');
      rethrow;
    }
  }

  /// Save encrypted data to a file in the app's documents directory
  Future<String> _saveToFile(String encryptedData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsString(encryptedData);
      return file.path;
    } catch (e) {
      debugPrint('Error saving export file: $e');
      rethrow;
    }
  }

  /// Import data from an encrypted export file
  Future<Map<String, dynamic>> importData(String filePath) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      debugPrint('Importing file from path: $filePath');
      String encryptedData;

      try {
        encryptedData = await file.readAsString();
        debugPrint(
            'Successfully read file content, length: ${encryptedData.length}');
      } catch (e) {
        debugPrint('Error reading file: $e');
        throw Exception('Could not read file: $e');
      }

      if (encryptedData.isEmpty) {
        throw Exception('File is empty');
      }

      try {
        // Attempt to decrypt the data
        debugPrint('Attempting to decrypt file content...');
        final String jsonData = await _encryptionService.decrypt(encryptedData);
        if (jsonData.isEmpty) {
          throw Exception('Decryption returned empty data');
        }
        debugPrint(
            'Successfully decrypted file content, length: ${jsonData.length}');

        // Parse the JSON data
        Map<String, dynamic> dataMap;
        try {
          dataMap = jsonDecode(jsonData);
          debugPrint('Successfully parsed JSON data');

          // Debug the structure
          if (dataMap.containsKey('credentials')) {
            final credentials = dataMap['credentials'];
            debugPrint(
                'Found credentials: ${credentials is List ? credentials.length : 'not a list'}');
          }

          if (dataMap.containsKey('familyMembers')) {
            final familyMembers = dataMap['familyMembers'];
            debugPrint(
                'Found family members: ${familyMembers is List ? familyMembers.length : 'not a list'}');
          }
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
          throw const FormatException(
              'Could not parse the file content as JSON. This may not be a valid backup file.');
        }

        // Validate the data format
        if (!dataMap.containsKey('credentials') ||
            !dataMap.containsKey('familyMembers')) {
          debugPrint('Missing required fields in backup file');
          throw Exception(
              'Invalid backup file format - missing required fields');
        }

        // Check if this is a legacy/empty import
        final credentials = dataMap['credentials'];
        final familyMembers = dataMap['familyMembers'];

        if ((credentials is List && credentials.isEmpty) &&
            (familyMembers is List && familyMembers.isEmpty)) {
          debugPrint('Detected empty data in import');
        }

        if (credentials is! List || familyMembers is! List) {
          debugPrint('Invalid data structure in backup file');
          throw Exception('Invalid backup file format - data structure error');
        }

        debugPrint(
            'Valid backup file with ${credentials.length} credentials and ${familyMembers.length} family members');
        return dataMap;
      } on FormatException catch (e) {
        debugPrint('JSON parsing error: $e');
        throw Exception('Invalid backup file format: ${e.message}');
      } catch (e) {
        debugPrint('Decryption or validation error: $e');

        // Check if this is a legacy format
        if (e.toString().contains('empty data')) {
          // Create empty but valid data structure
          final Map<String, dynamic> emptyData = {
            'exportDate': DateTime.now().toIso8601String(),
            'version': '1.0.0',
            'credentials': [],
            'familyMembers': [],
          };
          debugPrint('Created empty data structure for legacy import');
          return emptyData;
        }

        // Provide a more helpful error message
        if (e.toString().contains('Key length not 128/192/256 bits')) {
          throw Exception(
              'Encryption key format is not compatible. Please try creating a new backup.');
        } else if (e.toString().contains('Invalid or corrupted pad block') ||
            e.toString().contains('Decryption error')) {
          throw Exception(
              'Could not decrypt file. The file may be corrupted or created with a different app version.');
        } else {
          throw Exception(
              'Could not decrypt file. This may not be a valid backup file.');
        }
      }
    } catch (e) {
      debugPrint('Error during data import: $e');
      rethrow;
    }
  }

  /// Import data from an encrypted export file with backup password
  Future<Map<String, dynamic>> importDataWithBackupPassword(
      String filePath, String backupPassword) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      debugPrint('Importing file with backup password from path: $filePath');
      String encryptedData;

      try {
        encryptedData = await file.readAsString();
        debugPrint(
            'Successfully read file content, length: ${encryptedData.length}');
      } catch (e) {
        debugPrint('Error reading file: $e');
        throw Exception('Could not read file: $e');
      }

      if (encryptedData.isEmpty) {
        throw Exception('File is empty');
      }

      try {
        // Check if this is the new combined format (salt:encryptedData)
        String salt;
        String actualEncryptedData;

        if (encryptedData.contains(':')) {
          final parts = encryptedData.split(':');
          if (parts.length >= 2) {
            // This is the new format with salt prefix
            salt = parts[0];
            actualEncryptedData = parts.sublist(1).join(':');
            debugPrint(
                'Detected new format with salt prefix. Salt length: ${salt.length}');
          } else {
            // This might be the old format or corrupted
            salt = '';
            actualEncryptedData = encryptedData;
            debugPrint('Using old format or corrupted data');
          }
        } else {
          // Old format without salt prefix
          salt = '';
          actualEncryptedData = encryptedData;
          debugPrint('Using old format without salt prefix');
        }

        // Now decrypt with the extracted salt
        debugPrint('Attempting to decrypt with extracted salt...');
        String jsonData;

        try {
          if (salt.isNotEmpty) {
            jsonData =
                await _encryptionService.decryptWithBackupPasswordAndSalt(
                    actualEncryptedData, backupPassword, salt);
            debugPrint('Decryption with extracted salt successful');
          } else {
            // Fallback to current device salt
            jsonData = await _encryptionService.decryptWithBackupPassword(
                actualEncryptedData, backupPassword);
            debugPrint('Decryption with current device salt successful');
          }
        } catch (e) {
          debugPrint('Decryption failed: $e');
          throw Exception(
              'Could not decrypt file with the provided password. Please verify your backup password.');
        }

        if (jsonData.isEmpty) {
          throw Exception('Decryption returned empty data');
        }
        debugPrint(
            'Successfully decrypted file content with backup password, length: ${jsonData.length}');

        // Parse the JSON data
        Map<String, dynamic> dataMap;
        try {
          dataMap = jsonDecode(jsonData);
          debugPrint('Successfully parsed JSON data');

          // Extract the salt from the backup data if available (for logging)
          if (dataMap.containsKey('salt')) {
            final embeddedSalt = dataMap['salt'];
            debugPrint(
                'Embedded salt in backup data: ${embeddedSalt.length} characters');
          }

          // Debug the structure
          if (dataMap.containsKey('credentials')) {
            final credentials = dataMap['credentials'];
            debugPrint(
                'Found credentials: ${credentials is List ? credentials.length : 'not a list'}');
          }

          if (dataMap.containsKey('familyMembers')) {
            final familyMembers = dataMap['familyMembers'];
            debugPrint(
                'Found family members: ${familyMembers is List ? familyMembers.length : 'not a list'}');
          }
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
          throw const FormatException(
              'Could not parse the file content as JSON. This may not be a valid backup file.');
        }

        // Validate the data format
        if (!dataMap.containsKey('credentials') ||
            !dataMap.containsKey('familyMembers')) {
          debugPrint('Missing required fields in backup file');
          throw Exception(
              'Invalid backup file format - missing required fields');
        }

        // Check if this is a legacy/empty import
        final credentials = dataMap['credentials'];
        final familyMembers = dataMap['familyMembers'];

        if ((credentials is List && credentials.isEmpty) &&
            (familyMembers is List && familyMembers.isEmpty)) {
          debugPrint('Detected empty data in import');
        }

        if (credentials is! List || familyMembers is! List) {
          debugPrint('Invalid data structure in backup file');
          throw Exception('Invalid backup file format - data structure error');
        }

        debugPrint(
            'Valid backup file with ${credentials.length} credentials and ${familyMembers.length} family members');
        return dataMap;
      } catch (e) {
        debugPrint('Backup password decryption or validation error: $e');

        // Provide a more helpful error message
        if (e.toString().contains('Invalid encrypted data format')) {
          throw Exception(
              'Invalid backup file format. This may not be a password-protected backup file.');
        } else if (e.toString().contains('Decryption returned empty data')) {
          throw Exception('Incorrect backup password. Please try again.');
        } else if (e
            .toString()
            .contains('Could not decrypt file with the provided password')) {
          throw Exception(
              'Could not decrypt file with the provided password. Please verify your backup password.');
        } else {
          throw Exception(
              'Could not decrypt file. This may not be a valid backup file.');
        }
      }
    } catch (e) {
      debugPrint('Error during backup password data import: $e');
      rethrow;
    }
  }
}
