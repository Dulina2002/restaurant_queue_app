import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'receptionist_dashboard_screen.dart';
import '../../shared/widgets/role_header_widget.dart';
import '../../shared/widgets/role_bottom_nav_widget.dart';

class ReservationSummaryScreen extends StatefulWidget {
  final UserProfile profile;

  const ReservationSummaryScreen({super.key, required this.profile});

  @override
  State<ReservationSummaryScreen> createState() => _ReservationSummaryScreenState();
}

class _ReservationSummaryScreenState extends State<ReservationSummaryScreen> {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reservations Management',
              style: TextStyle(color: Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            
            TextField(
              decoration: InputDecoration(
                hintText: 'Search guest name or reservation ID',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF143621)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', true),
                  const SizedBox(width: 12),
                  _buildFilterChip('Confirmed', false),
                  const SizedBox(width: 12),
                  _buildFilterChip('Completed', false),
                  const SizedBox(width: 12),
                  _buildFilterChip('Cancelled', false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildReservationListCard(
              name: 'Ayesha Perera',
              time: '7:30 PM', guests: '4 Guests', table: 'Table 04',
              requirement: 'Req: Window seat facing the ocean, celebrating an anniversary.',
              status: 'Completed',
            ),
            const SizedBox(height: 16),
            _buildReservationListCard(
              name: 'Ayesha Perera',
              time: '8:00 PM', guests: '2 Guests', table: 'Table 02',
              requirement: 'Req: Quiet corner table.',
              status: 'Completed',
            ),
            const SizedBox(height: 16),
            _buildReservationListCard(
              name: 'Ayesha Perera',
              time: '7:00 PM', guests: '6 Guests', table: 'Table 06',
              requirement: 'Req: Tatami seating if possible.',
              status: 'Cancelled',
            ),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNavWidget(
        selectedIndex: 1, // 1 is Reservation
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => ReceptionistDashboardScreen(profile: widget.profile),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Reservation'),
          NavigationDestination(icon: Icon(Icons.table_restaurant_outlined), label: 'Tables'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF143621) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4B5563),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildReservationListCard({
    required String name,
    required String time,
    required String guests,
    required String table,
    required String requirement,
    required String status,
  }) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (status == 'Completed') {
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFE6F4EA);
      statusIcon = Icons.check;
    } else if (status == 'Cancelled') {
      statusColor = const Color(0xFFD32F2F);
      statusBgColor = const Color(0xFFFCE8E8);
      statusIcon = Icons.close;
    } else {
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFFECFDF5);
      statusIcon = Icons.check;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$time • $guests • $table', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          Text(requirement, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4)),
        ],
      ),
    );
  }
}
