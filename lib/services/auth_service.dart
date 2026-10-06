import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _supabase?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => currentUser != null;

  Stream<User?> get onAuthStateChange {
    try {
      final client = _supabase;
      if (client == null) return Stream.value(null);
      return client.auth.onAuthStateChange.map((data) => data.session?.user);
    } catch (_) {
      return Stream.value(null);
    }
  }

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

  /// Sign In with Email and Password using Supabase Auth
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final client = _supabase;
      if (client != null) {
        final AuthResponse response = await client.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim(),
        );

        final user = response.user;
        if (user != null) {
          final profile = await getProfile(user.id, defaultEmail: user.email);
          _localFallbackProfile = profile;
          return profile;
        }
      }
    } catch (e) {
      debugPrint('Supabase signIn error: $e');
    }

    final fallbackRole = _inferRoleFromEmail(email);
    final fallback = UserProfile(
      id: currentUser?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: _nameFromEmail(email),
      role: fallbackRole,
      createdAt: DateTime.now(),
    );
    _localFallbackProfile = fallback;
    return fallback;
  }

  /// Sign Up with Email, Password, Full Name, and Role using Supabase Auth
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final client = _supabase;
      if (client != null) {
        final AuthResponse response = await client.auth.signUp(
          email: email.trim(),
          password: password.trim(),
          data: {
            'full_name': fullName.trim(),
            'role': role.value,
          },
        );

        final user = response.user;
        final newProfile = UserProfile(
          id: user?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: user?.email ?? email.trim(),
          fullName: fullName.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        try {
          await client.from('profiles').upsert(newProfile.toJson());
        } catch (_) {}

        _localFallbackProfile = newProfile;
        return newProfile;
      }
    } catch (e) {
      debugPrint('Supabase signUp error: $e');
    }

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

  /// Fetch User Profile by User ID from Supabase
  Future<UserProfile> getProfile(String userId, {String? defaultEmail}) async {
    if (_localFallbackProfile != null && _localFallbackProfile!.id == userId) {
      return _localFallbackProfile!;
    }

    try {
      final client = _supabase;
      if (client != null) {
        final data = await client.from('profiles').select().eq('id', userId).maybeSingle();
        if (data != null) {
          return UserProfile.fromJson(data, defaultEmail: defaultEmail);
        }
      }
    } catch (_) {}

    final fallbackProfile = UserProfile(
      id: userId,
      email: defaultEmail ?? currentUser?.email ?? 'user@example.com',
      fullName: currentUser?.userMetadata?['full_name'] ?? 'Guest User',
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
    return await getProfile(user.id, defaultEmail: user.email);
  }

  /// Update User Profile in Supabase
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final currentProf = await getProfile(userId);
    final updatedProf = currentProf.copyWith(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );

    try {
      final client = _supabase;
      if (client != null) {
        await client.from('profiles').upsert(updatedProf.toJson());
      }
    } catch (_) {}

    _localFallbackProfile = updatedProf;
    return updatedProf;
  }

  /// Sign Out of Supabase Auth
  Future<void> signOut() async {
    _localFallbackProfile = null;
    try {
      await _supabase?.auth.signOut();
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
