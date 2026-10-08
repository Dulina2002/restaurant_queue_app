import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/restaurant_model.dart';
import '../../models/reservation_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/receptionist_context.dart';
import '../home_screen.dart';
import 'receptionist_dashboard_screen.dart';
import 'floor_overview_screen.dart';
import 'live_queue_screen.dart';
import 'receptionist_profile_screen.dart';
import '../../shared/widgets/role_header_widget.dart';
import '../../shared/widgets/role_bottom_nav_widget.dart';
import '../../shared/widgets/app_toast.dart';

class ReservationSummaryScreen extends StatefulWidget {
  final UserProfile profile;

  const ReservationSummaryScreen({super.key, required this.profile});

  @override
  State<ReservationSummaryScreen> createState() => _ReservationSummaryScreenState();
}

class _ReservationSummaryScreenState extends State<ReservationSummaryScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  String _selectedTab = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<List<ReservationModel>>? _reservationsSub;
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;

  String get _currentRestaurantId => ReceptionistContext().activeRestaurantId;
  String get _currentRestaurantName => ReceptionistContext().activeRestaurantName;

  @override
  void initState() {
    super.initState();
    ReceptionistContext().activeRestaurantNotifier.addListener(_onRestaurantChanged);
    _subscribeToReservations();
  }

  void _onRestaurantChanged() {
    if (mounted) {
      _subscribeToReservations();
    }
  }

  void _subscribeToReservations() {
    _reservationsSub?.cancel();
    setState(() => _isLoading = true);

    final restaurantId = _currentRestaurantId;
    _reservationsSub = SupabaseService()
        .streamAllRestaurantReservations(restaurantId)
        .listen((list) {
      if (!mounted) return;
      setState(() {
        _reservations = list;
        _isLoading = false;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _reservationsSub?.cancel();
    ReceptionistContext().activeRestaurantNotifier.removeListener(_onRestaurantChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<ReservationModel> get _filteredReservations {
    return _reservations.where((res) {
      final statusLower = res.status.toLowerCase();
      bool matchesTab = true;
      if (_selectedTab == 'Confirmed') {
        matchesTab = statusLower == 'confirmed';
      } else if (_selectedTab == 'Completed') {
        matchesTab = statusLower == 'completed' || statusLower == 'checked_in';
      } else if (_selectedTab == 'Cancelled') {
        matchesTab = statusLower == 'cancelled';
      }

      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          res.guestName.toLowerCase().contains(query) ||
          res.reservationCode.toLowerCase().contains(query) ||
          (res.assignedTable ?? '').toLowerCase().contains(query) ||
          (res.specialNotes ?? '').toLowerCase().contains(query);

      return matchesTab && matchesSearch;
    }).toList();
  }

  Future<void> _checkInGuest(ReservationModel res) async {
    try {
      await SupabaseService().updateReservationStatus(res.id, 'completed');

      if (mounted) {
        AppToast.showSuccess(
          context,
          '${res.guestName} (${res.reservationCode}) checked in successfully!',
          title: 'Guest Checked In',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'Failed to check in: $e',
          title: 'Error',
        );
      }
    }
  }

  Future<void> _cancelReservation(ReservationModel res) async {
    try {
      await SupabaseService().cancelReservation(res.id);

      if (mounted) {
        AppToast.show(
          context,
          message: 'Reservation ${res.reservationCode} marked as cancelled.',
          title: 'Reservation Cancelled',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'Failed to cancel: $e',
          title: 'Error',
        );
      }
    }
  }

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
    if (index == 1) return; // already on Reservations
    Widget destination;
    if (index == 0) {
      destination = ReceptionistDashboardScreen(profile: widget.profile);
    } else if (index == 2) {
      destination = FloorOverviewScreen(profile: widget.profile);
    } else if (index == 3) {
      destination = LiveQueueScreen(profile: widget.profile);
    } else if (index == 4) {
      destination = ReceptionistProfileScreen(profile: widget.profile);
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

  @override
  Widget build(BuildContext context) {
    final confirmedCount = _reservations.where((r) => r.status.toLowerCase() == 'confirmed').length;
    final completedCount = _reservations.where((r) => r.status.toLowerCase() == 'completed' || r.status.toLowerCase() == 'checked_in').length;
    final cancelledCount = _reservations.where((r) => r.status.toLowerCase() == 'cancelled').length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RoleHeaderWidget(
        roleName: 'RECEPTIONIST',
        roleColor: const Color(0xFFFF6B35),
        isSigningOut: _isSigningOut,
        onSignOut: _signOut,
        profile: widget.profile,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Title + Active Restaurant & Switcher
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reservations Management',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Text(
                              _currentRestaurantName,
                              style: const TextStyle(
                                color: Color(0xFFC2410C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_reservations.length} Total • $confirmedCount Confirmed',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Switcher Button
                StreamBuilder<List<RestaurantModel>>(
                  stream: SupabaseService().streamActiveRestaurants(),
                  builder: (context, snapshot) {
                    final restaurants = snapshot.data ?? [];
                    if (restaurants.isEmpty) return const SizedBox.shrink();

                    return PopupMenuButton<RestaurantModel>(
                      tooltip: 'Switch Restaurant',
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: Colors.white,
                      elevation: 8,
                      onSelected: (selected) {
                        ReceptionistContext().setActiveRestaurant(selected);
                      },
                      itemBuilder: (context) {
                        return restaurants.map((r) {
                          final isSelected = r.id == _currentRestaurantId;
                          return PopupMenuItem<RestaurantModel>(
                            value: r,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.storefront_outlined,
                                  size: 18,
                                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, size: 16, color: Color(0xFF475569)),
                            SizedBox(width: 4),
                            Text(
                              'Switch',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search guest name, code, or table',
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
            const SizedBox(height: 16),

            // Tab Filter Chips with Live Badges
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', _reservations.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Confirmed', confirmedCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', completedCount),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled', cancelledCount),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reservations List or Loading / Empty States
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                ),
              )
            else if (_filteredReservations.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(
                      'No ${_selectedTab == 'All' ? '' : '$_selectedTab '}reservations found for $_currentRestaurantName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reservations placed by guests will appear here in real-time.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              ..._filteredReservations.map((res) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildReservationListCard(res),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNavWidget(
        selectedIndex: 1, // 1 is Reservation
        onDestinationSelected: _navigate,
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF143621) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF143621) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationListCard(ReservationModel res) {
    final statusLower = res.status.toLowerCase();
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String displayStatus;

    if (statusLower == 'completed' || statusLower == 'checked_in') {
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFE6F4EA);
      statusIcon = Icons.check;
      displayStatus = 'Completed';
    } else if (statusLower == 'cancelled') {
      statusColor = const Color(0xFFD32F2F);
      statusBgColor = const Color(0xFFFCE8E8);
      statusIcon = Icons.close;
      displayStatus = 'Cancelled';
    } else {
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFFECFDF5);
      statusIcon = Icons.schedule;
      displayStatus = 'Confirmed';
    }

    final tableInfo = (res.assignedTable != null && res.assignedTable!.isNotEmpty)
        ? res.assignedTable!
        : 'Assigned on arrival';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        res.guestName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        res.reservationCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${res.time} • ${res.partySize} Guests • $tableInfo',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
          if (res.specialNotes != null && res.specialNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                res.specialNotes!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.3),
              ),
            ),
          ],
          if (statusLower == 'confirmed') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _cancelReservation(res),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _checkInGuest(res),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Check In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF143621),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

