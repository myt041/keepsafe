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
    _initializeData();
  }

  Future<void> _initializeData() async {
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
        title: const Text('KeepSafe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCredential,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFamilySelector(),
        _buildCategorySelector(),
        const Divider(),
        Expanded(child: _buildCredentialsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
    
    return SizedBox(
      height: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Family',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: useGrayBackground
                        ? Colors.grey.withOpacity(0.2)
                        : isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected || useGrayBackground ? Colors.white : Colors.white70,
                  ),
                )
              else if (memberName != null)
                FamilyAvatar(
                  name: memberName,
                  photoUrl: photoUrl,
                  size: 50,
                  isSelected: isSelected,
                ),
              const SizedBox(height: 4),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium,
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
    
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: [
          // All categories option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              onSelected: (_) => _onCategorySelected(null),
            ),
          ),
          
          // Category options
          ...Credential.CATEGORIES.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (_) => _onCategorySelected(category),
              ),
            );
          }),
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