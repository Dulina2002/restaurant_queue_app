import 'package:flutter/material.dart';
import 'modify_reservation_screen.dart';
import 'cancel_reservation_dialog.dart';

class CustomerBookingsView extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const CustomerBookingsView({
    super.key,
    this.onExploreTap,
  });

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView> {
  int _selectedTabIndex = 0; // 0: Upcoming, 1: Past, 2: Cancelled

  final List<String> _tabs = ['Upcoming', 'Past', 'Cancelled'];

  // Mock list of upcoming bookings
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': 'RSV10245',
      'restaurantName': 'Ocean Bistro',
      'date': 'Saturday, 12 September',
      'time': '7:30 PM',
      'guests': 4,
      'status': 'Confirmed',
    },
  ];

  // Mock list of past bookings
  final List<Map<String, dynamic>> _pastBookings = [
    {
      'id': 'RSV09812',
      'restaurantName': 'The Mango Tree',
      'date': 'Friday, 28 August',
      'time': '8:00 PM',
      'guests': 2,
      'status': 'Completed',
    },
    {
      'id': 'RSV09450',
      'restaurantName': 'Ministry of Crab',
      'date': 'Sunday, 15 August',
      'time': '1:30 PM',
      'guests': 5,
      'status': 'Completed',
    },
  ];

  // Mock list of cancelled bookings
  final List<Map<String, dynamic>> _cancelledBookings = [
    {
      'id': 'RSV08990',
      'restaurantName': 'Nihonbashi',
      'date': 'Wednesday, 5 August',
      'time': '6:30 PM',
      'guests': 2,
      'status': 'Cancelled',
    },
  ];

  void _showModifyDialog(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyReservationScreen(
          booking: booking,
          onSave: (updatedBooking) {
            setState(() {
              final index = _upcomingBookings
                  .indexWhere((b) => b['id'] == booking['id']);
              if (index != -1) {
                _upcomingBookings[index] = updatedBooking;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Reservation updated successfully!'),
                  ],
                ),
                backgroundColor: Color(0xFF0D3B2E),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => CancelReservationDialog(
        booking: booking,
        onConfirmCancel: () {
          setState(() {
            _upcomingBookings.remove(booking);
            final cancelledItem = Map<String, dynamic>.from(booking);
            cancelledItem['status'] = 'Cancelled';
            _cancelledBookings.insert(0, cancelledItem);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reservation #${booking['id']} cancelled.'),
              backgroundColor: const Color(0xFFDC4437),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: const Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Segmented Tabs: Upcoming / Past / Cancelled
          _buildTabBar(),

          const SizedBox(height: 12),

          // Bookings List Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF111827)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  // Active Underline Indicator
                  Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF112518)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildBookingsList(
          bookings: _upcomingBookings,
          isUpcoming: true,
          emptyMessage: 'No upcoming bookings found.',
          emptySubMessage: 'Explore top restaurants and reserve your table now.',
        );
      case 1:
        return _buildBookingsList(
          bookings: _pastBookings,
          isUpcoming: false,
          emptyMessage: 'No past bookings yet.',
          emptySubMessage: 'Your completed dining experiences will appear here.',
        );
      case 2:
        return _buildBookingsList(
          bookings: _cancelledBookings,
          isUpcoming: false,
          emptyMessage: 'No cancelled bookings.',
          emptySubMessage: 'Any cancelled reservations will be archived here.',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBookingsList({
    required List<Map<String, dynamic>> bookings,
    required bool isUpcoming,
    required String emptyMessage,
    required String emptySubMessage,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 32,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              if (widget.onExploreTap != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: widget.onExploreTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Explore Restaurants'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, isUpcoming);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isUpcoming) {
    final status = booking['status'] as String;
    final isConfirmed = status == 'Confirmed';
    final isCancelled = status == 'Cancelled';

    Color statusColor;
    IconData statusIcon;

    if (isConfirmed) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
    } else if (isCancelled) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel;
    } else {
      statusColor = const Color(0xFF6B7280);
      statusIcon = Icons.task_alt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Restaurant Name + Booking ID & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['restaurantName'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Booking #${booking['id']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Details Row: Date • Time • Guests
          Row(
            children: [
              // Date
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    booking['date'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    booking['time'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Guests
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 15,
                    color: Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${booking['guests']} Guests',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (isUpcoming) ...[
            const SizedBox(height: 18),

            // Action Buttons: Modify & Cancel
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showModifyDialog(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F2937),
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Modify',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                        color: Color(0xFFFCA5A5),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isCancelled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _cancelledBookings.remove(booking);
                    final rebooked = Map<String, dynamic>.from(booking);
                    rebooked['status'] = 'Confirmed';
                    _upcomingBookings.insert(0, rebooked);
                    _selectedTabIndex = 0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Re-booking confirmed!'),
                      backgroundColor: Color(0xFF0D3B2E),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D3B2E),
                  side: const BorderSide(
                    color: Color(0xFF0D3B2E),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Re-Book Table',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Rate & Review',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        final rebooked = Map<String, dynamic>.from(booking);
                        rebooked['status'] = 'Confirmed';
                        rebooked['date'] = 'Saturday, 19 September';
                        _upcomingBookings.insert(0, rebooked);
                        _selectedTabIndex = 0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Table re-booked for Saturday, 19 September!'),
                          backgroundColor: Color(0xFF0D3B2E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D3B2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book Again',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
