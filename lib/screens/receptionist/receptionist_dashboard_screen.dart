import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/restaurant_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/receptionist_context.dart';
import '../sign_in_screen.dart';
import 'reservation_summary_screen.dart';
import 'floor_overview_screen.dart';
import 'live_queue_screen.dart';
import 'receptionist_profile_screen.dart';
import '../../features/receptionist/presentation/widgets/add_walk_in_dialog.dart';
import '../../features/receptionist/presentation/widgets/reassign_table_dialog.dart';
import '../../shared/widgets/role_header_widget.dart';
import '../../shared/widgets/role_bottom_nav_widget.dart';
import '../../shared/widgets/top_toast.dart' hide ToastType;
import '../../shared/widgets/app_toast.dart';
import '../../models/reservation_model.dart';
import '../../features/receptionist/data/models/floor_table_model.dart';

class ReceptionistDashboardScreen extends StatefulWidget {
  final UserProfile profile;

  const ReceptionistDashboardScreen({super.key, required this.profile});

  @override
  State<ReceptionistDashboardScreen> createState() => _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState extends State<ReceptionistDashboardScreen> {
  UserProfile? _currentProfile;

  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  late final Stream<List<RestaurantModel>> _restaurantsStream;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _restaurantsStream = SupabaseService().streamActiveRestaurants();
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

  @override
  Widget build(BuildContext context) {
    final activeProfile = _currentProfile ?? widget.profile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RoleHeaderWidget(
        roleName: 'RECEPTIONIST',
        roleColor: const Color(0xFFFF6B35),
        isSigningOut: _isSigningOut,
        onSignOut: _signOut,
        profile: activeProfile,
        onProfileUpdated: (updated) => setState(() => _currentProfile = updated),
      ),
      body: _buildDashboardBody(),
      bottomNavigationBar: RoleBottomNavWidget(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return; // already here
          Widget? destination;
          if (index == 1) {
            destination = ReservationSummaryScreen(profile: widget.profile);
          } else if (index == 2) {
            destination = FloorOverviewScreen(profile: widget.profile);
          } else if (index == 3) {
            destination = LiveQueueScreen(profile: widget.profile);
          } else if (index == 4) {
            destination = ReceptionistProfileScreen(profile: widget.profile);
          }
          if (destination != null) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => destination!,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
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

  Widget _buildDashboardBody() {
    final activeProfile = _currentProfile ?? widget.profile;

    return StreamBuilder<List<RestaurantModel>>(
      stream: _restaurantsStream,
      builder: (context, snapshot) {
        final restaurants = snapshot.data ?? [];
        if (restaurants.isNotEmpty) {
          ReceptionistContext().initialize(
            restaurants,
            preferredRestaurantId: activeProfile.restaurantId,
          );
        }

        return ValueListenableBuilder<RestaurantModel?>(
          valueListenable: ReceptionistContext().activeRestaurantNotifier,
          builder: (context, activeRestaurant, _) {
            final activeRestaurantId = ReceptionistContext().activeRestaurantId;
            final activeRestaurantName = ReceptionistContext().activeRestaurantName;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRestaurantSelector(restaurants, activeProfile, activeRestaurant),
                      ),
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'On Duty',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard('Today\'s RSV', '2', Icons.calendar_today_outlined, const Color(0xFFF8FAFC), const Color(0xFF1E293B), const Color(0xFF64748B)),
                  _buildStatCard('Available', '5/12', Icons.check_circle_outline, const Color(0xFFF0FDF4), const Color(0xFF10B981), const Color(0xFF10B981)),
                  _buildStatCard('Waiting Queue', '4', Icons.people_outline, const Color(0xFFFFF7ED), const Color(0xFFD97706), const Color(0xFFD97706)),
                  _buildStatCard('Occupied', '4', Icons.restaurant, const Color(0xFFFEF2F2), const Color(0xFFDC2626), const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => AddWalkInDialog.show(context),
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                      label: const Text('+ Walk-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF143621),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => FloorOverviewScreen(profile: widget.profile),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      icon: const Icon(Icons.grid_view, color: Color(0xFF1E293B), size: 20),
                      label: const Text('Floor Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Dynamic Upcoming Arrivals for active restaurant
              StreamBuilder<List<ReservationModel>>(
                key: ValueKey('arrivals_$activeRestaurantId'),
                stream: SupabaseService().streamAllRestaurantReservations(activeRestaurantId),
                builder: (context, rsvSnapshot) {
                  final allReservations = rsvSnapshot.data ?? [];
                  final activeArrivals = allReservations
                      .where((r) => r.status.toLowerCase() != 'cancelled')
                      .toList();
                  activeArrivals.sort((a, b) {
                    final aConfirmed = a.status.toLowerCase() == 'confirmed';
                    final bConfirmed = b.status.toLowerCase() == 'confirmed';
                    if (aConfirmed && !bConfirmed) return -1;
                    if (!aConfirmed && bConfirmed) return 1;
                    return a.time.compareTo(b.time);
                  });
                  final displayArrivals = activeArrivals.take(2).toList();
                  final targetRestaurantId = activeRestaurantId;
                  final targetRestaurantName = activeRestaurantName;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Arrivals',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => ReservationSummaryScreen(profile: widget.profile),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                            },
                            child: Text(
                              'View All (${activeArrivals.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (displayArrivals.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              'No upcoming arrivals for $targetRestaurantName',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        ...displayArrivals.map((rsv) {
                          final isConfirmed = rsv.status.toLowerCase() == 'confirmed';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildArrivalCard(
                              name: rsv.guestName,
                              time: rsv.time,
                              guests: '${rsv.partySize} Guests',
                              table: (rsv.assignedTable != null && rsv.assignedTable!.isNotEmpty)
                                  ? rsv.assignedTable!
                                  : 'Assigned on arrival',
                              requirement: (rsv.specialNotes != null && rsv.specialNotes!.isNotEmpty)
                                  ? rsv.specialNotes!
                                  : 'No special requirements noted.',
                              status: isConfirmed ? 'Confirmed' : 'Completed',
                              isConfirmed: isConfirmed,
                              showActions: isConfirmed,
                              onCheckInPressed: () async {
                                await SupabaseService().updateReservationStatus(rsv.id, 'completed');
                                if (rsv.assignedTable != null && rsv.assignedTable!.isNotEmpty) {
                                  final floorTables = SupabaseService().getFloorTablesSync(restaurantId: targetRestaurantId);
                                  final matchTable = floorTables.where((t) => t.name.toLowerCase() == rsv.assignedTable!.toLowerCase()).firstOrNull;
                                  if (matchTable != null) {
                                    await SupabaseService().updateFloorTableStatus(
                                      restaurantId: targetRestaurantId,
                                      tableId: matchTable.id,
                                      status: FloorTableStatus.occupied,
                                      guestName: rsv.guestName,
                                    );
                                  }
                                }
                                if (context.mounted) {
                                  TopToast.show(
                                    context,
                                    message: '${rsv.guestName} checked in and seated',
                                    backgroundColor: const Color(0xFF2E9B60),
                                    icon: Icons.check_circle,
                                  );
                                }
                              },
                              onReassignPressed: () async {
                                await ReassignTableDialog.show(
                                  context,
                                  reservation: rsv,
                                  restaurantId: targetRestaurantId,
                                  restaurantName: targetRestaurantName,
                                );
                              },
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildRestaurantSelector(
    List<RestaurantModel> restaurants,
    UserProfile profile,
    RestaurantModel? activeRestaurant,
  ) {
    final currentName = activeRestaurant?.name ?? ReceptionistContext().activeRestaurantName;
    if (restaurants.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentName,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Receptionist Desk • Connecting to database',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final active = activeRestaurant ??
        ReceptionistContext().activeRestaurant ??
        restaurants.first;

    final dropdownList = List<RestaurantModel>.from(restaurants);
    if (!dropdownList.any((r) => r.id == active.id)) {
      dropdownList.add(active);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PopupMenuButton<RestaurantModel>(
          tooltip: 'Switch Restaurant',
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          elevation: 8,
          onSelected: (RestaurantModel selected) {
            if (selected.id != active.id) {
              ReceptionistContext().setActiveRestaurant(selected);
              AppToast.show(
                context,
                message: 'Managing ${selected.name}',
                title: 'Restaurant Changed',
                type: ToastType.info,
              );
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem<RestaurantModel>(
                enabled: false,
                height: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'SWITCH RESTAURANT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 6),
                    Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                ),
              ),
              ...dropdownList.map((RestaurantModel r) {
                final isSelected = r.id == active.id;
                return PopupMenuItem<RestaurantModel>(
                  value: r,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          size: 18,
                          color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '${r.cuisine} • ${r.location}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ];
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  active.name,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.unfold_more_rounded,
                  size: 18,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Text(
                active.cuisine,
                style: const TextStyle(
                  color: Color(0xFFC2410C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                active.location.isNotEmpty ? active.location : 'Receptionist Desk • Live Operations',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color valueColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor == const Color(0xFFF8FAFC) 
              ? const Color(0xFFE2E8F0) 
              : bgColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildArrivalCard({
    required String name,
    required String time,
    required String guests,
    required String table,
    required String requirement,
    required String status,
    required bool isConfirmed,
    required bool showActions,
    VoidCallback? onCheckInPressed,
    VoidCallback? onReassignPressed,
  }) {
    final statusColor = isConfirmed ? const Color(0xFF10B981) : const Color(0xFF059669);
    final statusBgColor = isConfirmed ? const Color(0xFFECFDF5) : const Color(0xFFD1FAE5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$time • $guests • $table', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Text(requirement, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCheckInPressed ?? () {},
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text('Check In & Seat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9B60),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReassignPressed,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reassign Table', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
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

