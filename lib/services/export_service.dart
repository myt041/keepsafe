import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/services/encryption_service.dart';

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
      // Create a data map containing all user data
      final Map<String, dynamic> dataMap = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'credentials': credentials.map((c) => c.toMap()).toList(),
        'familyMembers': familyMembers.map((m) => m.toMap()).toList(),
      };

      // Convert data map to JSON
      final String jsonData = jsonEncode(dataMap);
      
      // Encrypt the JSON data
      final String encryptedData = await _encryptionService.encrypt(jsonData);
      
      // Create a file name with timestamp - use .txt extension for better platform compatibility
      final String fileName = 'keepsafe_backup_${DateTime.now().millisecondsSinceEpoch}.kse';
      
      // Save the encrypted data to a file in the app documents directory
      final String filePath = await _saveToFile(encryptedData, fileName);
      
      return filePath;
    } catch (e) {
      debugPrint('Error during data export: $e');
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
        debugPrint('Successfully read file content, length: ${encryptedData.length}');
      } catch (e) {
        debugPrint('Error reading file: $e');
        throw Exception('Could not read file: $e');
      }
      
      if (encryptedData.isEmpty) {
        throw Exception('File is empty');
      }
      
      try {
        // Attempt to decrypt the data
        final String jsonData = await _encryptionService.decrypt(encryptedData);
        debugPrint('Successfully decrypted file content');
        
        // Parse the JSON data
        final Map<String, dynamic> dataMap = jsonDecode(jsonData);
        
        // Validate the data format
        if (!dataMap.containsKey('credentials') || !dataMap.containsKey('familyMembers')) {
          throw Exception('Invalid backup file format - missing required fields');
        }
        
        // Validate data structure
        final credentials = dataMap['credentials'];
        final familyMembers = dataMap['familyMembers'];
        
        if (credentials is! List || familyMembers is! List) {
          throw Exception('Invalid backup file format - data structure error');
        }
        
        debugPrint('Valid backup file with ${credentials.length} credentials and ${familyMembers.length} family members');
        return dataMap;
      } on FormatException catch (e) {
        debugPrint('JSON parsing error: $e');
        throw Exception('Invalid backup file format - not a valid JSON');
      } catch (e) {
        debugPrint('Decryption or validation error: $e');
        throw Exception('Could not decrypt file. This may not be a valid backup file.');
      }
    } catch (e) {
      debugPrint('Error during data import: $e');
      rethrow;
    }
  }
} 