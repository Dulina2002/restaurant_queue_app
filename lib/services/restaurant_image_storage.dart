import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent & synchronous image lookup service for restaurants.
///
/// Ensures restaurant images (such as Pizza Hub or newly added/edited restaurants)
/// remain completely persistent on the customer and admin interfaces, even when
/// the remote database table schema does not yet have an `image_url` column or
/// during network drops.
class RestaurantImageStorage {
  static final RestaurantImageStorage _instance = RestaurantImageStorage._internal();
  factory RestaurantImageStorage() => _instance;
  RestaurantImageStorage._internal();

  static const String _prefPrefix = 'resto_img_';
  static const String _allKeysPref = 'resto_img_all_keys';

  final Map<String, String> _memoryCache = {};
  bool _initialized = false;

  /// Curated culinary fallbacks for popular cuisines and food types
  static const Map<String, String> culinaryFallbacks = {
    'pizza': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=80',
    'burger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1200&q=80',
    'italian': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
    'seafood': 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80',
    'crab': 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1200&q=80',
    'indian': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=1200&q=80',
    'japanese': 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?auto=format&fit=crop&w=1200&q=80',
    'sushi': 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?auto=format&fit=crop&w=1200&q=80',
    'sugarfish': 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?auto=format&fit=crop&w=1200&q=80',
    'fish': 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?auto=format&fit=crop&w=1200&q=80',
    'ramen': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',
    'steak': 'https://images.unsplash.com/photo-1558030006-450675393462?auto=format&fit=crop&w=1200&q=80',
    'mexican': 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=1200&q=80',
    'taco': 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=1200&q=80',
    'cafe': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80',
    'coffee': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80',
    'bakery': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',
    'bistro': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
  };

  /// Initialize and load saved image URLs from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getStringList(_allKeysPref) ?? [];
      for (final key in allKeys) {
        final val = prefs.getString('$_prefPrefix$key');
        if (val != null && val.isNotEmpty) {
          _memoryCache[key] = val;
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('RestaurantImageStorage init error: $e');
    }
  }

  /// Normalize a restaurant name or ID for fuzzy dictionary matching
  static String normalizeKey(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), '');
  }

  /// Create a slug representation
  static String slugKey(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Synchronously retrieve a stored restaurant image URL or a matching culinary fallback
  String? getImage({
    String? id,
    String? name,
    String? cuisine,
    bool enableCulinaryFallback = true,
  }) {
    // 1. Direct ID lookup
    if (id != null && id.trim().isNotEmpty) {
      final trimmedId = id.trim();
      if (_memoryCache.containsKey(trimmedId) && _memoryCache[trimmedId]!.isNotEmpty) {
        return _memoryCache[trimmedId];
      }
      final slugId = slugKey(id);
      if (_memoryCache.containsKey(slugId) && _memoryCache[slugId]!.isNotEmpty) {
        return _memoryCache[slugId];
      }
    }

    // 2. Normalized Name lookup
    if (name != null && name.trim().isNotEmpty) {
      final normName = normalizeKey(name);
      if (_memoryCache.containsKey(normName) && _memoryCache[normName]!.isNotEmpty) {
        return _memoryCache[normName];
      }
      final slugName = slugKey(name);
      if (_memoryCache.containsKey(slugName) && _memoryCache[slugName]!.isNotEmpty) {
        return _memoryCache[slugName];
      }
      // Check partial matches in memory cache
      for (final entry in _memoryCache.entries) {
        if (normName.contains(entry.key) || entry.key.contains(normName)) {
          if (entry.value.isNotEmpty) return entry.value;
        }
      }
    }

    // 3. Intelligent culinary fallback based on name or cuisine
    if (enableCulinaryFallback) {
      final combined = '${name ?? ''} ${cuisine ?? ''}'.toLowerCase();
      for (final key in culinaryFallbacks.keys) {
        if (combined.contains(key)) {
          return culinaryFallbacks[key];
        }
      }
    }

    return null;
  }

  /// Check if a custom admin-uploaded or explicitly assigned image exists
  bool hasCustomImage({String? id, String? name}) {
    return getImage(id: id, name: name, enableCulinaryFallback: false) != null;
  }

  /// Save restaurant image URL under ID, normalized name, and slug
  Future<void> saveImage({
    required String id,
    required String name,
    required String imageUrl,
  }) async {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) return;

    final trimmedId = id.trim();
    final normName = normalizeKey(name);
    final slugName = slugKey(name);
    final slugId = slugKey(id);

    // Save to memory cache immediately
    if (trimmedId.isNotEmpty) _memoryCache[trimmedId] = cleanUrl;
    if (slugId.isNotEmpty) _memoryCache[slugId] = cleanUrl;
    if (normName.isNotEmpty) _memoryCache[normName] = cleanUrl;
    if (slugName.isNotEmpty) _memoryCache[slugName] = cleanUrl;

    // Persist to SharedPreferences in background
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = (prefs.getStringList(_allKeysPref) ?? []).toSet();

      final keysToSave = <String>{
        if (trimmedId.isNotEmpty) trimmedId,
        if (slugId.isNotEmpty) slugId,
        if (normName.isNotEmpty) normName,
        if (slugName.isNotEmpty) slugName,
      };

      for (final k in keysToSave) {
        await prefs.setString('$_prefPrefix$k', cleanUrl);
        allKeys.add(k);
      }

      await prefs.setStringList(_allKeysPref, allKeys.toList());
    } catch (e) {
      debugPrint('RestaurantImageStorage saveImage error: $e');
    }
  }

  /// Store a map of fallback images in batch
  void primeMemoryCache(Map<String, String> entries) {
    for (final e in entries.entries) {
      _memoryCache[e.key] = e.value;
      final norm = normalizeKey(e.key);
      if (norm.isNotEmpty) _memoryCache[norm] = e.value;
      final slug = slugKey(e.key);
      if (slug.isNotEmpty) _memoryCache[slug] = e.value;
    }
  }
}
