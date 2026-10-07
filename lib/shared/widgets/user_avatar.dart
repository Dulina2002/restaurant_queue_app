import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final UserProfile? profile;
  final String? avatarUrl;
  final File? imageFile;
  final String? name;
  final double size;
  final bool isEditable;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Border? border;

  const UserAvatar({
    super.key,
    this.profile,
    this.avatarUrl,
    this.imageFile,
    this.name,
    this.size = 56,
    this.isEditable = false,
    this.onTap,
    this.onEditTap,
    this.backgroundColor,
    this.textColor,
    this.border,
  });

  String get _displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (profile != null && profile!.fullName.trim().isNotEmpty) return profile!.fullName.trim();
    return 'User';
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String? get _resolvedUrl {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return avatarUrl!.trim();
    }
    if (profile?.avatarUrl != null && profile!.avatarUrl!.trim().isNotEmpty) {
      return profile!.avatarUrl!.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _resolvedUrl;
    final initials = _getInitials(_displayName);
    final bgColor = backgroundColor ?? const Color(0xFFD1FAE5);
    final fgColor = textColor ?? const Color(0xFF065F46);

    Widget avatarContent;

    if (imageFile != null) {
      avatarContent = Image.file(
        imageFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(initials, bgColor, fgColor),
      );
    } else if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      if (effectiveUrl.startsWith('data:image/')) {
        try {
          final base64String = effectiveUrl.split(',').last;
          final bytes = base64Decode(base64String);
          avatarContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _buildInitials(initials, bgColor, fgColor),
          );
        } catch (_) {
          avatarContent = _buildInitials(initials, bgColor, fgColor);
        }
      } else if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
        avatarContent = Image.network(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: bgColor,
              alignment: Alignment.center,
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildInitials(initials, bgColor, fgColor),
        );
      } else if (effectiveUrl.startsWith('/') || effectiveUrl.startsWith('file://')) {
        final filePath = effectiveUrl.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          avatarContent = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildInitials(initials, bgColor, fgColor),
          );
        } else {
          avatarContent = _buildInitials(initials, bgColor, fgColor);
        }
      } else {
        avatarContent = _buildInitials(initials, bgColor, fgColor);
      }
    } else {
      avatarContent = _buildInitials(initials, bgColor, fgColor);
    }

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: border ?? Border.all(color: Colors.white, width: size > 60 ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );

    if (isEditable) {
      final badgeSize = (size * 0.34).clamp(24.0, 36.0);
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditTap ?? onTap,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: badgeSize * 0.55,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildInitials(String initials, Color bgColor, Color fgColor) {
    final fontSize = (size * 0.38).clamp(11.0, 32.0);
    return Container(
      width: size,
      height: size,
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: fgColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
