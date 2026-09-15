import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'home_screen.dart';
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
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    try {
      if (_authService.isAuthenticated) {
        final profile = await _authService.getCurrentUserProfile();
        if (mounted) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profile = null;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profile = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1910),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFF27B50),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Smart Dining...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: _authService.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? _authService.currentSession;
        if (session == null) {
          return const HomeScreen();
        }

        if (_profile != null && _profile!.id == session.user.id) {
          return AuthGate.getScreenForRole(_profile!);
        }

        return FutureBuilder<UserProfile?>(
          future: _authService.getCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0B1910),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF27B50)),
                ),
              );
            }

            final userProfile = profileSnapshot.data ??
                UserProfile(
                  id: session.user.id,
                  email: session.user.email ?? '',
                  fullName: 'Guest User',
                  role: UserRole.customer,
                );

            return AuthGate.getScreenForRole(userProfile);
          },
        );
      },
    );
  }
}
