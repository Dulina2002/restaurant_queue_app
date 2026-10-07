import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';

class RoleHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String roleName;
  final Color roleColor;
  final bool isSigningOut;
  final VoidCallback onSignOut;
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onProfileUpdated;
  final String? subtitle;

  const RoleHeaderWidget({
    super.key,
    required this.roleName,
    required this.roleColor,
    required this.isSigningOut,
    required this.onSignOut,
    this.profile,
    this.onProfileUpdated,
    this.subtitle,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final name = (profile?.fullName.isNotEmpty == true)
        ? profile!.fullName
        : 'Reception Staff';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: User Avatar + Greeting & Name
              Expanded(
                child: Row(
                  children: [
                    UserAvatar(
                      profile: profile,
                      name: name,
                      size: 42,
                      onTap: () async {
                        final updated = await Navigator.push<UserProfile>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(profile: profile),
                          ),
                        );
                        if (updated != null && onProfileUpdated != null) {
                          onProfileUpdated!(updated);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle ?? _getGreeting(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Role Pill + DineQueue Capsule + Switch Role Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Role Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      roleName.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // DineQueue Brand Capsule
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'DineQueue',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Switch Role / Logout Action Button
                  GestureDetector(
                    onTap: isSigningOut ? null : onSignOut,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isSigningOut
                          ? const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

