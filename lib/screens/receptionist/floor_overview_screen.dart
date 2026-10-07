import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import '../../shared/widgets/role_header_widget.dart';
import '../../shared/widgets/role_bottom_nav_widget.dart';
import '../../shared/widgets/app_toast.dart';
import '../../features/receptionist/presentation/widgets/floor_overview_widget.dart';
import 'receptionist_dashboard_screen.dart';
import 'reservation_summary_screen.dart';
import 'live_queue_screen.dart';
import 'receptionist_profile_screen.dart';

class FloorOverviewScreen extends StatefulWidget {
  final UserProfile profile;

  const FloorOverviewScreen({super.key, required this.profile});

  @override
  State<FloorOverviewScreen> createState() => _FloorOverviewScreenState();
}

class _FloorOverviewScreenState extends State<FloorOverviewScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Failed to sign out: $e',
        title: 'Sign Out Error',
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _navigate(int index) {
    if (index == 2) return; // already here
    Widget destination;
    if (index == 0) {
      destination = ReceptionistDashboardScreen(profile: widget.profile);
    } else if (index == 1) {
      destination = ReservationSummaryScreen(profile: widget.profile);
    } else if (index == 3) {
      destination = LiveQueueScreen(profile: widget.profile);
    } else if (index == 4) {
      destination = ReceptionistProfileScreen(profile: widget.profile);
    } else {
      return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RoleHeaderWidget(
        roleName: 'RECEPTIONIST',
        roleColor: const Color(0xFFFF6B35),
        isSigningOut: _isSigningOut,
        onSignOut: _signOut,
        profile: widget.profile,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: FloorOverviewWidget(),
      ),
      bottomNavigationBar: RoleBottomNavWidget(
        selectedIndex: 2, // Tables tab
        onDestinationSelected: _navigate,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Reservations'),
          NavigationDestination(icon: Icon(Icons.table_restaurant_outlined), label: 'Tables'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
