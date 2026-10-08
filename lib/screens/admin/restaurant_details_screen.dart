import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/admin_supabase_service.dart';
import 'admin_theme.dart';
import 'admin_dialogs.dart';
import 'edit_restaurant_screen.dart';
import '../../services/restaurant_image_storage.dart';
import '../../shared/widgets/restaurant_image.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final UserProfile profile;
  final AdminSupabaseService adminService;
  final Map<String, String> restaurant;
  final ValueChanged<Map<String, String>> onRestaurantUpdated;
  final Future<void> Function() onToggleStatus;

  const RestaurantDetailsScreen({
    super.key,
    required this.profile,
    required this.adminService,
    required this.restaurant,
    required this.onRestaurantUpdated,
    required this.onToggleStatus,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  late Map<String, String> _current;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _current = Map<String, String>.from(widget.restaurant);
  }

  void _openSwitchRoleModal() {
    showDialog<void>(
      context: context,
      builder: (_) => SwitchRoleDialog(
        profile: widget.profile,
        currentRole: UserRole.admin,
      ),
    );
  }

  Future<void> _handleToggle() async {
    setState(() => _toggling = true);
    await widget.onToggleStatus();
    if (mounted) {
      final isAvailable = _current['status'] == 'Tables Available';
      setState(() {
        _current['status'] =
            isAvailable ? 'Few Tables Left' : 'Tables Available';
        _current['waitTime'] = isAvailable ? '15m' : '0m';
      });
      setState(() => _toggling = false);
    }
  }

  void _navigateToEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRestaurantScreen(
          profile: widget.profile,
          adminService: widget.adminService,
          restaurant: _current,
          onRestaurantSaved: (updated) {
            setState(() => _current = updated);
            widget.onRestaurantUpdated(updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _current['name'] ?? 'Restaurant';
    final cuisine = _current['cuisine'] ?? 'Italian • Seafood';
    final price = _current['price'] ?? r'$$$';
    final status = _current['status'] ?? 'Tables Available';
    final isAvailable = status == 'Tables Available';

    final address = _current['address']?.isNotEmpty == true
        ? _current['address']!
        : '42 Marine Drive, Colombo 03';
    final phone = _current['phone'] != null && _current['phone'] != 'Not provided'
        ? _current['phone']!
        : '+94 11 257 8899';
    final email = _current['email']?.isNotEmpty == true
        ? _current['email']!
        : 'info@oceanbistro.lk';
    final hours = _current['openingHours']?.isNotEmpty == true
        ? _current['openingHours']!
        : '11:00 AM - 11:00 PM';
    final capacity = _current['capacity']?.isNotEmpty == true
        ? _current['capacity']!
        : '50 Guests';
    final waitTime = _current['waitTime'] ?? '0m';
    final id = _current['id'] ?? '';

    final imageUrl = (_current['imageUrl'] != null && _current['imageUrl']!.isNotEmpty)
        ? _current['imageUrl']!
        : RestaurantImageStorage().getImage(id: id, name: name, cuisine: cuisine) ??
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // Green Header Area
          Container(
            color: AdminTheme.headerGreen,
            child: SafeArea(
              bottom: false,
              child: _buildTopBar(),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AdminTheme.borderSubtle, width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AdminTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Restaurant Hero Image
                    RestaurantImage(
                      imageUrl: imageUrl,
                      restaurantId: id,
                      restaurantName: name,
                      cuisine: cuisine,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    const SizedBox(height: 14),
                    // Restaurant Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AdminTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AdminTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$cuisine • $price',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AdminTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? AdminTheme.badgeGreenBg
                                      : AdminTheme.badgeOrangeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isAvailable
                                        ? AdminTheme.badgeGreenText
                                        : AdminTheme.badgeOrangeText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // 2x2 Stats Grid
                          Row(
                            children: [
                              Expanded(
                                child: _statItem(
                                  'STATUS',
                                  isAvailable ? 'Active' : 'Limited',
                                  isAvailable
                                      ? AdminTheme.badgeGreenText
                                      : AdminTheme.badgeOrangeText,
                                ),
                              ),
                              Expanded(
                                child: _statItem(
                                  'AVAILABILITY',
                                  isAvailable ? '12 tables free' : 'Few tables',
                                  AdminTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _statItem(
                                  'WAIT TIME',
                                  waitTime,
                                  AdminTheme.textDark,
                                ),
                              ),
                              Expanded(
                                child: _statItem(
                                  'CAPACITY',
                                  capacity,
                                  AdminTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final mins = int.tryParse(waitTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                              final isDirect = mins == 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDirect ? AdminTheme.badgeGreenBg : AdminTheme.badgeOrangeBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isDirect ? Icons.flash_on_rounded : Icons.people_alt_rounded,
                                      size: 16,
                                      color: isDirect ? AdminTheme.badgeGreenText : AdminTheme.badgeOrangeText,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isDirect
                                          ? 'Customer Button: Direct Booking (0m wait)'
                                          : 'Customer Button: Join Queue (${mins}m wait)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDirect ? AdminTheme.badgeGreenText : AdminTheme.badgeOrangeText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(
                              height: 36, color: AdminTheme.borderSubtle),
                          // Contact & Location Details
                          _infoRow(
                            Icons.location_on_outlined,
                            'LOCATION',
                            address,
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            Icons.phone_outlined,
                            'CONTACT NUMBER',
                            phone,
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            Icons.email_outlined,
                            'EMAIL ADDRESS',
                            email,
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            Icons.access_time_rounded,
                            'OPENING HOURS',
                            hours,
                          ),
                          const SizedBox(height: 24),
                          // Action Buttons
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text(
                                'Edit Restaurant',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _toggling ? null : _handleToggle,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AdminTheme.primaryDark,
                                side: const BorderSide(
                                    color: AdminTheme.borderSubtle, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _toggling
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AdminTheme.primaryDark,
                                      ),
                                    )
                                  : const Text(
                                      'Toggle Status',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AdminTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AdminTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AdminTheme.headerGreen,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.accentOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ADMINISTRATOR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openSwitchRoleModal,
            child: const Text(
              'Tap to switch role',
              style: TextStyle(
                color: AdminTheme.headerTextMint,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'DineQueue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AdminTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_rounded,
                    color: AdminTheme.primaryDark, size: 22),
                SizedBox(height: 2),
                Text(
                  'System',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _openSwitchRoleModal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.badge_outlined,
                    color: AdminTheme.textSecondary, size: 22),
                SizedBox(height: 2),
                Text(
                  'Roles',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
