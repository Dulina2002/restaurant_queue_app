import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'manager/manager_dashboard_screen.dart';
import 'receptionist/receptionist_dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  static Widget getScreenForRole(UserProfile profile) {
    switch (profile.role) {
      case UserRole.customer:
        return CustomerDashboardScreen(profile: profile);
      case UserRole.receptionist:
        return ReceptionistDashboardScreen(profile: profile);
      case UserRole.manager:
        return ManagerDashboardScreen(profile: profile);
      case UserRole.admin:
        return AdminDashboardScreen(profile: profile);
    }
  }

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  Future<UserProfile?>? _profileFuture;
  StreamSubscription<dynamic>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _authSub = _authService.onAuthStateChange.listen((_) {
      if (mounted) {
        setState(() {
          _profileFuture = _authService.getCurrentUserProfile();
        });
      }
    });
  }

  void _loadProfile() {
    _profileFuture = _authService.getCurrentUserProfile();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting && !profileSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B1910),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF27B50),
              ),
            ),
          );
        }

        final userProfile = profileSnapshot.data;
        if (userProfile == null) {
          return const HomeScreen();
        }

        return AuthGate.getScreenForRole(userProfile);
      },
    );
  }
}
