import 'package:flutter/foundation.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/models/family_member.dart';
import 'package:keepsafe/services/database_service.dart';
import 'package:keepsafe/services/export_service.dart';
import 'package:keepsafe/services/backup_password_service.dart';

class DataProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final ExportService _exportService = ExportService();

  List<FamilyMember> _familyMembers = [];
  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];

  // Selected family member ID (null means showing user's own credentials)
  int? _selectedFamilyMemberId;

  // Selected category for filtering (null means show all)
  String? _selectedCategory;

  // Search query
  String _searchQuery = '';

  // Getters
  List<FamilyMember> get familyMembers => _familyMembers;
  List<Credential> get credentials => _filteredCredentials;
  int? get selectedFamilyMemberId => _selectedFamilyMemberId;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Initialize data
  Future<void> initialize() async {
    await _loadFamilyMembers();
    await _loadCredentials();
  }

  // Load family members from database
  Future<void> _loadFamilyMembers() async {
    _familyMembers = await _databaseService.getFamilyMembers();
    notifyListeners();
  }

  // Load credentials from database based on selected family member
  Future<void> _loadCredentials() async {
    _credentials = await _databaseService.getCredentials(
      familyMemberId: _selectedFamilyMemberId,
    );
    _applyFilters();
  }

  // Apply filters to the credentials list
  void _applyFilters() {
    _filteredCredentials = _credentials.where((credential) {
      // Apply category filter if selected
      final categoryMatch =
          _selectedCategory == null || credential.category == _selectedCategory;

      // Apply search filter if query is not empty
      final searchMatch = _searchQuery.isEmpty ||
          credential.getSearchTerms().any(
                (term) =>
                    term.toLowerCase().contains(_searchQuery.toLowerCase()),
              );

      return categoryMatch && searchMatch;
    }).toList();

    notifyListeners();
  }

  // Set selected family member
  Future<void> selectFamilyMember(int? familyMemberId) async {
    if (_selectedFamilyMemberId != familyMemberId) {
      _selectedFamilyMemberId = familyMemberId;
      await _loadCredentials();
    }
  }

  // Set selected category
  void selectCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Add a new family member
  Future<void> addFamilyMember(FamilyMember member) async {
    final id = await _databaseService.insertFamilyMember(member);
    final newMember = member.copyWith(id: id);
    _familyMembers.add(newMember);
    notifyListeners();
  }

  // Update a family member
  Future<void> updateFamilyMember(FamilyMember member) async {
    await _databaseService.updateFamilyMember(member);
    final index = _familyMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _familyMembers[index] = member;
      notifyListeners();
    }
  }

  // Delete a family member
  Future<void> deleteFamilyMember(int id) async {
    await _databaseService.deleteFamilyMember(id);
    _familyMembers.removeWhere((member) => member.id == id);

    // If the deleted member was selected, reset selection
    if (_selectedFamilyMemberId == id) {
      _selectedFamilyMemberId = null;
      await _loadCredentials();
    } else {
      notifyListeners();
    }
  }

  // Add a new credential
  Future<void> addCredential(Credential credential) async {
    final id = await _databaseService.insertCredential(credential);
    final newCredential = credential.copyWith(id: id);
    _credentials.add(newCredential);
    _applyFilters();
  }

  // Update a credential
  Future<void> updateCredential(Credential credential) async {
    await _databaseService.updateCredential(credential);
    final index = _credentials.indexWhere((c) => c.id == credential.id);
    if (index != -1) {
      _credentials[index] = credential;
      _applyFilters();
    }
  }

  // Delete a credential
  Future<void> deleteCredential(int id) async {
    await _databaseService.deleteCredential(id);
    _credentials.removeWhere((credential) => credential.id == id);
    _applyFilters();
  }

  // Toggle favorite status of a credential
  Future<void> toggleFavorite(Credential credential) async {
    final updatedCredential = credential.copyWith(
      isFavorite: !credential.isFavorite,
    );

    await updateCredential(updatedCredential);
  }

  // Clear all data from the database
  Future<void> clearAllData() async {
    try {
      // Clear local lists
      _credentials = [];
      _filteredCredentials = [];
      _familyMembers = [];
      _selectedFamilyMemberId = null;
      _selectedCategory = null;
      _searchQuery = '';

      // Clear database tables - implementation needed in DatabaseService
      await _databaseService.clearAllData();

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  // Export all data to an encrypted file
  Future<String> exportAllData() async {
    try {
      // Make sure the data is loaded before exporting
      if (_credentials.isEmpty || _familyMembers.isEmpty) {
        await initialize();
      }

      // Export the data using the export service
      final String filePath = await _exportService.exportData(
        credentials: _credentials,
        familyMembers: _familyMembers,
      );

      return filePath;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  // Import data from an encrypted file
  Future<void> importData(String filePath) async {
    try {
      debugPrint('Starting legacy import for file: $filePath');
      // 1. Parse and validate the backup file first
      final Map<String, dynamic> dataMap =
          await _exportService.importData(filePath);
      debugPrint('Backup file parsed successfully. Proceeding to clear data.');
      // 2. Only clear data if the backup is valid
      await clearAllData();
      debugPrint('Existing data cleared. Importing new data.');
      // 3. Import family members
      final List<dynamic> familyMembersData = dataMap['familyMembers'];
      for (var memberData in familyMembersData) {
        final member = FamilyMember.fromMap(memberData);
        await addFamilyMember(member);
      }
      // 4. Import credentials
      final List<dynamic> credentialsData = dataMap['credentials'];
      for (var credentialData in credentialsData) {
        final credential = Credential.fromMap(credentialData);
        await addCredential(credential);
      }
      // 5. Refresh data
      await initialize();
      debugPrint('Import completed successfully.');
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  // Export all data to an encrypted file with backup password
  Future<String> exportAllDataWithBackupPassword(String backupPassword) async {
    try {
      // Make sure the data is loaded before exporting
      if (_credentials.isEmpty || _familyMembers.isEmpty) {
        await initialize();
      }

      // Export the data using the export service with backup password
      final String filePath = await _exportService.exportDataWithBackupPassword(
        credentials: _credentials,
        familyMembers: _familyMembers,
        backupPassword: backupPassword,
      );

      return filePath;
    } catch (e) {
      debugPrint('Error exporting data with backup password: $e');
      rethrow;
    }
  }

  // Import data from an encrypted file with backup password
  Future<void> importDataWithBackupPassword(
      String filePath, String backupPassword) async {
    try {
      debugPrint('Starting password-protected import for file: $filePath');
      // 1. Parse and validate the backup file first
      final Map<String, dynamic> dataMap = await _exportService
          .importDataWithBackupPassword(filePath, backupPassword);
      debugPrint('Backup file parsed successfully. Proceeding to clear data.');
      // 2. Only clear data if the backup is valid
      await clearAllData();
      debugPrint('Existing data cleared. Importing new data.');
      // 3. Import family members
      final List<dynamic> familyMembersData = dataMap['familyMembers'];
      for (var memberData in familyMembersData) {
        final member = FamilyMember.fromMap(memberData);
        await addFamilyMember(member);
      }
      // 4. Import credentials
      final List<dynamic> credentialsData = dataMap['credentials'];
      for (var credentialData in credentialsData) {
        final credential = Credential.fromMap(credentialData);
        await addCredential(credential);
      }
      // 5. Refresh data
      await initialize();
      debugPrint('Password-protected import completed successfully.');
    } catch (e) {
      debugPrint('Error importing data with backup password: $e');
      rethrow;
    }
  }

  // Check if backup password is set
  Future<bool> isBackupPasswordSet() async {
    final backupPasswordService = BackupPasswordService();
    return await backupPasswordService.isBackupPasswordSet();
  }

  // Set backup password
  Future<void> setBackupPassword(String password) async {
    final backupPasswordService = BackupPasswordService();
    await backupPasswordService.setBackupPassword(password);
  }

  // Verify backup password
  Future<bool> verifyBackupPassword(String password) async {
    final backupPasswordService = BackupPasswordService();
    return await backupPasswordService.verifyBackupPassword(password);
  }
}
