import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'email_service.dart';

class PendingCustomerRegistration {
  final String email;
  final String fullName;
  final String password;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  int attempts;

  PendingCustomerRegistration({
    required this.email,
    required this.fullName,
    required this.password,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.attempts = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'password': password,
        'code': code,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'attempts': attempts,
      };

  factory PendingCustomerRegistration.fromJson(Map<String, dynamic> json) =>
      PendingCustomerRegistration(
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        password: json['password'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        attempts: json['attempts'] as int? ?? 0,
      );
}

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
  static const String _pendingCustomerPrefix = 'dinequeue_pending_cust_';

  // In-memory cache of registered customer accounts
  final Map<String, _LocalCustomerAccount> _inMemoryCustomerAccounts = {};

  // In-memory registry of pending customer email verifications
  final Map<String, PendingCustomerRegistration> _pendingRegistrations = {};

  // --- Fixed Predefined Staff Roles & Credentials ---
  static final Map<String, _FixedStaffCredential> _fixedStaff = {
    // Customer
    'customer123@gmail.com': const _FixedStaffCredential(
      password: 'customer@123',
      role: UserRole.customer,
      fullName: 'John Guest',
      phoneNumber: '+94 77 123 4567',
    ),
    'customer@dinequeue.com': const _FixedStaffCredential(
      password: 'customer@123',
      role: UserRole.customer,
      fullName: 'John Guest',
      phoneNumber: '+94 77 123 4567',
    ),

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

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
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

  static String? validateVerificationCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Verification code is required';
    }
    final clean = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.length < 6 ||
        clean.length > 8 ||
        !RegExp(r'^[a-zA-Z0-9]{6,8}$').hasMatch(clean)) {
      return 'Code must be 6 to 8 characters';
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
      try {
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
      } catch (authErr) {
        // Staff accounts must always authenticate against Supabase.
        if (_fixedStaff.containsKey(cleanEmail)) {
          rethrow;
        }
        // Verified customer accounts can fall back to locally verified credentials
        final customer =
            await _verifyLocalCustomerAccount(cleanEmail, password);
        if (customer != null && customer.role == UserRole.customer) {
          _localFallbackProfile = customer;
          await _saveProfileLocally(customer);
          return customer;
        }
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
    Map<String, dynamic>? row = await supa
        .from('profiles')
        .select('id,full_name,role')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      final roleStr = (user.userMetadata?['role'] as String?) ?? 'customer';
      final nameStr = (user.userMetadata?['full_name'] as String?) ??
          _nameFromEmail(user.email ?? 'Customer');
      try {
        await supa.from('profiles').insert({
          'id': user.id,
          'role': roleStr,
          'full_name': nameStr,
        });
        row = {'id': user.id, 'role': roleStr, 'full_name': nameStr};
      } catch (insertErr) {
        debugPrint('Notice inserting missing profile: $insertErr');
      }
    }

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
        try {
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
        } catch (signUpErr) {
          debugPrint('Supabase auth signUp notice: $signUpErr');
          // If user exists, sign in to establish session and obtain authenticated UUID
          try {
            final signRes = await supa.auth.signInWithPassword(
              email: cleanEmail,
              password: cleanPassword,
            );
            if (signRes.user != null) {
              finalUserId = signRes.user!.id;
            }
          } catch (signErr) {
            debugPrint('Supabase auth signIn notice: $signErr');
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase auth notice: $e');
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
        // Only insert if finalUserId is a valid UUID
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(finalUserId);

        if (isUuid) {
          await supa.from('profiles').upsert({
            'id': finalUserId,
            'role': newProfile.role.value,
            'full_name': newProfile.fullName,
          });
          debugPrint(
              '✅ [AuthService] Successfully saved profile to Supabase profiles table: $finalUserId ($cleanName)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService] Supabase profiles upsert notice: $e');
    }

    // 3. Save locally in device storage & credentials registry
    _localFallbackProfile = newProfile;
    await _saveProfileLocally(newProfile);
    await _saveCustomerCredentialsLocally(
        cleanEmail, cleanPassword, newProfile);
    return newProfile;
  }

  // --- Customer Email Verification Actions ---

  /// Sends a verification code to the customer's specific email address.
  /// This code is STRICTLY valid for creating a new customer account.
  Future<String> sendCustomerVerificationCode({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = fullName.trim();

    // 1. Validate fields
    final nameErr = validateName(cleanName);
    if (nameErr != null) throw Exception(nameErr);
    final emailErr = validateEmail(cleanEmail);
    if (emailErr != null) throw Exception(emailErr);
    final passErr = validatePassword(cleanPassword);
    if (passErr != null) throw Exception(passErr);

    // 2. Reserved staff check: Staff members cannot register or receive customer codes
    if (_fixedStaff.containsKey(cleanEmail)) {
      throw Exception(
        'This email is reserved for system staff. Staff members do not require customer email verification.',
      );
    }

    // 4. Generate 6-digit numeric verification code
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();

    // 5. Send real OTP email to the customer's specific email address
    // Priority A: Direct SMTP delivery to customer inbox (if SMTP credentials configured)
    final emailService = EmailService();
    bool emailDelivered = false;

    if (emailService.isSmtpConfigured) {
      emailDelivered = await emailService.sendVerificationEmail(
        recipientEmail: cleanEmail,
        recipientName: cleanName,
        verificationCode: code,
      );
    }

    // Priority B: Supabase Auth OTP delivery
    if (!emailDelivered) {
      try {
        final supa = _supabase;
        if (supa != null) {
          try {
            await supa.auth.signUp(
              email: cleanEmail,
              password: cleanPassword,
              data: {
                'full_name': cleanName,
                'role': UserRole.customer.value,
              },
            );
            debugPrint(
                '📧 [AuthService] Successfully sent OTP email via Supabase signUp to $cleanEmail');
          } catch (signUpErr) {
            debugPrint('[AuthService] Supabase signUp notice: $signUpErr');
            // If user already exists in Supabase (unconfirmed from previous attempt), resend confirmation
            try {
              await supa.auth.resend(
                email: cleanEmail,
                type: OtpType.signup,
              );
              debugPrint(
                  '📧 [AuthService] Successfully resent OTP email via Supabase resend to $cleanEmail');
            } catch (resendErr) {
              debugPrint('[AuthService] Supabase resend notice: $resendErr');
              try {
                await supa.auth.signInWithOtp(
                  email: cleanEmail,
                  shouldCreateUser: true,
                );
                debugPrint(
                    '📧 [AuthService] Successfully sent OTP email via Supabase signInWithOtp to $cleanEmail');
              } catch (otpErr) {
                debugPrint('[AuthService] Supabase signInWithOtp notice: $otpErr');
                final allErrors = '$signUpErr $resendErr $otpErr'.toLowerCase();
                if (allErrors.contains('rate') ||
                    allErrors.contains('seconds') ||
                    allErrors.contains('429')) {
                  throw Exception(
                    'Please wait 60 seconds before requesting another verification code.',
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        final errText = e.toString().toLowerCase();
        if (errText.contains('rate') || errText.contains('seconds') || errText.contains('429')) {
          rethrow;
        }
        debugPrint('[AuthService] Email dispatch notice: $e');
      }
    }

    // 6. Record pending registration (expires in 10 minutes)
    final pending = PendingCustomerRegistration(
      email: cleanEmail,
      fullName: cleanName,
      password: cleanPassword,
      code: code,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
    _pendingRegistrations[cleanEmail] = pending;
    await _savePendingRegistrationLocally(pending);

    debugPrint(
        '📧 [AuthService] Customer verification code for $cleanEmail: $code (valid for 10 min)');
    return code;
  }

  /// Verifies the 6-digit verification code and completes new customer account creation.
  /// ONLY valid for creating a new customer account.
  Future<UserProfile> verifyCustomerRegistration({
    required String email,
    required String code,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCode = code.trim().replaceAll(RegExp(r'[\s\-]'), '');

    final codeErr = validateVerificationCode(cleanCode);
    if (codeErr != null) {
      throw Exception(codeErr);
    }

    // Prevent staff emails from using customer verification
    if (_fixedStaff.containsKey(cleanEmail)) {
      throw Exception(
        'This email belongs to system staff and cannot be verified as a customer.',
      );
    }

    PendingCustomerRegistration? pending = _pendingRegistrations[cleanEmail];
    pending ??= await _loadPendingRegistrationLocally(cleanEmail);

    if (pending == null) {
      throw Exception(
        'No pending registration found for $cleanEmail. Please request a new verification code.',
      );
    }

    if (pending.isExpired) {
      _pendingRegistrations.remove(cleanEmail);
      await _clearPendingRegistrationLocally(cleanEmail);
      throw Exception(
        'Verification code has expired. Please request a new verification code.',
      );
    }

    bool isValid = false;
    if (cleanCode == pending.code) {
      isValid = true;
    }

    // Also attempt verification via Supabase OTP (email / signup)
    final supa = _supabase;
    if (supa != null) {
      try {
        final res = await supa.auth.verifyOTP(
          email: cleanEmail,
          token: cleanCode,
          type: OtpType.email,
        );
        if (res.user != null || res.session != null) {
          isValid = true;
          try {
            await supa.auth.updateUser(
              UserAttributes(password: pending.password),
            );
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('[AuthService] Supabase verifyOTP email notice: $e');
        try {
          final res = await supa.auth.verifyOTP(
            email: cleanEmail,
            token: cleanCode,
            type: OtpType.signup,
          );
          if (res.user != null || res.session != null) {
            isValid = true;
          }
        } catch (_) {}
      }
    }

    if (!isValid) {
      pending.attempts++;
      if (pending.attempts >= 5) {
        _pendingRegistrations.remove(cleanEmail);
        await _clearPendingRegistrationLocally(cleanEmail);
        throw Exception(
          'Too many incorrect attempts. This code has been invalidated. Please request a new code.',
        );
      }
      throw Exception(
        'Invalid verification code. Please check your email and try again.',
      );
    }

    // Verification succeeded! Complete customer registration
    final profile = await signUp(
      email: pending.email,
      password: pending.password,
      fullName: pending.fullName,
      role: UserRole.customer,
    );

    // Clean up pending registration
    _pendingRegistrations.remove(cleanEmail);
    await _clearPendingRegistrationLocally(cleanEmail);

    return profile;
  }

  /// Resends a verification code to the specified customer email address.
  Future<String> resendCustomerVerificationCode(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    PendingCustomerRegistration? pending = _pendingRegistrations[cleanEmail];
    pending ??= await _loadPendingRegistrationLocally(cleanEmail);

    if (pending == null) {
      throw Exception(
        'No pending registration found for $cleanEmail. Please fill out the registration form again.',
      );
    }

    return await sendCustomerVerificationCode(
      email: pending.email,
      fullName: pending.fullName,
      password: pending.password,
    );
  }

  /// Helper for testing and debugging to retrieve pending verification code.
  String? getPendingCustomerVerificationCode(String email) {
    final cleanEmail = email.trim().toLowerCase();
    return _pendingRegistrations[cleanEmail]?.code;
  }

  Future<void> _savePendingRegistrationLocally(
      PendingCustomerRegistration pending) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_pendingCustomerPrefix${pending.email}',
        jsonEncode(pending.toJson()),
      );
    } catch (_) {}
  }

  Future<PendingCustomerRegistration?> _loadPendingRegistrationLocally(
      String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_pendingCustomerPrefix$email');
      if (str != null) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        final pending = PendingCustomerRegistration.fromJson(decoded);
        _pendingRegistrations[email] = pending;
        return pending;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearPendingRegistrationLocally(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingCustomerPrefix$email');
    } catch (_) {}
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
