import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class _LocalCustomerAccount {
  final String email;
  final String password;
  final UserProfile profile;

  const _LocalCustomerAccount({
    required this.email,
    required this.password,
    required this.profile,
  });
}

class _FixedStaffCredential {
  final String password;
  final UserRole role;
  final String fullName;
  final String phoneNumber;

  const _FixedStaffCredential({
    required this.password,
    required this.role,
    required this.fullName,
    required this.phoneNumber,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal()
      : _testClient = null,
        _useTestClient = false;
  @visibleForTesting
  AuthService.forTesting(SupabaseClient? client)
      : _testClient = client,
        _useTestClient = true;
  final SupabaseClient? _testClient;
  final bool _useTestClient;

  static const String _activeUserKey = 'dinequeue_active_user_id';
  static const String _activeUserEmailKey = 'dinequeue_active_user_email';
  static const String _userProfilesPrefix = 'dinequeue_user_profile_';
  static const String _emailToIdPrefix = 'dinequeue_email_to_id_';
  static const String _registeredUserPrefix = 'dinequeue_reg_user_';

  // In-memory cache of registered customer accounts
  final Map<String, _LocalCustomerAccount> _inMemoryCustomerAccounts = {};

  // --- Fixed Predefined Staff Roles & Credentials ---
  static final Map<String, _FixedStaffCredential> _fixedStaff = {
    // Receptionist
    'reciptionist123@gmail.com': const _FixedStaffCredential(
      password: 'reciption@123',
      role: UserRole.receptionist,
      fullName: 'Front Desk Receptionist',
      phoneNumber: '+94 11 234 5678',
    ),
    'receptionist123@gmail.com': const _FixedStaffCredential(
      password: 'reception@123',
      role: UserRole.receptionist,
      fullName: 'Front Desk Receptionist',
      phoneNumber: '+94 11 234 5678',
    ),
    'receptionist@dinequeue.com': const _FixedStaffCredential(
      password: 'reception@123',
      role: UserRole.receptionist,
      fullName: 'Host Front Desk',
      phoneNumber: '+94 11 234 5678',
    ),
    'reception@dinequeue.com': const _FixedStaffCredential(
      password: 'reception@123',
      role: UserRole.receptionist,
      fullName: 'Host Front Desk',
      phoneNumber: '+94 11 234 5678',
    ),

    // Manager
    'manager123@gmail.com': const _FixedStaffCredential(
      password: 'manager@123',
      role: UserRole.manager,
      fullName: 'Restaurant Manager',
      phoneNumber: '+94 77 987 6543',
    ),
    'manager@oceanbistro.com': const _FixedStaffCredential(
      password: 'manager@123',
      role: UserRole.manager,
      fullName: 'Restaurant Manager',
      phoneNumber: '+94 77 987 6543',
    ),
    'manager@dinequeue.com': const _FixedStaffCredential(
      password: 'manager@123',
      role: UserRole.manager,
      fullName: 'Restaurant Manager',
      phoneNumber: '+94 77 987 6543',
    ),

    // Admin
    'admin123@gmail.com': const _FixedStaffCredential(
      password: 'admin@123',
      role: UserRole.admin,
      fullName: 'System Administrator',
      phoneNumber: '+94 71 111 2233',
    ),
    'admin@dinequeue.com': const _FixedStaffCredential(
      password: 'admin@123',
      role: UserRole.admin,
      fullName: 'System Administrator',
      phoneNumber: '+94 71 111 2233',
    ),
  };

  SupabaseClient? get _supabase {
    if (_useTestClient) return _testClient;
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

  bool get isAuthenticated =>
      currentUser != null || _localFallbackProfile != null;

  Stream<dynamic> get onAuthStateChange {
    try {
      final supa = _supabase;
      if (supa == null) return Stream.value(null);
      return supa.auth.onAuthStateChange;
    } catch (_) {
      return Stream.value(null);
    }
  }

  // Current session cached user for local fallback
  UserProfile? _localFallbackProfile;

  // --- Local Persistence Helpers ---

  Future<void> _saveProfileLocally(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profile.toJson());
      await prefs.setString('$_userProfilesPrefix${profile.id}', jsonString);
      if (profile.email.isNotEmpty) {
        final emailKey = profile.email.toLowerCase().trim();
        await prefs.setString('$_userProfilesPrefix$emailKey', jsonString);
        await prefs.setString('$_emailToIdPrefix$emailKey', profile.id);
      }
      await prefs.setString(_activeUserKey, profile.id);
      await prefs.setString(_activeUserEmailKey, profile.email);
    } catch (e) {
      debugPrint('Error saving profile locally: $e');
    }
  }

  Future<UserProfile?> _loadProfileLocally(String identifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clean = identifier.toLowerCase().trim();

      // 1. Try direct lookup by email or id
      String? jsonString = prefs.getString('$_userProfilesPrefix$clean');

      // 2. Try email-to-id mapping
      if (jsonString == null) {
        final mappedId = prefs.getString('$_emailToIdPrefix$clean');
        if (mappedId != null) {
          jsonString = prefs.getString('$_userProfilesPrefix$mappedId');
        }
      }

      // 3. Try raw identifier
      jsonString ??= prefs.getString('$_userProfilesPrefix$identifier');

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        return UserProfile.fromJson(data,
            defaultEmail: clean.contains('@') ? clean : null);
      }
    } catch (e) {
      debugPrint('Error loading profile locally: $e');
    }
    return null;
  }

  Future<void> _saveCustomerCredentialsLocally(
    String email,
    String password,
    UserProfile profile,
  ) async {
    final cleanEmail = email.toLowerCase().trim();
    _inMemoryCustomerAccounts[cleanEmail] = _LocalCustomerAccount(
      email: cleanEmail,
      password: password,
      profile: profile,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_registeredUserPrefix$cleanEmail';
      final data = {
        'email': cleanEmail,
        'password': password,
        'profile': profile.toJson(),
      };
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Error storing customer credentials locally: $e');
    }
  }

  Future<UserProfile?> _verifyLocalCustomerAccount(
    String email,
    String password,
  ) async {
    final cleanEmail = email.toLowerCase().trim();
    final mem = _inMemoryCustomerAccounts[cleanEmail];
    if (mem != null) {
      if (mem.password == password) {
        return mem.profile;
      } else {
        throw Exception('Incorrect password. Please verify and try again.');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_registeredUserPrefix$cleanEmail';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr);
        final storedPass = data['password'] as String?;
        if (storedPass == password) {
          final profMap = data['profile'] as Map<String, dynamic>;
          final prof = UserProfile.fromJson(profMap);
          _inMemoryCustomerAccounts[cleanEmail] = _LocalCustomerAccount(
            email: cleanEmail,
            password: password,
            profile: prof,
          );
          return prof;
        } else {
          throw Exception('Incorrect password. Please verify and try again.');
        }
      }
    } catch (e) {
      if (e.toString().contains('Incorrect password')) rethrow;
      debugPrint('Error verifying local customer account: $e');
    }
    return null;
  }

  Future<void> _clearActiveLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeUserKey);
      await prefs.remove(_activeUserEmailKey);
    } catch (e) {
      debugPrint('Error clearing local session: $e');
    }
  }

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

  /// Normal sign-in uses Supabase Auth for every role. Local customer preview
  /// is available only when Supabase is unconfigured, never after a login error.
  Future<UserProfile> signIn(
      {required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    _localFallbackProfile = null;
    await _clearActiveLocalSession();
    final supa = _supabase;
    if (supa != null) {
      final response = await supa.auth
          .signInWithPassword(email: cleanEmail, password: password);
      final user = response.user;
      if (user == null ||
          response.session == null ||
          supa.auth.currentUser?.id != user.id) {
        throw const AuthException(
            'Sign-in did not establish an authenticated session.');
      }
      try {
        return await _authenticatedProfile(supa, user);
      } catch (_) {
        // A session without an authoritative profile must not enter a dashboard.
        await supa.auth.signOut(scope: SignOutScope.local);
        rethrow;
      }
    }
    final customer = await _verifyLocalCustomerAccount(cleanEmail, password);
    if (customer == null || customer.role != UserRole.customer) {
      throw const AuthException(
          'Supabase sign-in is required for staff accounts. No valid local customer account was found.');
    }
    _localFallbackProfile = customer;
    await _saveProfileLocally(customer);
    return customer;
  }

  Future<UserProfile> _authenticatedProfile(
      SupabaseClient supa, User user) async {
    final row = await supa
        .from('profiles')
        .select('id,full_name,role')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null ||
        row['id'] != user.id ||
        !['customer', 'receptionist', 'manager', 'admin']
            .contains(row['role'])) {
      throw const AuthException(
          'Your authenticated account has no valid profile. Contact an administrator.');
    }
    final profile = UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: row['full_name'] as String? ??
          (user.userMetadata?['full_name'] as String?) ??
          _nameFromEmail(user.email ?? 'User'),
      role: UserRole.fromString(row['role'] as String),
    );
    // Persist display data, but it must never authenticate privileged roles offline.
    await _saveProfileLocally(profile);
    return profile;
  }

  /// Sign Up for Customers with Email, Password, and Full Name
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.customer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = fullName.trim();
    final normalizedId =
        'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    String finalUserId = normalizedId;

    // Check if trying to register using a fixed staff email
    if (_fixedStaff.containsKey(cleanEmail)) {
      throw Exception(
          'This email is reserved for system staff. Please sign in instead.');
    }

    // 1. Try Supabase Auth signup with metadata
    try {
      final supa = _supabase;
      if (supa != null) {
        final res = await supa.auth.signUp(
          email: cleanEmail,
          password: cleanPassword,
          data: {
            'full_name': cleanName,
            'role': UserRole.customer.value,
          },
        );
        if (res.user != null) {
          finalUserId = res.user!.id;
        }
      }
    } catch (e) {
      debugPrint('Supabase auth signUp notice: $e');
    }

    final newProfile = UserProfile(
      id: finalUserId,
      email: cleanEmail,
      fullName: cleanName,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );

    // 2. Save to Supabase profiles table
    try {
      final supa = _supabase;
      if (supa != null) {
        try {
          await supa.from('profiles').upsert({
            'id': newProfile.id,
            'role': newProfile.role.value,
            'full_name': newProfile.fullName,
            'email': newProfile.email,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          try {
            await supa.from('profiles').upsert({
              'id': newProfile.id,
              'role': newProfile.role.value,
              'full_name': newProfile.fullName,
            });
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 3. Save locally in device storage & credentials registry
    _localFallbackProfile = newProfile;
    await _saveProfileLocally(newProfile);
    await _saveCustomerCredentialsLocally(
        cleanEmail, cleanPassword, newProfile);
    return newProfile;
  }

  /// Real sessions always use the UUID-linked database profile, not local roles.
  Future<UserProfile> getProfile(
    String userId, {
    String? defaultEmail,
    Map<String, dynamic>? userMetadata,
  }) async {
    final supa = _supabase;
    final user = supa?.auth.currentUser;
    if (supa != null && user != null && supa.auth.currentSession != null) {
      if (userId != user.id) {
        throw const AuthException(
            'Profile does not match the authenticated user.');
      }
      return _authenticatedProfile(supa, user);
    }
    final local = await _loadProfileLocally(defaultEmail ?? userId);
    if (local != null && local.role == UserRole.customer) return local;
    // Explicit local preview data cannot derive privileges from email/metadata.
    return UserProfile(
        id: userId,
        email: defaultEmail ?? '',
        fullName: userMetadata?['full_name'] as String? ?? 'Guest User',
        role: UserRole.customer);
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final supa = _supabase;
    final user = supa?.auth.currentUser;
    if (supa != null && user != null && supa.auth.currentSession != null) {
      return _authenticatedProfile(supa, user);
    }
    if (_localFallbackProfile?.role == UserRole.customer) {
      return _localFallbackProfile;
    }
    _localFallbackProfile = null;
    final prefs = await SharedPreferences.getInstance();
    final identifier =
        prefs.getString(_activeUserEmailKey) ?? prefs.getString(_activeUserKey);
    if (identifier != null) {
      final saved = await _loadProfileLocally(identifier);
      if (saved?.role == UserRole.customer) {
        _localFallbackProfile = saved;
        return saved;
      }
      await _clearActiveLocalSession();
    }
    return null;
  }

  /// Upload avatar image and return URL or Data URI
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    // 1. Try Supabase Storage (bucket 'avatars')
    try {
      final supa = _supabase;
      if (supa != null) {
        final bytes = await imageFile.readAsBytes();
        final path = 'avatars/$userId.jpg';
        await supa.storage.from('avatars').uploadBinary(
              path,
              bytes,
              fileOptions:
                  const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );
        final publicUrl = supa.storage.from('avatars').getPublicUrl(path);
        if (publicUrl.isNotEmpty) return publicUrl;
      }
    } catch (_) {}

    // 2. Resilient Base64 Data URI
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Update User Profile in Supabase and Local Storage
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final currentProf = await getProfile(userId, defaultEmail: email);
    final updatedProf = currentProf.copyWith(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
    );

    // Save to Supabase profiles
    try {
      final supa = _supabase;
      if (supa != null) {
        try {
          await supa.from('profiles').upsert({
            'id': userId,
            'role': updatedProf.role.value,
            'full_name': updatedProf.fullName,
            'email': updatedProf.email,
            'phone_number': updatedProf.phoneNumber,
            'avatar_url': updatedProf.avatarUrl,
          });
        } catch (_) {
          try {
            await supa.from('profiles').upsert({
              'id': userId,
              'role': updatedProf.role.value,
              'full_name': updatedProf.fullName,
              'phone_number': updatedProf.phoneNumber,
              'avatar_url': updatedProf.avatarUrl,
            });
          } catch (_) {}
        }
      }
    } catch (_) {}

    _localFallbackProfile = updatedProf;
    await _saveProfileLocally(updatedProf);
    return updatedProf;
  }

  /// Sign Out of Supabase Auth & Clear Local Active Session
  Future<void> signOut() async {
    _localFallbackProfile = null;
    await _clearActiveLocalSession();
    try {
      await _supabase?.auth.signOut();
    } catch (_) {}
  }

  String _nameFromEmail(String email) {
    final parts = email.split('@');
    if (parts.isNotEmpty) {
      final name = parts[0].replaceAll('.', ' ').replaceAll('_', ' ');
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return 'User';
  }
}
