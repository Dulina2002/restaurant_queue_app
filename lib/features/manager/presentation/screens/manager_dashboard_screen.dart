import 'package:flutter/material.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/queue_entry_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/restaurant_database_service.dart';
import '../../../../screens/home_screen.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../data/models/manager_dashboard_model.dart';
import '../../data/models/physical_table_model.dart';
import '../widgets/ai_floor_optimizer_sheet.dart';
import '../widgets/quick_turn_tables_sheet.dart';
import '../widgets/tables_tab_widget.dart';
import '../widgets/live_menu_tab_widget.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final UserProfile? profile;

  const ManagerDashboardScreen({super.key, this.profile});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  int _selectedTab = 0; // 0: Overview, 1: Tables, 2: Live Menu
  int _selectedTimeFilter = 1; // 0: Today, 1: This Week
  int _bottomNavIndex = 0; // 0: Dashboard, 1: Profile

  String _selectedRestaurant = 'Ocean Bistro';
  final List<String> _availableRestaurants = [
    'Ocean Bistro',
    'The Mango Tree',
    'Nihonbashi',
  ];

  late final ManagerDashboardData _dashboardData;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _dashboardData = ManagerDashboardData.mock();
  }

  Future<void> _signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to log out of your Manager session?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

    if (shouldLogout == true) {
      setState(() => _isSigningOut = true);
      try {
        await _authService.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } finally {
        if (mounted) setState(() => _isSigningOut = false);
      }
    }
  }

  String _getAvatarInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'MN';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showAddNewRestaurantDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.storefront, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add New Restaurant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the name of the new restaurant entity you wish to manage.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Restaurant Name',
                  hintText: 'e.g. Bavette Steakhouse',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    if (!_availableRestaurants.contains(name)) {
                      _availableRestaurants.add(name);
                    }
                    _selectedRestaurant = name;
                  });
                  Navigator.pop(dialogContext);
                  AppToast.showSuccess(
                    context,
                    '$name registered successfully!',
                    title: 'Restaurant Added',
                  );
                }
              },
              child: const Text('Add Restaurant', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Top Header Bar ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'MANAGER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap to switch role',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'DineQueue',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final updated = await Navigator.push<UserProfile>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(profile: _currentProfile ?? widget.profile),
                                  ),
                                );
                                if (updated != null) {
                                  setState(() => _currentProfile = updated);
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getAvatarInitials(_currentProfile?.fullName ?? widget.profile?.fullName ?? 'Manager'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _isSigningOut ? null : _signOut,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                alignment: Alignment.center,
                                child: _isSigningOut
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.logout_rounded,
                                        size: 15,
                                        color: AppColors.textSecondary,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Dashboard Title & Venue Pill ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Manager Dashboard',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Floor Operations • Live Menu • Dynamic Yield Control',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Select or Add Restaurant',
                          offset: const Offset(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedRestaurant.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          onSelected: (value) {
                            if (value == '__add_new__') {
                              _showAddNewRestaurantDialog();
                            } else {
                              setState(() {
                                _selectedRestaurant = value;
                              });
                            }
                          },
                          itemBuilder: (context) {
                            return [
                              ..._availableRestaurants.map(
                                (rest) => PopupMenuItem<String>(
                                  value: rest,
                                  child: Row(
                                    children: [
                                      Icon(
                                        rest == _selectedRestaurant ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: rest == _selectedRestaurant ? AppColors.primary : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        rest,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: rest == _selectedRestaurant ? FontWeight.bold : FontWeight.normal,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: '__add_new__',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      '+ Add New Restaurant',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Tabs (Overview / Tables / Live Menu) ---
                    Row(
                      children: [
                        _buildTabPill('Overview', 0),
                        const SizedBox(width: 8),
                        _buildTabPill('Tables', 1),
                        const SizedBox(width: 8),
                        _buildTabPill('Live Menu', 2),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Tab Content Switching ---
                    if (_selectedTab == 1) ...[
                      TablesTabWidget(
                        selectedRestaurant: _selectedRestaurant,
                        availableRestaurants: _availableRestaurants,
                      ),
                    ] else if (_selectedTab == 2) ...[
                      LiveMenuTabWidget(
                        selectedRestaurant: _selectedRestaurant,
                        availableRestaurants: _availableRestaurants,
                      ),
                    ] else ...[
                      // --- Executive KPIs Header & Time Filter ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Executive KPIs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                _buildTimeFilterPill('Today', 0),
                                _buildTimeFilterPill('This Week', 1),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- 2x2 Live KPI Cards Grid ---
                      StreamBuilder<List<PhysicalTable>>(
                        stream: FirestoreService().streamTables(restaurantId: 'ocean_bistro'),
                        builder: (context, tablesSnapshot) {
                          final tables = tablesSnapshot.data ?? PhysicalTable.mockList();
                          final totalTables = tables.length;
                          final availableCount = tables.where((t) => t.status == TableStatus.available).length;
                          final availableTablesRatio = '$availableCount / $totalTables';

                          return StreamBuilder<List<QueueEntryModel>>(
                            stream: FirestoreService().streamQueue('ocean_bistro'),
                            builder: (context, queueSnapshot) {
                              final queue = queueSnapshot.data ?? [];
                              int totalWait = 0;
                              for (final entry in queue) {
                                totalWait += entry.estimatedWaitMinutes;
                              }
                              final avgWaitMinutes = queue.isEmpty ? 14 : (totalWait / queue.length).round();
                              final totalBookingsBase = _selectedTimeFilter == 1 ? 195 : 42;
                              final totalBookingsCount = (totalBookingsBase + queue.length).toString();
                              final occupiedCount = tables.where((t) => t.status == TableStatus.occupied).length;
                              final turnoverRate = '${(3.0 + (occupiedCount * 0.2)).toStringAsFixed(1)}x';

                              return GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.4,
                                children: [
                                  _KpiCardWidget(
                                    label: 'Total Bookings',
                                    value: totalBookingsCount,
                                    icon: Icons.smartphone,
                                    bgColor: AppColors.mintTint,
                                    iconColor: AppColors.primary,
                                    iconBgColor: Colors.white,
                                  ),
                                  _KpiCardWidget(
                                    label: 'Floor Turnover',
                                    value: turnoverRate,
                                    icon: Icons.bolt,
                                    bgColor: AppColors.peachTint,
                                    iconColor: AppColors.accentOrange,
                                    iconBgColor: Colors.white,
                                  ),
                                  _KpiCardWidget(
                                    label: 'Avg Queue Wait',
                                    value: '$avgWaitMinutes min',
                                    icon: Icons.access_time_filled,
                                    bgColor: AppColors.amberTint,
                                    iconColor: AppColors.accentAmber,
                                    iconBgColor: Colors.white,
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedTab = 1),
                                    child: _KpiCardWidget(
                                      label: 'Available Tables',
                                      value: availableTablesRatio,
                                      icon: Icons.table_restaurant,
                                      bgColor: AppColors.skyTint,
                                      iconColor: AppColors.primary,
                                      iconBgColor: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- Manager Fast Actions ---
                      Row(
                        children: const [
                          Icon(Icons.bolt, size: 18, color: AppColors.accentOrange),
                          SizedBox(width: 4),
                          Text(
                            'Manager Fast Actions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => QuickTurnTablesSheet.show(context),
                              icon: const Icon(Icons.bolt, size: 16),
                              label: const Text(
                                'Quick Turn 2 Tables',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => AiFloorOptimizerSheet.show(context),
                              icon: const Icon(Icons.tune, size: 16, color: AppColors.textPrimary),
                              label: const Text(
                                'Optimize Floor',
                                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- Hourly Velocity Chart ---
                      StreamBuilder<List<HourlyVelocityData>>(
                        stream: _firestoreService.streamHourlyVelocity(restaurantId: 'ocean_bistro'),
                        builder: (context, snapshot) {
                          final chartData = snapshot.data ?? _dashboardData.hourlyVelocity;
                          return _HourlyVelocityChartWidget(data: chartData);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // --- Bottom Navigation Bar ---
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard'),
                  _buildNavItem(1, Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterPill(String label, int index) {
    final isSelected = _selectedTimeFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (index == 1) {
          final updated = await Navigator.push<UserProfile>(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(profile: _currentProfile ?? widget.profile),
            ),
          );
          if (updated != null) {
            setState(() => _currentProfile = updated);
          }
        } else {
          setState(() => _bottomNavIndex = index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final Color iconBgColor;

  const _KpiCardWidget({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: iconColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyVelocityChartWidget extends StatelessWidget {
  final List<HourlyVelocityData> data;

  const _HourlyVelocityChartWidget({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final peakItem = data.firstWhere(
      (item) => item.isPeak,
      orElse: () => data.isNotEmpty
          ? data.reduce((a, b) => a.value >= b.value ? a : b)
          : const HourlyVelocityData(hour: '8 PM', value: 0.95, isPeak: true),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Hourly Floor Load & Turn Velocity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Peak: ${peakItem.hour}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final Color barColor = item.isPeak ? AppColors.accentOrange : AppColors.primary;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: item.value,
                          child: Container(
                            width: 22,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.hour,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
