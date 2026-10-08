import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/restaurant_image_storage.dart';

/// A robust image rendering widget that safely handles:
/// - Local File (`imageFile`)
/// - Remote HTTP/HTTPS URLs
/// - Base64 Data URIs (`data:image/...`)
/// - Local File paths (`/path...` or `file://...`)
/// - Name-based persistent local storage lookup
/// - Intelligent culinary fallbacks (e.g. Pizza Hub, Seafood, Italian)
/// - Graceful placeholder fallback with subtle restaurant branding
class RestaurantImage extends StatelessWidget {
  final String? imageUrl;
  final String? restaurantId;
  final String? restaurantName;
  final String? cuisine;
  final File? imageFile;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const RestaurantImage({
    super.key,
    this.imageUrl,
    this.restaurantId,
    this.restaurantName,
    this.cuisine,
    this.imageFile,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    // 1. Direct File provided
    if (imageFile != null) {
      content = Image.file(
        imageFile!,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
      );
    } else {
      // 2. Check if a custom admin-uploaded or explicitly assigned image exists in storage
      // This MUST take absolute priority over generic culinary fallbacks!
      final customSaved = RestaurantImageStorage().getImage(
        id: restaurantId,
        name: restaurantName,
        enableCulinaryFallback: false,
      );

      var resolvedUrl = (customSaved != null && customSaved.trim().isNotEmpty)
          ? customSaved.trim()
          : (imageUrl?.trim() ?? '');

      if (resolvedUrl.isEmpty) {
        resolvedUrl = RestaurantImageStorage().getImage(
          id: restaurantId,
          name: restaurantName,
          cuisine: cuisine,
          enableCulinaryFallback: true,
        ) ?? '';
      }

      if (resolvedUrl.isNotEmpty) {
        // Strip surrounding quotes or formatting artifacts
        final cleanUrl = resolvedUrl
            .replaceAll(RegExp(r'^["' "'" r']+|["' "'" r']+$'), '')
            .trim();

        final isLocalFile = cleanUrl.startsWith('/') ||
            cleanUrl.startsWith('file://') ||
            RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(cleanUrl);

        if (cleanUrl.contains('base64,')) {
          try {
            final base64String = cleanUrl
                .split('base64,')
                .last
                .replaceAll(RegExp(r'\s+'), '');
            final bytes = base64Decode(base64String);
            content = Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
            );
          } catch (_) {
            content = _buildPlaceholder();
          }
        } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
          content = Image.network(
            cleanUrl,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                width: width,
                height: height,
                color: const Color(0xFF14382A),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              );
            },
            errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
          );
        } else if (isLocalFile) {
          final filePath = cleanUrl.replaceFirst('file://', '');
          final file = File(filePath);
          if (file.existsSync()) {
            content = Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
            );
          } else {
            content = _buildPlaceholder();
          }
        } else {
          content = _buildPlaceholder();
        }
      } else {
        content = _buildPlaceholder();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    // Check if culinary fallback can provide a themed image
    final culinaryFallback = RestaurantImageStorage().getImage(
      name: restaurantName,
      cuisine: cuisine,
    );
    if (culinaryFallback != null &&
        culinaryFallback != imageUrl &&
        (culinaryFallback.startsWith('http://') || culinaryFallback.startsWith('https://'))) {
      return Image.network(
        culinaryFallback,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallbackContainer(),
      );
    }

    return _buildFallbackContainer();
  }

  Widget _buildFallbackContainer() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF0B2B1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: height != null ? (height! * 0.45).clamp(24.0, 72.0) : 42,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
