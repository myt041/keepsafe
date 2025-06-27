import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyAvatar extends StatefulWidget {
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
  State<FamilyAvatar> createState() => _FamilyAvatarState();
  
  // Static method to reset all color assignments (useful for migration or debugging)
  static Future<void> resetAllColorAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys that start with 'avatar_color_'
      final keys = prefs.getKeys();
      final colorKeys = keys.where((key) => key.startsWith('avatar_color_')).toList();
      
      // Remove all color assignments
      for (final key in colorKeys) {
        await prefs.remove(key);
      }
      
      // Clear all usage flags
      for (int i = 0; i < 18; i++) {
        await prefs.remove('color_used_$i');
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  // Static method to get color for a name without creating a widget
  static Future<Color> getColorForName(String name, bool isDark) async {
    if (name.isEmpty) {
      return isDark ? Colors.grey.shade800 : Colors.grey;
    }
    
    // Extended color palette
    final List<Color> lightColors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
      Colors.pink.shade300,
      Colors.amber.shade300,
      Colors.cyan.shade300,
      Colors.lime.shade300,
      Colors.deepPurple.shade300,
      Colors.deepOrange.shade300,
      Colors.lightBlue.shade300,
      Colors.lightGreen.shade300,
      Colors.brown.shade300,
      Colors.blueGrey.shade300,
      Colors.yellow.shade600,
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
      Colors.amber.shade700,
      Colors.cyan.shade700,
      Colors.lime.shade700,
      Colors.deepPurple.shade700,
      Colors.deepOrange.shade700,
      Colors.lightBlue.shade700,
      Colors.lightGreen.shade700,
      Colors.brown.shade700,
      Colors.blueGrey.shade700,
      Colors.yellow.shade800,
    ];
    
    final colors = isDark ? darkColors : lightColors;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorKey = 'avatar_color_${name.toLowerCase().replaceAll(' ', '_')}';
      
      // Check if this name already has an assigned color
      final savedColorIndex = prefs.getInt(colorKey);
      if (savedColorIndex != null && savedColorIndex < colors.length) {
        return colors[savedColorIndex];
      }
      
      // For existing members without saved colors, generate a consistent color based on name hash
      final hash = name.codeUnits.fold<int>(0, (prev, element) => prev + element);
      final consistentIndex = hash % colors.length;
      
      // Check if this consistent color is already used by another member
      final usedIndices = <int>{};
      for (int i = 0; i < colors.length; i++) {
        final isUsed = prefs.getBool('color_used_$i') ?? false;
        if (isUsed) {
          usedIndices.add(i);
        }
      }
      
      int selectedIndex;
      
      // If the consistent color is not used, use it
      if (!usedIndices.contains(consistentIndex)) {
        selectedIndex = consistentIndex;
      } else {
        // If the consistent color is used, find the first unused color
        selectedIndex = 0;
        for (int i = 0; i < colors.length; i++) {
          if (!usedIndices.contains(i)) {
            selectedIndex = i;
            break;
          }
        }
        
        // If all colors are used, reset the usage tracking and start over
        if (usedIndices.length >= colors.length) {
          // Clear all usage flags
          for (int i = 0; i < colors.length; i++) {
            await prefs.remove('color_used_$i');
          }
          selectedIndex = 0;
        }
      }
      
      // Mark this color as used
      await prefs.setBool('color_used_$selectedIndex', true);
      
      // Save the color assignment for this name
      await prefs.setInt(colorKey, selectedIndex);
      
      return colors[selectedIndex];
    } catch (e) {
      // Fallback to hash-based color if there's an error
      final hash = name.codeUnits.fold<int>(0, (prev, element) => prev + element);
      return colors[hash % colors.length];
    }
  }
}

class _FamilyAvatarState extends State<FamilyAvatar> {
  Color? _avatarColor;
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    _loadAvatarColor();
  }

  @override
  void didUpdateWidget(FamilyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _loadAvatarColor();
    }
  }

  Future<void> _loadAvatarColor() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    final color = await FamilyAvatar.getColorForName(widget.name, isDark);
    if (mounted) {
      setState(() {
        _avatarColor = color;
        _isLoadingColor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    final borderColor = widget.isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final borderWidth = widget.isSelected ? 2.0 : 0.0;

    // Generate exactly 2 character initials
    final initials = _generateInitials(widget.name);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
          ? ClipOval(
              clipBehavior: Clip.antiAlias,
              child: _buildImage(widget.photoUrl!, initials, isDark),
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
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildInitialsAvatar(initials, isDark);
      },
    );
  }

  Widget _buildNetworkImage(String photoUrl, String initials, bool isDark) {
    return Image.network(
      photoUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingAvatar(context);
      },
      errorBuilder: (context, error, stackTrace) {
        // If network image fails, fall back to initials
        return _buildInitialsAvatar(initials, isDark);
      },
    );
  }

  Widget _buildLoadingAvatar(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size / 3,
          height: widget.size / 3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, bool isDark) {
    // Use loading color if color is still being loaded
    final avatarColor = _avatarColor ?? (isDark ? Colors.grey.shade800 : Colors.grey);
    final textColor = _getTextColorForBackground(avatarColor);
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
      ),
      child: Center(
        child: _isLoadingColor
            ? SizedBox(
                width: widget.size / 3,
                height: widget.size / 3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Text(
                initials,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size / 3,
                ),
              ),
      ),
    );
  }

  // Generate exactly 2 character initials
  String _generateInitials(String name) {
    if (name.isEmpty) return '??';
    
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    
    if (words.isEmpty) return '??';
    
    if (words.length == 1) {
      // Single word: use first two characters or repeat first character
      final firstChar = words[0][0].toUpperCase();
      return words[0].length > 1 ? '$firstChar${words[0][1].toUpperCase()}' : '$firstChar$firstChar';
    } else {
      // Multiple words: use first letter of first and last word
      final firstChar = words[0][0].toUpperCase();
      final lastChar = words.last[0].toUpperCase();
      return '$firstChar$lastChar';
    }
  }

  // Get appropriate text color based on background color
  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculate the luminance - if it's dark, use white text, otherwise black
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}