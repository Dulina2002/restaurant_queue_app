import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

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

  /// Sign In with Email and Password
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed. No user returned.');
      }

      final profile = await getProfile(user.id, defaultEmail: user.email);
      return profile;
    } on AuthException catch (e) {
      throw Exception(_parseAuthException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Sign Up with Email, Password, Full Name, and Role
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'full_name': fullName.trim(),
          'role': role.value,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Account creation failed. Please try again.');
      }

      // Upsert profile in `profiles` table
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName.trim(),
          'role': role.value,
        });
      } catch (_) {
        // Continue even if table trigger already handles profile creation
      }

      return UserProfile(
        id: user.id,
        email: user.email ?? email.trim(),
        fullName: fullName.trim(),
        role: role,
      );
    } on AuthException catch (e) {
      throw Exception(_parseAuthException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Fetch User Profile by User ID
  Future<UserProfile> getProfile(String userId, {String? defaultEmail}) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response, defaultEmail: defaultEmail ?? currentUser?.email);
      }

      // Fallback: If profile row does not exist yet, infer or create default
      final fallbackProfile = UserProfile(
        id: userId,
        email: defaultEmail ?? currentUser?.email ?? '',
        fullName: currentUser?.userMetadata?['full_name'] as String? ?? 'Guest User',
        role: UserRole.fromString(currentUser?.userMetadata?['role'] as String?),
      );

      // Attempt to create profile row
      try {
        await _client.from('profiles').upsert(fallbackProfile.toJson());
      } catch (_) {}

      return fallbackProfile;
    } catch (_) {
      return UserProfile(
        id: userId,
        email: defaultEmail ?? currentUser?.email ?? '',
        fullName: 'User',
        role: UserRole.customer,
      );
    }
  }

  /// Get profile of currently signed in user
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return await getProfile(user.id, defaultEmail: user.email);
  }

  /// Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Convert AuthException into user-friendly messages
  String _parseAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid grant')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('network') || msg.contains('failed host lookup') || msg.contains('socket')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    return e.message;
  }
}
