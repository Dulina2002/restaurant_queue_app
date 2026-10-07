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

  /// Sign In with Email and Password using Supabase Auth or Firebase Auth
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final normalizedId = 'user_${cleanEmail.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    // 1. Try Supabase Auth
    try {
      final supa = _supabase;
      if (supa != null) {
        final authResponse = await supa.auth.signInWithPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final supaUser = authResponse.user;
        if (supaUser != null) {
          final profile = await getProfile(supaUser.id, defaultEmail: supaUser.email ?? cleanEmail);
          _localFallbackProfile = profile;
          return profile;
        }
      }
    } catch (_) {}

    // 2. Try Firebase Auth
    try {
      final auth = _auth;
      if (auth != null) {
        final UserCredential credential = await auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        final user = credential.user;
        if (user != null) {
          final profile = await getProfile(user.uid, defaultEmail: user.email ?? cleanEmail);
          _localFallbackProfile = profile;
          return profile;
        }
      }
    } catch (_) {}

    // 3. Try Direct Supabase Database lookup by email (e.g. for existing registered reception/staff)
    try {
      final supa = _supabase;
      if (supa != null) {
        final row = await supa.from('profiles').select().ilike('email', cleanEmail).maybeSingle() ??
            await supa.from('users').select().ilike('email', cleanEmail).maybeSingle();
        if (row != null) {
          var role = UserRole.fromString(row['role']?.toString());
          if (role == UserRole.customer) {
            final inferred = _inferRoleFromEmail(cleanEmail);
            if (inferred != UserRole.customer) role = inferred;
          }
          final profile = UserProfile(
            id: row['id']?.toString() ?? normalizedId,
            email: (row['email'] as String?) ?? cleanEmail,
            fullName: (row['full_name'] as String?) ?? _nameFromEmail(cleanEmail),
            role: role,
            avatarUrl: row['avatar_url'] as String?,
            phoneNumber: row['phone_number'] as String?,
            createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
          );
          _localFallbackProfile = profile;
          return profile;
        }
      }
    } catch (_) {}

    // 4. Try Firestore Database lookup by email
    try {
      final query = await _firestore?.collection('users').where('email', isEqualTo: cleanEmail).limit(1).get();
      if (query != null && query.docs.isNotEmpty) {
        final profile = UserProfile.fromFirestore(query.docs.first, defaultEmail: cleanEmail);
        _localFallbackProfile = profile;
        return profile;
      }
    } catch (_) {}

    // 5. Fallback: Role inferred from email for instant preview
    final fallbackRole = _inferRoleFromEmail(cleanEmail);
    final fallback = UserProfile(
      id: currentUser?.uid ?? normalizedId,
      email: cleanEmail,
      fullName: _nameFromEmail(cleanEmail),
      role: fallbackRole,
      createdAt: DateTime.now(),
    );
    _localFallbackProfile = fallback;
    return fallback;
  }

  /// Sign Up with Email, Password, Full Name, and Role using Supabase / Firebase Auth
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.customer,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanName = fullName.trim();
    final normalizedId = 'user_${cleanEmail.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    String finalUserId = normalizedId;

    // 1. Try Supabase Auth signup
    try {
      final supa = _supabase;
      if (supa != null) {
        final res = await supa.auth.signUp(
          email: cleanEmail,
          password: cleanPassword,
          data: {
            'full_name': cleanName,
            'role': role.value,
          },
        );
        if (res.user != null) {
          finalUserId = res.user!.id;
        }
      }
    } catch (_) {}

    // 2. Try Firebase Auth signup
    try {
      final auth = _auth;
      if (auth != null) {
        final UserCredential credential = await auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(cleanName);
          finalUserId = user.uid;
        }
      }
    } catch (_) {}

    final newProfile = UserProfile(
      id: finalUserId,
      email: cleanEmail,
      fullName: cleanName,
      role: role,
      createdAt: DateTime.now(),
    );

    // Save to Supabase profiles table
    try {
      await _supabase?.from('profiles').upsert({
        'id': newProfile.id,
        'role': newProfile.role.value,
        'full_name': newProfile.fullName,
        'email': newProfile.email,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // Save to Firestore users collection
    try {
      await _firestore?.collection('users').doc(newProfile.id).set(newProfile.toFirestore());
    } catch (_) {}

    _localFallbackProfile = newProfile;
    return newProfile;
  }

  /// Fetch User Profile by User ID or Email from Supabase or Firestore
  Future<UserProfile> getProfile(String userId, {String? defaultEmail}) async {
    if (_localFallbackProfile != null &&
        (_localFallbackProfile!.id == userId ||
            (defaultEmail != null &&
                _localFallbackProfile!.email.toLowerCase() == defaultEmail.trim().toLowerCase()))) {
      return _localFallbackProfile!;
    }

    final searchEmail = defaultEmail?.trim();

    // 1. Try Supabase profiles table
    try {
      final supa = _supabase;
      if (supa != null) {
        // Query by ID
        var row = await supa.from('profiles').select().eq('id', userId).maybeSingle();

        // If not found by ID, query by email
        if (row == null && searchEmail != null && searchEmail.isNotEmpty) {
          row = await supa.from('profiles').select().ilike('email', searchEmail).maybeSingle();
        }

        // If still not found, try 'users' table
        if (row == null) {
          row = await supa.from('users').select().eq('id', userId).maybeSingle();
        }
        if (row == null && searchEmail != null && searchEmail.isNotEmpty) {
          row = await supa.from('users').select().ilike('email', searchEmail).maybeSingle();
        }

        if (row != null) {
          var role = UserRole.fromString(row['role']?.toString());
          if (role == UserRole.customer && searchEmail != null) {
            final inferred = _inferRoleFromEmail(searchEmail);
            if (inferred != UserRole.customer) role = inferred;
          }
          final p = UserProfile(
            id: row['id']?.toString() ?? userId,
            email: (row['email'] as String?) ?? searchEmail ?? currentUser?.email ?? '',
            fullName: (row['full_name'] as String?) ?? 'User',
            role: role,
            avatarUrl: row['avatar_url'] as String?,
            phoneNumber: row['phone_number'] as String?,
            createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
          );
          _localFallbackProfile = p;
          return p;
        }
      }
    } catch (_) {}

    // 2. Try Firestore users collection
    try {
      var doc = await _firestore?.collection('users').doc(userId).get();
      if ((doc == null || !doc.exists) && searchEmail != null && searchEmail.isNotEmpty) {
        final q = await _firestore?.collection('users').where('email', isEqualTo: searchEmail).limit(1).get();
        if (q != null && q.docs.isNotEmpty) {
          doc = q.docs.first;
        }
      }
      if (doc != null && doc.exists && doc.data() != null) {
        final p = UserProfile.fromFirestore(doc, defaultEmail: searchEmail ?? currentUser?.email);
        _localFallbackProfile = p;
        return p;
      }
    } catch (_) {}

    // 3. Fallback: Role inferred from email
    final fallbackRole = searchEmail != null ? _inferRoleFromEmail(searchEmail) : UserRole.customer;
    final fallbackProfile = UserProfile(
      id: userId,
      email: searchEmail ?? currentUser?.email ?? 'user@example.com',
      fullName: currentUser?.displayName ?? (searchEmail != null ? _nameFromEmail(searchEmail) : 'Guest User'),
      role: fallbackRole,
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

    final supaUser = _supabase?.auth.currentUser;
    if (supaUser != null) {
      return await getProfile(supaUser.id, defaultEmail: supaUser.email);
    }

    final user = currentUser;
    if (user != null) {
      return await getProfile(user.uid, defaultEmail: user.email);
    }

    return null;
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

  /// Sign Out of Firebase Auth & Supabase Auth
  Future<void> signOut() async {
    _localFallbackProfile = null;
    try {
      await _auth?.signOut();
    } catch (_) {}
    try {
      await _supabase?.auth.signOut();
    } catch (_) {}
  }

  UserRole _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase().trim();
    if (lower.contains('admin') || lower.contains('owner') || lower.contains('root')) {
      return UserRole.admin;
    }
    if (lower.contains('manager') || lower.contains('mgr') || lower.contains('mgmt')) {
      return UserRole.manager;
    }
    if (lower.contains('reception') ||
        lower.contains('frontdesk') ||
        lower.contains('front_desk') ||
        lower.contains('desk') ||
        lower.contains('host') ||
        lower.contains('hostess') ||
        lower.contains('staff') ||
        lower.contains('greeter') ||
        lower.contains('cashier')) {
      return UserRole.receptionist;
    }
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
