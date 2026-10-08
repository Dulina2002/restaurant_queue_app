import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../models/review_model.dart';
import '../../../models/restaurant_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/restaurant_database_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../home_screen.dart';
import '../../sign_in_screen.dart';
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

  void _showReviewsSheet() {
    final userId = _currentProfile?.id ?? 'guest_id';
    
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
              
              StreamBuilder<List<ReviewModel>>(
                stream: RestaurantDatabaseService().streamUserReviews(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }
                  
                  final reviews = snapshot.data ?? [];
                  if (reviews.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'You haven\'t reviewed any restaurants yet.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: reviews.map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
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
                                  children: [
                                    Text(
                                      '${review.restaurantName} — ${review.rating.toStringAsFixed(1)} ★',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '"${review.comment}"',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddReviewSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewSheet() {
    final userId = _currentProfile?.id ?? 'guest_id';
    String? selectedRestaurantId;
    String? selectedRestaurantName;
    double rating = 5.0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Write a Review',
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
                    FutureBuilder<List<RestaurantModel>>(
                      future: RestaurantDatabaseService().getActiveRestaurants(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final restaurants = snapshot.data ?? [];
                        if (restaurants.isEmpty) {
                          return const Text('No restaurants available to review.', style: TextStyle(color: AppColors.textMuted));
                        }
                        
                        if (selectedRestaurantId == null && restaurants.isNotEmpty) {
                          selectedRestaurantId = restaurants.first.id;
                          selectedRestaurantName = restaurants.first.name;
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedRestaurantId,
                          decoration: InputDecoration(
                            labelText: 'Select Restaurant',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: restaurants.map((r) {
                            return DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedRestaurantId = val;
                              selectedRestaurantName = restaurants.firstWhere((r) => r.id == val).name;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFD97706),
                            size: 36,
                          ),
                          onPressed: () => setState(() => rating = index + 1.0),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Your Experience',
                        hintText: 'Tell us about your visit...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting || selectedRestaurantId == null
                            ? null
                            : () async {
                                if (commentController.text.trim().isEmpty) {
                                  AppToast.showError(context, 'Please enter a review comment.');
                                  return;
                                }
                                setState(() => isSubmitting = true);
                                try {
                                  final newReview = ReviewModel(
                                    id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                                    userId: userId,
                                    restaurantId: selectedRestaurantId!,
                                    restaurantName: selectedRestaurantName!,
                                    rating: rating,
                                    comment: commentController.text.trim(),
                                    createdAt: DateTime.now(),
                                  );
                                  await RestaurantDatabaseService().addReview(newReview);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  AppToast.showSuccess(context, 'Review submitted successfully!');
                                } catch (e) {
                                  setState(() => isSubmitting = false);
                                  AppToast.showError(context, 'Failed to submit review: $e');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                MaterialPageRoute(builder: (context) => const SignInScreen()),
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

    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

                    // --- 3. Settings Menu Items List ---
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
