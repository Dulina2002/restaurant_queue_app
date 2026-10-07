import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/role_header_widget.dart';
import '../../shared/widgets/role_bottom_nav_widget.dart';
import '../../shared/widgets/app_toast.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../home_screen.dart';
import '../sign_in_screen.dart';
import 'receptionist_dashboard_screen.dart';
import 'floor_overview_screen.dart';
import 'reservation_summary_screen.dart';
import 'live_queue_screen.dart';
import '../../features/manager/presentation/screens/manager_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_dashboard_screen.dart';

class ReceptionistProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const ReceptionistProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ReceptionistProfileScreen> createState() => _ReceptionistProfileScreenState();
}

class _ReceptionistProfileScreenState extends State<ReceptionistProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _currentProfile;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
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
    if (index == 4) return; // already here
    Widget destination;
    if (index == 0) {
      destination = ReceptionistDashboardScreen(profile: widget.profile);
    } else if (index == 1) {
      destination = ReservationSummaryScreen(profile: widget.profile);
    } else if (index == 2) {
      destination = FloorOverviewScreen(profile: widget.profile);
    } else if (index == 3) {
      destination = LiveQueueScreen(profile: widget.profile);
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

  Future<void> _navigateToEditProfile() async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: _currentProfile ?? widget.profile),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentProfile = updated;
      });
    }
  }

  void _showRoleSwitchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch Workspace Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a role to preview the app dashboard for that user type:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            _buildRoleOption(
              title: 'Customer',
              subtitle: 'Browse restaurants, book tables, join virtual waitlist',
              roleColor: const Color(0xFFF27B50),
              icon: Icons.person_outline_rounded,
              isSelected: false,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDashboardScreen(
                      profile: _currentProfile ?? widget.profile,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildRoleOption(
              title: 'Receptionist / Host',
              subtitle: 'Manage live queue, call guests, oversee physical tables',
              roleColor: const Color(0xFFFF6B35),
              icon: Icons.table_restaurant_outlined,
              isSelected: true,
              onTap: () => Navigator.pop(sheetContext),
            ),
            const SizedBox(height: 10),

            _buildRoleOption(
              title: 'Manager',
              subtitle: 'AI optimizer, live menu 86-ing, floor analytics & turns',
              roleColor: const Color(0xFF10B981),
              icon: Icons.dashboard_outlined,
              isSelected: false,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManagerDashboardScreen(
                      profile: _currentProfile ?? widget.profile,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildRoleOption(
              title: 'Admin',
              subtitle: 'System users, multi-tenant restaurants & enterprise configs',
              roleColor: const Color(0xFF8B5CF6),
              icon: Icons.admin_panel_settings_outlined,
              isSelected: false,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboardScreen(
                      profile: _currentProfile ?? widget.profile,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required Color roleColor,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? roleColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? roleColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: roleColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? roleColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: roleColor, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = _currentProfile ?? widget.profile;
    final userName = (activeProfile.fullName.isNotEmpty == true)
        ? activeProfile.fullName
        : 'Host Front Desk';
    final userEmail = (activeProfile.email.isNotEmpty == true)
        ? activeProfile.email
        : 'receptionist@dinequeue.com';
    final userPhone = (activeProfile.phoneNumber?.isNotEmpty == true)
        ? activeProfile.phoneNumber!
        : '+94 11 234 5678';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RoleHeaderWidget(
        roleName: 'RECEPTIONIST',
        roleColor: const Color(0xFFFF6B35),
        isSigningOut: _isSigningOut,
        onSignOut: _showRoleSwitchSheet,
        profile: activeProfile,
        onProfileUpdated: (updated) => setState(() => _currentProfile = updated),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // --- 2. Avatar & Info Header ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UserAvatar(
                          profile: activeProfile,
                          name: userName,
                          size: 64,
                          onTap: _navigateToEditProfile,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToEditProfile,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userPhone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 28, color: AppColors.textPrimary),
                          onPressed: _navigateToEditProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- 3. Current Role Switcher Card ---
                    GestureDetector(
                      onTap: _showRoleSwitchSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.table_restaurant_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Current Role: Receptionist',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tap to switch between Customer, Receptionist, Manager & Admin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 4. Settings Menu Items List ---
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      onTap: _navigateToEditProfile,
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            content: const Text(
                              'For staff support or inquiries, please contact admin@dinequeue.com.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy & Terms',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Text('Privacy & Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            content: const Text(
                              'Staff are required to keep all customer dining data confidential.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.rocket_launch_outlined,
                      title: 'View App Starting Screen',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // --- 5. Log Out Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isSigningOut ? null : _signOut,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFEDD5), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                        child: _isSigningOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Color(0xFFEA580C), strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.logout_rounded, color: Color(0xFFEA580C), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Color(0xFFEA580C),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: RoleBottomNavWidget(
        selectedIndex: 4, // Profile tab
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.textPrimary, size: 20),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          onTap: onTap,
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
