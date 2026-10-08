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
}
