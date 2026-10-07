import 'package:flutter/material.dart';

import 'how_it_works_screen.dart';

import 'sign_in_screen.dart';

import 'admin/admin_dashboard_screen.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'customer/customer_dashboard_screen.dart';
import 'receptionist/receptionist_dashboard_screen.dart';
import 'manager/manager_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1910),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: ColoredBox(
            color: const Color(0xFF0B1910),
            child: SafeArea(
              child: SizedBox.expand(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width >= 600 ? 32 : 16,
                    24,
                    MediaQuery.sizeOf(context).width >= 600 ? 32 : 16,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'COLOMBO • SMART DINING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignInScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Row(
                              children: [
                                Text('Skip to App',
                                    style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 72),

                      // Logo & Title

                      Center(
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF112518),
                                    border: Border.all(
                                      color: const Color(0xFFF27B50),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                Positioned(
                                  bottom: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF27B50),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check,
                                            color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'LIVE SYNC',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              'DineQueue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Reserve tables with certainty.\nWait in virtual queues with freedom.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Features

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final scale =
                              MediaQuery.textScalerOf(context).scale(11) / 11;
                          final columns = constraints.maxWidth >= 320 * scale
                              ? 3
                              : constraints.maxWidth >= 210 * scale
                                  ? 2
                                  : 1;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 8) /
                                  columns;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _FeatureCard(
                                  icon: Icons.calendar_today,
                                  title: 'Instant Booking',
                                  subtitle: 'Guaranteed Tables'),
                              _FeatureCard(
                                  icon: Icons.people_outline,
                                  title: 'Virtual Queue',
                                  subtitle: 'Zero Physical Wait'),
                              _FeatureCard(
                                  icon: Icons.wifi,
                                  title: 'Live Status',
                                  subtitle: 'Instant Alerts'),
                            ]
                                .map((card) =>
                                    SizedBox(width: width, child: card))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Banner

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162C1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.show_chart,
                                  color: Colors.greenAccent, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '24 Premier Dining Partners Online',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '84 tables seated • Avg wait time 12 mins',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Buttons

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF27B50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                                child: Text(
                              'Explore & Reserve Tables',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            )),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showHowItWorksDialog(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('How It Works'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 12),
                      Text('OR DEMO QUICK-LAUNCH AS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      LayoutBuilder(builder: (context, constraints) {
                        final scale =
                            MediaQuery.textScalerOf(context).scale(11) / 11;
                        final columns = constraints.maxWidth >= 350 * scale
                            ? 4
                            : constraints.maxWidth >= 180 * scale
                                ? 2
                                : 1;
                        final width =
                            ((constraints.maxWidth - (columns - 1) * 8) /
                                    columns)
                                .clamp(0.0, 160.0 * scale)
                                .toDouble();
                        return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _demoButton(context, 'Customer', width,
                                  const CustomerDashboardScreen()),
                              _demoButton(
                                  context,
                                  'Receptionist',
                                  width,
                                  const ReceptionistDashboardScreen(
                                      profile: UserProfile(
                                          id: 'demo_receptionist',
                                          email: '',
                                          fullName: 'Demo Receptionist',
                                          role: UserRole.receptionist))),
                              _demoButton(
                                  context,
                                  'Manager',
                                  width,
                                  const ManagerDashboardScreen(
                                      profile: UserProfile(
                                          id: 'demo_manager',
                                          email: '',
                                          fullName: 'Demo Manager',
                                          role: UserRole.manager))),
                              _demoButton(
                                  context,
                                  'Admin',
                                  width,
                                  const AdminDashboardScreen(
                                      profile: UserProfile(
                                          id: 'demo_admin',
                                          email: '',
                                          fullName: 'Demo Admin',
                                          role: UserRole.admin))),
                            ]);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoButton(
      BuildContext context, String label, double width, Widget screen) {
    return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen)),
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ));
  }

  void _showHowItWorksDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HowItWorksScreen()),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF1C77F), size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
