import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/services/encryption_service.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final EncryptionService _encryptionService = EncryptionService();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'keepsafe.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create Family Members table
    await db.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        photoUrl TEXT
      )
    ''');

    // Create Credentials table
    await db.execute('''
      CREATE TABLE credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        familyMemberId INTEGER,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        encryptedFields TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (familyMemberId) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');
  }

  // Family Member operations
  Future<int> insertFamilyMember(FamilyMember member) async {
    final db = await database;
    return await db.insert('family_members', member.toMap());
  }

  Future<int> updateFamilyMember(FamilyMember member) async {
    final db = await database;
    return await db.update(
      'family_members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await database;
    return await db.delete(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FamilyMember>> getFamilyMembers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('family_members');
    
    return List.generate(maps.length, (i) {
      return FamilyMember.fromMap(maps[i]);
    });
  }

  Future<FamilyMember?> getFamilyMember(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return FamilyMember.fromMap(maps.first);
    }
    
    return null;
  }

  // Credential operations
  Future<int> insertCredential(Credential credential) async {
    final db = await database;
    
    // Encrypt fields before storing
    final encryptedFields = await _encryptionService.encrypt(
      jsonEncode(credential.fields),
    );
    
    final map = credential.toMap();
    map['encryptedFields'] = encryptedFields;
    map.remove('fields');
    
    return await db.insert('credentials', map);
  }

  Future<int> updateCredential(Credential credential) async {
    final db = await database;
    
    // Encrypt fields before storing
    final encryptedFields = await _encryptionService.encrypt(
      jsonEncode(credential.fields),
    );
    
    final map = credential.toMap();
    map['encryptedFields'] = encryptedFields;
    map.remove('fields');
    
    return await db.update(
      'credentials',
      map,
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<int> deleteCredential(int id) async {
    final db = await database;
    return await db.delete(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Credential>> getCredentials({int? familyMemberId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (familyMemberId != null) {
      maps = await db.query(
        'credentials',
        where: 'familyMemberId = ?',
        whereArgs: [familyMemberId],
      );
    } else {
      maps = await db.query('credentials');
    }
    
    final credentials = <Credential>[];
    
    for (var originalMap in maps) {
      // Create a mutable copy of the map
      final map = Map<String, dynamic>.from(originalMap);
      
      // Decrypt fields before returning
      final decryptedFields = await _encryptionService.decrypt(map['encryptedFields']);
      map['fields'] = jsonDecode(decryptedFields);
      map.remove('encryptedFields');
      
      credentials.add(Credential.fromMap(map));
    }
    
    return credentials;
  }

  Future<Credential?> getCredential(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      // Create a mutable copy of the map
      final map = Map<String, dynamic>.from(maps.first);
      
      // Decrypt fields before returning
      final decryptedFields = await _encryptionService.decrypt(map['encryptedFields']);
      map['fields'] = jsonDecode(decryptedFields);
      map.remove('encryptedFields');
      
      return Credential.fromMap(map);
    }
    
    return null;
  }

  Future<List<Credential>> searchCredentials(String query, {int? familyMemberId}) async {
    final db = await database;
    final allCredentials = await getCredentials(familyMemberId: familyMemberId);
    
    query = query.toLowerCase();
    
    return allCredentials.where((credential) {
      // Check if the query matches any field in the credential
      return credential.getSearchTerms().any(
        (term) => term.toLowerCase().contains(query),
      );
    }).toList();
  }

  // Clear all data from the database
  Future<void> clearAllData() async {
    try {
      final db = await database;
      
      // Use transactions for atomicity
      await db.transaction((txn) async {
        // Clear all tables
        await txn.delete('credentials');
        await txn.delete('family_members');
      });
      
      debugPrint('Database cleared successfully');
    } catch (e) {
      debugPrint('Error clearing database: $e');
      rethrow;
    }
  }
} 