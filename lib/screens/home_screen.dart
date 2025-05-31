import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/models/credential.dart';
import 'package:keepsafe/providers/auth_provider.dart';
import 'package:keepsafe/providers/data_provider.dart';
import 'package:keepsafe/screens/auth/login_screen.dart';
import 'package:keepsafe/screens/credentials/add_credential_screen.dart';
import 'package:keepsafe/screens/credentials/credential_details_screen.dart';
import 'package:keepsafe/screens/family/add_family_member_screen.dart';
import 'package:keepsafe/screens/settings_screen.dart';
import 'package:keepsafe/utils/theme.dart';
import 'package:keepsafe/widgets/credential_card.dart';
import 'package:keepsafe/widgets/empty_state.dart';
import 'package:keepsafe/widgets/family_avatar.dart';
import 'package:keepsafe/widgets/search_bar.dart';
import 'package:keepsafe/services/app_update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Check for app updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdate(context);
    });
  }

  Future<void> _loadData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    await dataProvider.initialize();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.setSearchQuery(query);
  }

  void _onCategorySelected(String? category) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.selectCategory(category);
  }

  void _onFamilyMemberSelected(int? familyMemberId) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.selectFamilyMember(familyMemberId);
  }

  void _addNewCredential() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddCredentialScreen(),
      ),
    );
  }

  void _addNewFamilyMember() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddFamilyMemberScreen(),
      ),
    );
  }

  void _viewCredential(Credential credential) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CredentialDetailsScreen(credential: credential),
      ),
    );
  }

  void _logout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.vpn_key,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('KeepSafe'),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCredential,
        icon: const Icon(Icons.add),
        label: const Text('Add Credential'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFamilySelector(),
        _buildCategorySelector(),
        const Divider(height: 1),
        Expanded(child: _buildCredentialsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomSearchBar(
        controller: _searchController,
        onChanged: _onSearchChanged,
        hintText: 'Search credentials...',
      ),
    );
  }

  Widget _buildFamilySelector() {
    final dataProvider = Provider.of<DataProvider>(context);
    final selectedFamilyId = dataProvider.selectedFamilyMemberId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Family',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              children: [
                // User's own credentials option
                _buildFamilyItem(
                  name: 'Me',
                  isSelected: selectedFamilyId == null,
                  onTap: () => _onFamilyMemberSelected(null),
                  icon: Icons.person,
                ),
                
                // Family members
                ...dataProvider.familyMembers.map((member) {
                  return _buildFamilyItem(
                    name: member.name.split(' ')[0],
                    isSelected: selectedFamilyId == member.id,
                    onTap: () => _onFamilyMemberSelected(member.id),
                    photoUrl: member.photoUrl,
                    memberName: member.name,
                  );
                }),
                
                // Add family member button
                _buildFamilyItem(
                  name: 'Add',
                  isSelected: false,
                  onTap: _addNewFamilyMember,
                  icon: Icons.add,
                  useGrayBackground: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyItem({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    String? photoUrl,
    String? memberName,
    bool useGrayBackground = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 45,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: useGrayBackground
                        ? Theme.of(context).colorScheme.surfaceVariant
                        : isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: useGrayBackground
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                  ),
                )
              else if (memberName != null)
                FamilyAvatar(
                  name: memberName,
                  photoUrl: photoUrl,
                  size: 38,
                  isSelected: isSelected,
                ),
              const SizedBox(height: 4),
              Text(
                name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final dataProvider = Provider.of<DataProvider>(context);
    final selectedCategory = dataProvider.selectedCategory;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              children: [
                // All categories option
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => _onCategorySelected(null),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selectedCategory == null
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                // Category options
                ...Credential.CATEGORIES.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => _onCategorySelected(category),
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsList() {
    final dataProvider = Provider.of<DataProvider>(context);
    final credentials = dataProvider.credentials;
    final selectedFamilyId = dataProvider.selectedFamilyMemberId;
    
    if (credentials.isEmpty) {
      String message;
      
      if (selectedFamilyId != null) {
        final member = dataProvider.familyMembers
            .firstWhere((m) => m.id == selectedFamilyId);
        message = 'No credentials added for ${member.name} yet.';
      } else if (dataProvider.searchQuery.isNotEmpty) {
        message = 'No credentials match your search.';
      } else if (dataProvider.selectedCategory != null) {
        message = 'No credentials in this category.';
      } else {
        message = 'No credentials added yet.';
      }
      
      return EmptyState(
        icon: Icons.vpn_key,
        message: message,
        actionLabel: 'Add Credential',
        onAction: _addNewCredential,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: credentials.length,
      itemBuilder: (context, index) {
        final credential = credentials[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CredentialCard(
            credential: credential,
            onTap: () => _viewCredential(credential),
          ),
        );
      },
    );
  }
} 