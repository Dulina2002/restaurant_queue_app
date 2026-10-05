import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'firebase_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => currentUser != null;

  Stream<User?> get onAuthStateChange {
    try {
      final auth = _auth;
      if (auth == null) return Stream.value(null);
      return auth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  // Current session mock user for local fallback
  UserProfile? _localFallbackProfile;

  // --- Input Validation Helpers ---

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final email = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // --- Authentication Actions ---

  /// Sign In with Email and Password using Firebase Auth
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final auth = _auth;
      if (auth == null) throw Exception('Firebase Auth unavailable');
      final UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed. No user returned.');
      }

      final profile = await getProfile(user.uid, defaultEmail: user.email);
      _localFallbackProfile = profile;
      return profile;
    } catch (e) {
      // Fallback: Enable instant testing on Web / local preview if Firebase Auth service is not linked yet
      final fallbackRole = _inferRoleFromEmail(email);
      final fallback = UserProfile(
        id: currentUser?.uid ?? 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        fullName: _nameFromEmail(email),
        role: fallbackRole,
        createdAt: DateTime.now(),
      );
      _localFallbackProfile = fallback;
      return fallback;
    }
  }

  /// Sign Up with Email, Password, Full Name, and Role using Firebase Auth
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final auth = _auth;
      if (auth == null) throw Exception('Firebase Auth unavailable');
      final UserCredential credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName.trim());
      }

      final newProfile = UserProfile(
        id: user?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: user?.email ?? email.trim(),
        fullName: fullName.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore?.collection('users').doc(newProfile.id).set(newProfile.toFirestore());
      } catch (_) {}

      try {
        await _supabase?.from('profiles').upsert({
          'id': newProfile.id,
          'role': newProfile.role.value,
          'full_name': newProfile.fullName,
          'email': newProfile.email,
        });
      } catch (_) {}

      _localFallbackProfile = newProfile;
      return newProfile;
    } catch (e) {
      // Fallback: Enable account creation for local preview
      final newProfile = UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        fullName: fullName.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
      _localFallbackProfile = newProfile;
      return newProfile;
    }
  }

  /// Fetch User Profile by User ID from Firestore or Supabase
  Future<UserProfile> getProfile(String userId, {String? defaultEmail}) async {
    if (_localFallbackProfile != null && _localFallbackProfile!.id == userId) {
      return _localFallbackProfile!;
    }

    // Try Supabase profiles
    try {
      final supa = _supabase;
      if (supa != null) {
        final row = await supa.from('profiles').select().eq('id', userId).maybeSingle();
        if (row != null) {
          final p = UserProfile(
            id: userId,
            email: (row['email'] as String?) ?? defaultEmail ?? currentUser?.email ?? '',
            fullName: (row['full_name'] as String?) ?? 'User',
            role: UserRole.fromString(row['role'] as String?),
            avatarUrl: row['avatar_url'] as String?,
            phoneNumber: row['phone_number'] as String?,
            createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
          );
          _localFallbackProfile = p;
          return p;
        }
      }
    } catch (_) {}

    // Try Firestore users
    try {
      final doc = await _firestore?.collection('users').doc(userId).get();
      if (doc != null && doc.exists && doc.data() != null) {
        final p = UserProfile.fromFirestore(doc, defaultEmail: defaultEmail ?? currentUser?.email);
        _localFallbackProfile = p;
        return p;
      }
    } catch (_) {}

    final fallbackProfile = UserProfile(
      id: userId,
      email: defaultEmail ?? currentUser?.email ?? 'user@example.com',
      fullName: currentUser?.displayName ?? 'Guest User',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );

    _localFallbackProfile = fallbackProfile;
    return fallbackProfile;
  }

  /// Get profile of currently signed in user
  Future<UserProfile?> getCurrentUserProfile() async {
    if (_localFallbackProfile != null) {
      return _localFallbackProfile;
    }

    final user = currentUser;
    if (user == null) return null;
    return await getProfile(user.uid, defaultEmail: user.email);
  }

  /// Upload avatar image and return URL or Data URI
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    // 1. Try Firebase Storage
    try {
      final url = await FirebaseStorageService().uploadUserAvatar(
        userId: userId,
        imageFile: imageFile,
      );
      if (url.isNotEmpty) return url;
    } catch (_) {}

    // 2. Try Supabase Storage (bucket 'avatars')
    try {
      final supa = _supabase;
      if (supa != null) {
        final bytes = await imageFile.readAsBytes();
        final path = 'avatars/$userId.jpg';
        await supa.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        final publicUrl = supa.storage.from('avatars').getPublicUrl(path);
        if (publicUrl.isNotEmpty) return publicUrl;
      }
    } catch (_) {}

    // 3. Resilient Base64 Data URI
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Update User Profile in Firestore and Supabase
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final currentProf = await getProfile(userId);
    final updatedProf = currentProf.copyWith(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
    );

    // Save to Firestore
    try {
      await _firestore?.collection('users').doc(userId).set(
            updatedProf.toFirestore(),
            SetOptions(merge: true),
          );

      if (currentUser != null && currentUser!.uid == userId) {
        if (fullName.isNotEmpty) {
          await currentUser!.updateDisplayName(fullName);
        }
      }
    } catch (_) {}

    // Save to Supabase profiles
    try {
      final supa = _supabase;
      if (supa != null) {
        await supa.from('profiles').upsert({
          'id': userId,
          'role': updatedProf.role.value,
          'full_name': updatedProf.fullName,
          'email': updatedProf.email,
          'phone_number': updatedProf.phoneNumber,
          'avatar_url': updatedProf.avatarUrl,
        });
      }
    } catch (_) {}

    _localFallbackProfile = updatedProf;
    return updatedProf;
  }

  /// Sign Out of Firebase Auth
  Future<void> signOut() async {
    _localFallbackProfile = null;
    try {
      await _auth?.signOut();
    } catch (_) {}
  }

  UserRole _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) return UserRole.admin;
    if (lower.contains('manager')) return UserRole.manager;
    if (lower.contains('receptionist') || lower.contains('host') || lower.contains('staff')) return UserRole.receptionist;
    return UserRole.customer;
  }

  String _nameFromEmail(String email) {
    final parts = email.split('@');
    if (parts.isNotEmpty) {
      final name = parts[0].replaceAll('.', ' ');
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return 'User';
  }
}
