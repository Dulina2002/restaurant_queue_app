import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import '../../shared/widgets/role_header_widget.dart';
import '../../shared/widgets/role_bottom_nav_widget.dart';
import '../../features/receptionist/presentation/widgets/live_queue_widget.dart';
import 'receptionist_dashboard_screen.dart';
import 'reservation_summary_screen.dart';
import 'floor_overview_screen.dart';

class LiveQueueScreen extends StatefulWidget {
  final UserProfile profile;

  const LiveQueueScreen({super.key, required this.profile});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _navigate(int index) {
    if (index == 3) return; // already on Queue tab
    Widget destination;
    if (index == 0) {
      destination = ReceptionistDashboardScreen(profile: widget.profile);
    } else if (index == 1) {
      destination = ReservationSummaryScreen(profile: widget.profile);
    } else if (index == 2) {
      destination = FloorOverviewScreen(profile: widget.profile);
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
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: LiveQueueWidget(),
      ),
      bottomNavigationBar: RoleBottomNavWidget(
        selectedIndex: 3, // Queue tab
        onDestinationSelected: _navigate,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Reservation',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
