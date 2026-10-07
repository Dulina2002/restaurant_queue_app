import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../models/user_role.dart';
import '../../../services/auth_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../home_screen.dart';
import '../../receptionist/receptionist_dashboard_screen.dart';
import '../../../features/manager/presentation/screens/manager_dashboard_screen.dart';
import '../../admin/admin_dashboard_screen.dart';
import 'customer_notifications_sheet.dart';

class CustomerProfileView extends StatefulWidget {
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onProfileUpdated;

  const CustomerProfileView({
    super.key,
    this.profile,
    this.onProfileUpdated,
  });

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> {
  final AuthService _authService = AuthService();
  UserProfile? _currentProfile;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant CustomerProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _currentProfile = widget.profile;
    }
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
      widget.onProfileUpdated?.call(updated);
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
              isSelected: true,
              onTap: () => Navigator.pop(sheetContext),
            ),
            const SizedBox(height: 10),

            _buildRoleOption(
              title: 'Receptionist / Host',
              subtitle: 'Manage live queue, call guests, oversee physical tables',
              roleColor: const Color(0xFF3B82F6),
              icon: Icons.table_restaurant_outlined,
              isSelected: false,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceptionistDashboardScreen(
                      profile: _currentProfile ??
                          widget.profile ??
                          UserProfile(
                            id: 'rec_1',
                            fullName: 'Host Front Desk',
                            email: 'receptionist@dinequeue.com',
                            role: UserRole.receptionist,
                            createdAt: DateTime.now(),
                          ),
                    ),
                  ),
                );
              },
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
                      profile: _currentProfile ??
                          widget.profile ??
                          UserProfile(
                            id: 'mgr_1',
                            fullName: 'Restaurant Manager',
                            email: 'manager@oceanbistro.com',
                            role: UserRole.manager,
                            createdAt: DateTime.now(),
                          ),
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
                      profile: _currentProfile ??
                          widget.profile ??
                          UserProfile(
                            id: 'adm_1',
                            fullName: 'System Admin',
                            email: 'admin@dinequeue.com',
                            role: UserRole.admin,
                            createdAt: DateTime.now(),
                          ),
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
          color: isSelected ? roleColor.withValues(alpha: 0.08) : Colors.white,
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
                color: roleColor.withValues(alpha: 0.15),
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

  void _showReviewsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Dining Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ocean Bistro — 5.0 ★',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '"Exceptional seafood risotto and swift seating with DineQueue!"',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'The Mango Tree — 4.5 ★',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '"Delicious butter chicken and courteous service."',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to log out of your DineQueue account?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isSigningOut = true);
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = _currentProfile ?? widget.profile;
    final userName = (activeProfile?.fullName.isNotEmpty == true)
        ? activeProfile!.fullName
        : 'Dulina';
    final userEmail = (activeProfile?.email.isNotEmpty == true)
        ? activeProfile!.email
        : 'dulina@gmail.com';
    final userPhone = (activeProfile?.phoneNumber?.isNotEmpty == true)
        ? activeProfile!.phoneNumber!
        : '+94 77 123 4567';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Top Green Header Bar ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF143823),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Role Badge + Tap to switch text
                    GestureDetector(
                      onTap: _showRoleSwitchSheet,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF27B50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CUSTOMER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to switch role',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'DineQueue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // --- 2. Customer Avatar & Info Header ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar Circle with Image Attachment support
                        UserAvatar(
                          profile: activeProfile,
                          name: userName,
                          size: 64,
                          onTap: _navigateToEditProfile,
                        ),
                        const SizedBox(width: 16),

                        // Name, Email, Phone
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

                        // Edit Pencil Button
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
                                color: const Color(0xFFF27B50),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Current Role: Customer',
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
                      icon: Icons.storefront_outlined,
                      title: 'My Reviews',
                      onTap: _showReviewsSheet,
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications & Reminders',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const CustomerNotificationsSheet(),
                        );
                      },
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
                              'For live restaurant booking support or inquiries, please contact support@dinequeue.com or call +94 11 234 5678.',
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
                              'DineQueue protects your private dining information and real-time location. All bookings and queue tickets are encrypted end-to-end.',
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
                        onPressed: _isSigningOut ? null : _handleSignOut,
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
