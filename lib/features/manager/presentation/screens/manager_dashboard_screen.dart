import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/restaurant_database_service.dart';
import '../../../../screens/sign_in_screen.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../data/models/manager_dashboard_model.dart';
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
  int _selectedTab = 0; // 0: Overview, 1: Tables, 2: Live Menu
  int _selectedTimeFilter = 1; // 0: Today, 1: This Week
  int _bottomNavIndex = 0; // 0: Dashboard, 1: Profile

  /// Restaurants loaded live from the database for the picker.
  List<RestaurantModel> _restaurants = const [];
  bool _restaurantsLoaded = false;
  Object? _restaurantsError;
  StreamSubscription<List<RestaurantModel>>? _restaurantsSub;

  /// Id of the restaurant every tab is currently showing.
  String? _selectedRestaurantId;

  /// Set after adding a restaurant so it is auto-selected once it streams in.
  String? _pendingSelectId;

  /// Live overview data (tables + queue + reservations) of the selected restaurant.
  Stream<ManagerLiveSnapshot>? _snapshotStream;

  UserProfile? _currentProfile;

  RestaurantModel? get _selectedRestaurant {
    for (final r in _restaurants) {
      if (r.id == _selectedRestaurantId) return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _listenToRestaurants();
  }

  @override
  void dispose() {
    _restaurantsSub?.cancel();
    super.dispose();
  }

  void _listenToRestaurants() {
    _restaurantsSub?.cancel();
    _restaurantsError = null;
    _restaurantsLoaded = false;
    _restaurantsSub = _firestoreService.streamManagedRestaurants().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _restaurants = list;
          _restaurantsLoaded = true;
          _restaurantsError = null;
          final pending = _pendingSelectId;
          if (pending != null && list.any((r) => r.id == pending)) {
            _pendingSelectId = null;
            _applySelection(pending);
          } else if (_selectedRestaurantId == null || !list.any((r) => r.id == _selectedRestaurantId)) {
            _applySelection(list.isEmpty ? null : list.first.id);
          }
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _restaurantsError = error;
          _restaurantsLoaded = true;
        });
      },
    );
  }

  /// Switches every tab to [id] and re-subscribes the overview stream so the
  /// KPIs, tables, queue and chart immediately reflect that restaurant.
  void _applySelection(String? id) {
    _selectedRestaurantId = id;
    _snapshotStream = id == null ? null : _firestoreService.streamManagerSnapshot(id);
  }

  void _selectRestaurant(String id) {
    if (id == _selectedRestaurantId) return;
    setState(() => _applySelection(id));
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
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final duplicate = _restaurants.any((r) => r.name.toLowerCase() == name.toLowerCase());
                if (duplicate) {
                  AppToast.showError(
                    context,
                    '"$name" already exists in your restaurant list.',
                    title: 'Duplicate Restaurant',
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                try {
                  final created = await _firestoreService.addRestaurant(name);
                  if (!mounted) return;
                  // Select it immediately and apply to manager view.
                  setState(() {
                    if (!_restaurants.any((r) => r.id == created.id)) {
                      _restaurants = [..._restaurants, created];
                    }
                    _applySelection(created.id);
                  });
                  AppToast.showSuccess(
                    context,
                    '$name registered successfully!',
                    title: 'Restaurant Added',
                  );
                } catch (e) {
                  if (!mounted) return;
                  AppToast.showError(
                    context,
                    'Could not add restaurant: $e',
                    title: 'Error',
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

  void _showRoleSelectorDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Switch User Role',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF064E3B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select any of the 4 application roles to preview its tailored UI/UX experience.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _buildRoleOptionTile(
                sheetContext: sheetContext,
                title: 'Customer',
                subtitle: 'Table booking & virtual queue',
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                isSelected: false,
              ),
              const SizedBox(height: 12),
              _buildRoleOptionTile(
                sheetContext: sheetContext,
                title: 'Receptionist',
                subtitle: 'Staff live tables & check-in',
                icon: Icons.room_service_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBgColor: const Color(0xFFF3E8FF),
                isSelected: false,
              ),
              const SizedBox(height: 12),
              _buildRoleOptionTile(
                sheetContext: sheetContext,
                title: 'Manager',
                subtitle: 'Reports, capacity & menu',
                icon: Icons.show_chart_rounded,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                isSelected: true,
              ),
              const SizedBox(height: 12),
              _buildRoleOptionTile(
                sheetContext: sheetContext,
                title: 'Administrator',
                subtitle: 'Platform & restaurant management',
                icon: Icons.storefront_rounded,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFDCFCE7),
                isSelected: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOptionTile({
    required BuildContext sheetContext,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isSelected,
  }) {
    const darkGreen = Color(0xFF064E3B);
    return InkWell(
      onTap: () async {
        Navigator.pop(sheetContext);
        try {
          await _authService.signOut();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? darkGreen : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? darkGreen : const Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- Full Width Top Header Bar (Matching Provided Screenshot) ---
            GestureDetector(
              onTap: _showRoleSelectorDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D2017),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF25430),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'MANAGER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tap to switch role',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'DineQueue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Scrollable Dashboard Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  (_selectedRestaurant?.name ?? (_restaurantsLoaded ? 'No restaurant' : 'Loading...')).toUpperCase(),
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
                              _selectRestaurant(value);
                            }
                          },
                          itemBuilder: (context) {
                            return [
                              ..._restaurants.map(
                                (rest) => PopupMenuItem<String>(
                                  value: rest.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        rest.id == _selectedRestaurantId ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: rest.id == _selectedRestaurantId ? AppColors.primary : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        rest.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: rest.id == _selectedRestaurantId ? FontWeight.bold : FontWeight.normal,
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
                    if (!_restaurantsLoaded)
                      const _CenteredStatus(child: CircularProgressIndicator(color: AppColors.primary))
                    else if (_restaurantsError != null && _restaurants.isEmpty)
                      _StatusCard(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load restaurants',
                        message: '$_restaurantsError',
                        actionLabel: 'Retry',
                        onAction: () => setState(_listenToRestaurants),
                      )
                    else if (_selectedRestaurantId == null)
                      _StatusCard(
                        icon: Icons.storefront,
                        title: 'No restaurants yet',
                        message: 'Add your first restaurant to start managing tables, menu and queue.',
                        actionLabel: 'Add Restaurant',
                        onAction: _showAddNewRestaurantDialog,
                      )
                    else if (_selectedTab == 1) ...[
                      TablesTabWidget(
                        restaurants: _restaurants,
                        selectedRestaurantId: _selectedRestaurantId!,
                      ),
                    ] else if (_selectedTab == 2) ...[
                      LiveMenuTabWidget(
                        restaurants: _restaurants,
                        selectedRestaurantId: _selectedRestaurantId!,
                      ),
                    ] else ...[
                      _buildOverview(),
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

  /// Overview tab: KPIs, fast actions and hourly chart for the selected
  /// restaurant, driven by one live snapshot stream.
  Widget _buildOverview() {
    final restaurantId = _selectedRestaurantId!;
    final isWeek = _selectedTimeFilter == 1;

    return StreamBuilder<ManagerLiveSnapshot>(
      stream: _snapshotStream,
      builder: (context, snapshot) {
        final data = snapshot.data;

        Widget kpiSection;
        Widget chartSection;
        if (data == null && snapshot.hasError) {
          kpiSection = _StatusCard(
            icon: Icons.cloud_off_rounded,
            title: 'Live data unavailable',
            message: '${snapshot.error}',
            actionLabel: 'Retry',
            onAction: () => setState(() => _applySelection(restaurantId)),
          );
          chartSection = const SizedBox.shrink();
        } else if (data == null) {
          kpiSection = const _CenteredStatus(child: CircularProgressIndicator(color: AppColors.primary));
          chartSection = const SizedBox.shrink();
        } else {
          kpiSection = GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _KpiCardWidget(
                label: 'Total Bookings',
                value: data.totalBookings(isWeek: isWeek).toString(),
                icon: Icons.smartphone,
                bgColor: AppColors.mintTint,
                iconColor: AppColors.primary,
                iconBgColor: Colors.white,
              ),
              _KpiCardWidget(
                label: 'Floor Turnover',
                value: data.floorTurnover(isWeek: isWeek),
                icon: Icons.bolt,
                bgColor: AppColors.peachTint,
                iconColor: AppColors.accentOrange,
                iconBgColor: Colors.white,
              ),
              _KpiCardWidget(
                label: 'Avg Queue Wait',
                value: '${data.avgQueueWaitMinutes} min',
                icon: Icons.access_time_filled,
                bgColor: AppColors.amberTint,
                iconColor: AppColors.accentAmber,
                iconBgColor: Colors.white,
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: _KpiCardWidget(
                  label: 'Available Tables',
                  value: data.availableTablesRatio,
                  icon: Icons.table_restaurant,
                  bgColor: AppColors.skyTint,
                  iconColor: AppColors.primary,
                  iconBgColor: Colors.white,
                ),
              ),
            ],
          );
          chartSection = _HourlyVelocityChartWidget(data: data.hourlyVelocity(isWeek: isWeek));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            kpiSection,
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
                    onPressed: () => QuickTurnTablesSheet.show(context, restaurantId: restaurantId),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text(
                      'Quick Turn Tables',
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
                    onPressed: () => AiFloorOptimizerSheet.show(context, restaurantId: restaurantId),
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
            chartSection,
          ],
        );
      },
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
    final peakItems = data.where((item) => item.isPeak);
    final peakLabel = peakItems.isEmpty ? 'No activity yet' : peakItems.first.hour;

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
                peakItems.isEmpty ? peakLabel : 'Peak: $peakLabel',
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

class _CenteredStatus extends StatelessWidget {
  final Widget child;

  const _CenteredStatus({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: child),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
