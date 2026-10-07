import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'manager/manager_dashboard_screen.dart';
import 'receptionist/receptionist_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.onAuthStateChange,
      builder: (context, snapshot) {
        final currentUser = snapshot.data ?? authService.currentUser;

        if (currentUser == null) {
          return const HomeScreen();
        }

        return FutureBuilder<UserProfile?>(
          future: authService.getCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const HomeScreen();
            }

            final userProfile = profileSnapshot.data ??
                UserProfile(
                  id: currentUser.id,
                  email: currentUser.email ?? '',
                  fullName: currentUser.userMetadata?['full_name'] as String? ?? 'Diner Guest',
                  role: UserRole.customer,
                );

            return AuthGate.getScreenForRole(userProfile);
          },
        );
      },
    );
  }
}
