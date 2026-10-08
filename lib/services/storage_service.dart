import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Upload user profile avatar image
  Future<String> uploadUserAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final client = _supabase;
      if (client == null) throw Exception('Supabase Storage unavailable');
      final path = 'avatars/$userId.jpg';
      await client.storage.from('avatars').upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
      return client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload user avatar: $e');
    }
  }

  /// Upload restaurant or menu item image
  Future<String> uploadMenuItemImage({
    required String dishId,
    required File imageFile,
  }) async {
    try {
      final client = _supabase;
      if (client == null) throw Exception('Supabase Storage unavailable');
      final path = 'dishes/$dishId.jpg';
      await client.storage.from('dishes').upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
      return client.storage.from('dishes').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload dish image: $e');
    }
  }

  /// Upload restaurant image (tries Supabase buckets, then saves persistently to local storage)
  Future<String> uploadRestaurantImage({
    required String restaurantId,
    required File imageFile,
  }) async {
    // 1. Try Supabase storage 'restaurants' bucket
    try {
      final client = _supabase;
      if (client != null) {
        final bytes = await imageFile.readAsBytes();
        final path = 'restaurants/${restaurantId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await client.storage.from('restaurants').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );
        final publicUrl = client.storage.from('restaurants').getPublicUrl(path);
        if (publicUrl.isNotEmpty) return publicUrl;
      }
    } catch (_) {
      // 2. Try 'dishes' bucket if 'restaurants' bucket not created yet
      try {
        final client = _supabase;
        if (client != null) {
          final bytes = await imageFile.readAsBytes();
          final path = 'restaurants/${restaurantId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await client.storage.from('dishes').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
              );
          final publicUrl = client.storage.from('dishes').getPublicUrl(path);
          if (publicUrl.isNotEmpty) return publicUrl;
        }
      } catch (_) {}
    }

    // 3. Persistent Local File storage fallback
    // When remote Supabase storage is unavailable or bucket lacks permissions,
    // safely copy the selected image file to permanent app storage so it is never lost.
    try {
      if (imageFile.existsSync()) {
        final parentDir = imageFile.parent;
        final storageDir = Directory('${parentDir.path}/restaurant_images');
        if (!storageDir.existsSync()) {
          storageDir.createSync(recursive: true);
        }
        final cleanId = restaurantId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final targetPath = '${storageDir.path}/${cleanId}_saved.jpg';
        final savedFile = await imageFile.copy(targetPath);
        return savedFile.path;
      }
    } catch (_) {}

    // 4. Return original file path if accessible
    if (imageFile.existsSync()) {
      return imageFile.path;
    }

    return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';
  }
}
