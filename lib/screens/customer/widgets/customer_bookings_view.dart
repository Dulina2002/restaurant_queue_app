import 'package:flutter/material.dart';
import '../../../models/reservation_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/restaurant_database_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import 'create_booking_modal.dart';

import '../booking/reservation_details_screen.dart';
import '../booking/reserve_table_stepper_screen.dart';
import '../booking/modify_reservation_screen.dart';
import '../../../models/restaurant_model.dart';

class CustomerBookingsView extends StatefulWidget {
  final UserProfile? profile;
  final VoidCallback onBrowseRestaurants;

  const CustomerBookingsView({
    super.key,
    this.profile,
    required this.onBrowseRestaurants,
  });

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView> {
  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();
  int _selectedTab = 0; // 0: Upcoming, 1: History

  void _confirmCancelBooking(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancel Reservation?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your table reservation at ${reservation.restaurantName} for ${reservation.date} at ${reservation.time}?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Booking', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.cancelReservation(reservation.id);
                if (!mounted) return;
                AppToast.show(
                  context,
                  title: 'Reservation Cancelled',
                  message: 'Cancelled booking ${reservation.reservationCode} at ${reservation.restaurantName}',
                  type: ToastType.error,
                );
              } catch (e) {
                if (!mounted) return;
                AppToast.showError(
                  context,
                  'Failed to cancel reservation: $e',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
  }

  void _openBookingWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReserveTableStepperScreen(
          restaurant: const RestaurantModel(
            id: 'ocean_bistro',
            name: 'Ocean Bistro',
            cuisine: 'Italian',
            tag: 'Italian • Seafood',
            location: '42 Marine Drive, Colombo 03, Sri Lanka',
            rating: 4.8,
            reviewsCount: 342,
            isActive: true,
            isQueueAvailable: true,
            estWait: '12 min wait',
            waitlistCount: 3,
          ),
          profile: widget.profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = (widget.profile?.id.isNotEmpty == true) ? widget.profile!.id : 'guest_id';

    return StreamBuilder<List<ReservationModel>>(
      stream: _firestoreService.streamUserReservations(userId),
      builder: (context, snapshot) {
        final allReservations = snapshot.data ?? [];
        final upcoming = allReservations.where((r) => r.status.toLowerCase() != 'cancelled' && r.status.toLowerCase() != 'completed').toList();
        final history = allReservations.where((r) => r.status.toLowerCase() == 'cancelled' || r.status.toLowerCase() == 'completed').toList();

        final currentList = _selectedTab == 0 ? upcoming : history;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Book New Table Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your upcoming and past reservations',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openBookingWizard,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Book Table', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D3B2E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Segmented Tabs: Upcoming vs History
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: 'Upcoming (${upcoming.length})',
                        index: 0,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: 'History (${history.length})',
                        index: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reservations List
              if (currentList.isEmpty)
                _buildEmptyState()
              else
                ...currentList.map((res) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildReservationCard(res),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({required String label, required int index}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel res) {
    final isConfirmed = res.status.toLowerCase() == 'confirmed';
    final isCancelled = res.status.toLowerCase() == 'cancelled';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationDetailsScreen(
              reservation: res,
              profile: widget.profile,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Restaurant Name & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.restaurantName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Booking ${res.reservationCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? const Color(0xFFE8F5E9)
                        : (isCancelled ? const Color(0xFFFFEBEE) : AppColors.surface),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConfirmed
                            ? Icons.check_circle_rounded
                            : (isCancelled ? Icons.cancel_rounded : Icons.info_outline),
                        size: 13,
                        color: isConfirmed
                            ? const Color(0xFF10B981)
                            : (isCancelled ? const Color(0xFFEF4444) : AppColors.textMuted),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        res.status.toUpperCase(),
                        style: TextStyle(
                          color: isConfirmed
                              ? const Color(0xFF10B981)
                              : (isCancelled ? const Color(0xFFEF4444) : AppColors.textMuted),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),

            // Details Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Date',
                  value: res.date.isNotEmpty ? res.date : 'Today',
                ),
                _buildDetailItem(
                  icon: Icons.access_time_rounded,
                  title: 'Time',
                  value: res.time.isNotEmpty ? res.time : '7:30 PM',
                ),
                _buildDetailItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Party',
                  value: '${res.partySize} Guests',
                ),
              ],
            ),

            // Cancel Action (for confirmed upcoming bookings)
            if (isConfirmed && _selectedTab == 0) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tap card for details',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModifyReservationScreen(
                          reservation: res,
                          profile: widget.profile,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 15, color: Color(0xFF0D3B2E)),
                    label: const Text(
                      'Modify',
                      style: TextStyle(
                        color: Color(0xFF0D3B2E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmCancelBooking(res),
                    icon: const Icon(Icons.close, size: 15, color: Color(0xFFEF4444)),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0 ? 'No Upcoming Reservations' : 'No Reservation History',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTab == 0
                ? 'Reserve a table in advance at top restaurants with instant confirmation.'
                : 'Your past and cancelled dining bookings will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
          ),
          if (_selectedTab == 0) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                CreateBookingModal.show(context, profile: widget.profile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Book a Table Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
