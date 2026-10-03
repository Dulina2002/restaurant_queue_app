import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload user profile avatar image
  Future<String> uploadUserAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
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
      final ref = _storage.ref().child('dishes/$dishId.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload dish image: $e');
    }
  }
}
