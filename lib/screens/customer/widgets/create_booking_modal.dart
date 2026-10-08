import 'package:flutter/material.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/reservation_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/restaurant_database_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';

class CreateBookingModal extends StatefulWidget {
  final RestaurantModel? preselectedRestaurant;
  final UserProfile? profile;
  final VoidCallback? onBookingSuccess;

  const CreateBookingModal({
    super.key,
    this.preselectedRestaurant,
    this.profile,
    this.onBookingSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    RestaurantModel? restaurant,
    UserProfile? profile,
    VoidCallback? onBookingSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateBookingModal(
        preselectedRestaurant: restaurant,
        profile: profile,
        onBookingSuccess: onBookingSuccess,
      ),
    );
  }

  @override
  State<CreateBookingModal> createState() => _CreateBookingModalState();
}

class _CreateBookingModalState extends State<CreateBookingModal> {
  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();
  RestaurantModel? _selectedRestaurant;
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = '7:30 PM';
  int _partySize = 2;
  final TextEditingController _specialRequestsController = TextEditingController();
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '12:00 PM',
    '12:30 PM',
    '1:00 PM',
    '1:30 PM',
    '6:30 PM',
    '7:00 PM',
    '7:30 PM',
    '8:00 PM',
    '8:30 PM',
    '9:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRestaurant = widget.preselectedRestaurant;
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Future<void> _handleConfirmBooking() async {
    if (_selectedRestaurant == null) {
      AppToast.showError(context, 'Please select a restaurant first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reservation = await _firestoreService.createReservation(
        ReservationModel(
          id: '',
          restaurantId: _selectedRestaurant!.id,
          restaurantName: _selectedRestaurant!.name,
          userId: (widget.profile?.id.isNotEmpty == true) ? widget.profile!.id : 'guest_id',
          guestName: (widget.profile?.fullName.isNotEmpty == true) ? widget.profile!.fullName : 'Guest',
          reservationCode: '',
          date: _formatDate(_selectedDate),
          time: _selectedTimeSlot,
          partySize: _partySize,
          status: 'confirmed',
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);

      widget.onBookingSuccess?.call();

      AppToast.showSuccess(
        context,
        'Table booked at ${_selectedRestaurant!.name}! Ticket: ${reservation.reservationCode}',
        title: 'Reservation Confirmed',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(
        context,
        'Failed to book table: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book a Table',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedRestaurant?.name ?? 'Select your dining details',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Select Restaurant (if not preselected)
            if (widget.preselectedRestaurant == null) ...[
              const Text(
                'Restaurant',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<RestaurantModel>>(
                stream: _firestoreService.streamActiveRestaurants(),
                builder: (context, snapshot) {
                  final rawRestaurants = snapshot.data ?? [];
                  final uniqueMap = <String, RestaurantModel>{};
                  for (final r in rawRestaurants) {
                    if (r.id.isNotEmpty) {
                      uniqueMap[r.id] = r;
                    }
                  }
                  final restaurants = uniqueMap.values.toList();
                  final selectedId = restaurants.any((r) => r.id == _selectedRestaurant?.id)
                      ? _selectedRestaurant?.id
                      : null;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedId,
                        hint: const Text('Choose a Restaurant', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        isExpanded: true,
                        items: restaurants.map((r) {
                          return DropdownMenuItem<String>(
                            value: r.id,
                            child: Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && uniqueMap.containsKey(val)) {
                            setState(() => _selectedRestaurant = uniqueMap[val]);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Date Selection
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDatePill('Today', DateTime.now()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDatePill('Tomorrow', DateTime.now().add(const Duration(days: 1))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDatePill('In 2 Days', DateTime.now().add(const Duration(days: 2))),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Time Slots Grid
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTimeSlot == time;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTimeSlot = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Party Size Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Party Size',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Number of dining guests',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_partySize guests',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _partySize < 12 ? () => setState(() => _partySize++) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirm Booking Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleConfirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D3B2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Reservation',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePill(String label, DateTime date) {
    final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month && _selectedDate.year == date.year;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}/${date.month}',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
