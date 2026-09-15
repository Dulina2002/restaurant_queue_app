import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final UserProfile profile;

  const CustomerDashboardScreen({super.key, required this.profile});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
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
      backgroundColor: const Color(0xFF0B1910),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1910),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'CUSTOMER PORTAL',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                : const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: _isSigningOut ? null : _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF162C1E), Color(0xFF0F3A26)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFF27B50).withValues(alpha: 0.2),
                      child: Text(
                        widget.profile.fullName.isNotEmpty
                            ? widget.profile.fullName.substring(0, 1).toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Color(0xFFF27B50),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.profile.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.profile.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active Waitlist Ticket Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF162C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF27B50).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'YOUR ACTIVE QUEUE TICKET',
                          style: TextStyle(
                            color: Color(0xFFF1C77F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF27B50).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NO ACTIVE QUEUE',
                            style: TextStyle(
                              color: Color(0xFFF27B50),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You are not currently in any restaurant queue.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Browse restaurants below to join a live waitlist')),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan Table QR / Join Queue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF27B50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Popular Dining Spots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Dining Waitlists',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Colombo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _RestaurantQueueCard(
                name: 'Ministry of Crab',
                cuisine: 'Seafood • Dutch Hospital',
                waitingCount: 4,
                estimatedWait: '15-20 min',
                onJoin: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined Ministry of Crab waitlist!')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _RestaurantQueueCard(
                name: 'The Lagoon',
                cuisine: 'Fine Seafood • Cinnamon Grand',
                waitingCount: 2,
                estimatedWait: '5-10 min',
                onJoin: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined The Lagoon waitlist!')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _RestaurantQueueCard(
                name: 'Nihonbashi',
                cuisine: 'Japanese Cuisine • Steuart Place',
                waitingCount: 6,
                estimatedWait: '25-30 min',
                onJoin: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined Nihonbashi waitlist!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantQueueCard extends StatelessWidget {
  final String name;
  final String cuisine;
  final int waitingCount;
  final String estimatedWait;
  final VoidCallback onJoin;

  const _RestaurantQueueCard({
    required this.name,
    required this.cuisine,
    required this.waitingCount,
    required this.estimatedWait,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1910),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Center(
              child: Icon(Icons.restaurant, color: Color(0xFFF1C77F), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cuisine,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 13, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      '$waitingCount ahead',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 13, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      estimatedWait,
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onJoin,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF27B50),
              side: const BorderSide(color: Color(0xFFF27B50)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
