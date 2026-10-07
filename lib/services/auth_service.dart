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
  AuthService._internal();

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

  bool get isAuthenticated => currentUser != null || _localFallbackProfile != null;

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
        return UserProfile.fromJson(data, defaultEmail: clean.contains('@') ? clean : null);
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

  /// Sign In with Email and Password using Fixed Staff Credentials, Supabase Auth, or Local Registered Accounts
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Check fixed staff credentials (Receptionist, Manager, Admin)
    final staff = _fixedStaff[cleanEmail];
    if (staff != null) {
      if (staff.password == cleanPassword) {
        final profile = UserProfile(
          id: 'staff_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
          email: cleanEmail,
          fullName: staff.fullName,
          role: staff.role,
          phoneNumber: staff.phoneNumber,
          createdAt: DateTime.now(),
        );
        _localFallbackProfile = profile;
        await _saveProfileLocally(profile);
        return profile;
      } else {
        throw Exception('Invalid password for ${staff.role.displayName} account. Please try again.');
      }
    }

    // 2. Try Supabase Auth (for registered customers in Supabase)
    try {
      final supa = _supabase;
      if (supa != null) {
        final authResponse = await supa.auth.signInWithPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final supaUser = authResponse.user;
        if (supaUser != null) {
          final profile = await getProfile(
            supaUser.id,
            defaultEmail: supaUser.email ?? cleanEmail,
            userMetadata: supaUser.userMetadata,
          );
          _localFallbackProfile = profile;
          await _saveProfileLocally(profile);
          return profile;
        }
      }
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('invalid login credentials') ||
          err.contains('invalid_grant') ||
          err.contains('wrong password') ||
          err.contains('invalid credentials')) {
        // Check local registered customer accounts
        final localCust = await _verifyLocalCustomerAccount(cleanEmail, cleanPassword);
        if (localCust != null) {
          _localFallbackProfile = localCust;
          await _saveProfileLocally(localCust);
          return localCust;
        }
        throw Exception('Invalid email or password. Please try again.');
      }
    }

    // 3. Try Local Registered Customer Account
    final localCust = await _verifyLocalCustomerAccount(cleanEmail, cleanPassword);
    if (localCust != null) {
      _localFallbackProfile = localCust;
      await _saveProfileLocally(localCust);
      return localCust;
    }

    // 4. If credentials do not match any staff account or customer account, fail securely
    throw Exception('Invalid email or password. No account found for $cleanEmail. If you are a customer, please create an account.');
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
    final normalizedId = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    String finalUserId = normalizedId;

    // Check if trying to register using a fixed staff email
    if (_fixedStaff.containsKey(cleanEmail)) {
      throw Exception('This email is reserved for system staff. Please sign in instead.');
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
    await _saveCustomerCredentialsLocally(cleanEmail, cleanPassword, newProfile);
    return newProfile;
  }

  /// Fetch User Profile by User ID or Email from Supabase / Local Storage
  Future<UserProfile> getProfile(
    String userId, {
    String? defaultEmail,
    Map<String, dynamic>? userMetadata,
  }) async {
    final searchEmail = defaultEmail?.trim();

    // Check userMetadata first for role & full_name
    UserRole? metadataRole;
    final metaRoleStr = userMetadata?['role']?.toString() ?? currentUser?.userMetadata?['role']?.toString();
    if (metaRoleStr != null && metaRoleStr.isNotEmpty) {
      metadataRole = UserRole.fromString(metaRoleStr);
    }
    final metadataFullName = (userMetadata?['full_name'] as String?) ??
        (currentUser?.userMetadata?['full_name'] as String?);

    // Return in-memory profile if valid and matching
    if (_localFallbackProfile != null &&
        (_localFallbackProfile!.id == userId ||
            (searchEmail != null &&
                _localFallbackProfile!.email.toLowerCase() == searchEmail.toLowerCase()))) {
      if (metadataRole != null && _localFallbackProfile!.role != metadataRole) {
        _localFallbackProfile = _localFallbackProfile!.copyWith(role: metadataRole);
        await _saveProfileLocally(_localFallbackProfile!);
      }
      return _localFallbackProfile!;
    }

    // 1. Try Supabase profiles table
    try {
      final supa = _supabase;
      if (supa != null) {
        // Query by ID
        var row = await supa.from('profiles').select().eq('id', userId).maybeSingle();

        // If not found by ID, query by email
        if (row == null && searchEmail != null && searchEmail.isNotEmpty) {
          try {
            row = await supa.from('profiles').select().ilike('email', searchEmail).maybeSingle();
          } catch (_) {}
        }

        // If still not found, try 'users' table
        if (row == null) {
          try {
            row = await supa.from('users').select().eq('id', userId).maybeSingle();
          } catch (_) {}
        }
        if (row == null && searchEmail != null && searchEmail.isNotEmpty) {
          try {
            row = await supa.from('users').select().ilike('email', searchEmail).maybeSingle();
          } catch (_) {}
        }

        if (row != null) {
          var role = UserRole.fromString(row['role']?.toString());
          if (metadataRole != null && metadataRole != UserRole.customer) {
            role = metadataRole;
          } else if (role == UserRole.customer && searchEmail != null) {
            final inferred = _inferRoleFromEmail(searchEmail);
            if (inferred != UserRole.customer) role = inferred;
          }
          final p = UserProfile(
            id: row['id']?.toString() ?? userId,
            email: (row['email'] as String?) ?? searchEmail ?? currentUser?.email ?? '',
            fullName: (row['full_name'] as String?) ?? metadataFullName ?? _nameFromEmail(searchEmail ?? 'User'),
            role: role,
            avatarUrl: row['avatar_url'] as String?,
            phoneNumber: row['phone_number'] as String?,
            createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
          );
          _localFallbackProfile = p;
          await _saveProfileLocally(p);
          return p;
        }
      }
    } catch (e) {
      debugPrint('Supabase getProfile read notice: $e');
    }

    // 2. Try Local Persistent Cache
    if (searchEmail != null || userId.isNotEmpty) {
      final localProf = await _loadProfileLocally(searchEmail ?? userId);
      if (localProf != null) {
        var finalRole = localProf.role;
        if (metadataRole != null && metadataRole != UserRole.customer) {
          finalRole = metadataRole;
        } else if (finalRole == UserRole.customer && searchEmail != null) {
          final inferred = _inferRoleFromEmail(searchEmail);
          if (inferred != UserRole.customer) finalRole = inferred;
        }
        final updated = localProf.copyWith(
          role: finalRole,
          fullName: metadataFullName ?? localProf.fullName,
        );
        _localFallbackProfile = updated;
        return updated;
      }
    }

    // 3. Fallback: Role inferred from email / metadata
    final fallbackRole = metadataRole ??
        (searchEmail != null ? _inferRoleFromEmail(searchEmail) : UserRole.customer);
    final fallbackProfile = UserProfile(
      id: userId,
      email: searchEmail ?? currentUser?.email ?? 'user@example.com',
      fullName: metadataFullName ?? (searchEmail != null ? _nameFromEmail(searchEmail) : 'Guest User'),
      role: fallbackRole,
      createdAt: DateTime.now(),
    );

    _localFallbackProfile = fallbackProfile;
    await _saveProfileLocally(fallbackProfile);
    return fallbackProfile;
  }

  /// Get profile of currently signed in user
  Future<UserProfile?> getCurrentUserProfile() async {
    if (_localFallbackProfile != null) {
      return _localFallbackProfile;
    }

    final supaUser = _supabase?.auth.currentUser;
    if (supaUser != null) {
      final prof = await getProfile(
        supaUser.id,
        defaultEmail: supaUser.email,
        userMetadata: supaUser.userMetadata,
      );
      _localFallbackProfile = prof;
      return prof;
    }

    // Check device local session
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeEmail = prefs.getString(_activeUserEmailKey);
      final activeId = prefs.getString(_activeUserKey);
      if (activeEmail != null || activeId != null) {
        final saved = await _loadProfileLocally(activeEmail ?? activeId!);
        if (saved != null) {
          _localFallbackProfile = saved;
          return saved;
        }
      }
    } catch (_) {}

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
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
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

  UserRole _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase().trim();
    if (lower.contains('admin') ||
        lower.contains('owner') ||
        lower.contains('root') ||
        lower.contains('administrator')) {
      return UserRole.admin;
    }
    if (lower.contains('manager') ||
        lower.contains('mgr') ||
        lower.contains('mgmt') ||
        lower.contains('manage') ||
        lower.contains('supervisor') ||
        lower.contains('lead')) {
      return UserRole.manager;
    }
    if (lower.contains('reception') ||
        lower.contains('reciption') ||
        lower.contains('recept') ||
        lower.contains('recipt') ||
        lower.contains('frontdesk') ||
        lower.contains('front_desk') ||
        lower.contains('front-desk') ||
        lower.contains('front desk') ||
        lower.contains('desk') ||
        lower.contains('host') ||
        lower.contains('hostess') ||
        lower.contains('staff') ||
        lower.contains('greeter') ||
        lower.contains('cashier') ||
        lower.contains('waiter') ||
        lower.contains('waitress') ||
        lower.contains('steward') ||
        lower.contains('concierge') ||
        lower.contains('clerk')) {
      return UserRole.receptionist;
    }
    return UserRole.customer;
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
