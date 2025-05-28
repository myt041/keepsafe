import 'dart:io';
import 'package:flutter/material.dart';
import 'package:keepsafe/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/providers/theme_provider.dart';

class FamilyAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final bool isSelected;

  const FamilyAvatar({
    Key? key,
    required this.name,
    this.photoUrl,
    required this.size,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    final borderColor = isSelected ? AppTheme.primaryColor : Colors.transparent;
    final borderWidth = isSelected ? 2.0 : 0.0;

    // Use initials if no photo is available
    final initials = name.isNotEmpty
        ? name.split(' ').map((part) => part.isNotEmpty ? part[0] : '').join('')
        : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              clipBehavior: Clip.antiAlias,
              child: _buildImage(photoUrl!, initials, isDark),
            )
          : _buildInitialsAvatar(initials, isDark),
    );
  }

  Widget _buildImage(String photoUrl, String initials, bool isDark) {
    // Check if photoUrl is a local file path
    if (photoUrl.startsWith('/')) {
      return _buildLocalImage(photoUrl, initials, isDark);
    } else {
      return _buildNetworkImage(photoUrl, initials, isDark);
    }
  }

  Widget _buildLocalImage(String photoUrl, String initials, bool isDark) {
    return Image.file(
      File(photoUrl),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildInitialsAvatar(initials, isDark);
      },
    );
  }

  Widget _buildNetworkImage(String photoUrl, String initials, bool isDark) {
    return Image.network(
      photoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingAvatar();
      },
      errorBuilder: (context, error, stackTrace) {
        // If network image fails, fall back to initials
        return _buildInitialsAvatar(initials, isDark);
      },
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
      ),
      child: Center(
        child: SizedBox(
          width: size / 3,
          height: size / 3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, bool isDark) {
    // Handle empty initials
    final displayInitials = initials.isEmpty ? '?' : initials;
    
    final avatarColor = _getColorFromName(name, isDark);
    final textColor = _getTextColorForBackground(avatarColor);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
      ),
      child: Center(
        child: Text(
          displayInitials.substring(0, displayInitials.length > 2 ? 2 : displayInitials.length),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: size / 3,
          ),
        ),
      ),
    );
  }

  // Generate a consistent color based on the name
  Color _getColorFromName(String name, bool isDark) {
    if (name.isEmpty) {
      return isDark ? Colors.grey.shade800 : Colors.grey;
    }
    
    final List<Color> lightColors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
      Colors.pink.shade300,
    ];
    
    final List<Color> darkColors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.red.shade700,
      Colors.teal.shade700,
      Colors.indigo.shade700,
      Colors.pink.shade700,
    ];
    
    final colors = isDark ? darkColors : lightColors;
    final hash = name.codeUnits.fold<int>(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }
  
  // Get appropriate text color based on background color
  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculate the luminance - if it's dark, use white text, otherwise black
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}