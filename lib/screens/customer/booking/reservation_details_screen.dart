import 'package:flutter/material.dart';
import '../../../models/reservation_model.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/restaurant_database_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/restaurant_image.dart';
import 'modify_reservation_screen.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final ReservationModel reservation;
  final RestaurantModel? restaurant;
  final UserProfile? profile;

  const ReservationDetailsScreen({
    super.key,
    required this.reservation,
    this.restaurant,
    this.profile,
  });

  @override
  State<ReservationDetailsScreen> createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();
  late ReservationModel _currentReservation;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _currentReservation = widget.reservation;
  }

  void _confirmCancel() {
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
          'Are you sure you want to cancel your table at ${_currentReservation.restaurantName} for ${_currentReservation.date} at ${_currentReservation.time}?',
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
              setState(() => _isCancelling = true);
              try {
                await _firestoreService.cancelReservation(_currentReservation.id);
                if (!mounted) return;
                setState(() {
                  _currentReservation = _currentReservation.copyWith(status: 'cancelled');
                  _isCancelling = false;
                });
                AppToast.show(
                  context,
                  title: 'Reservation Cancelled',
                  message: 'Your booking ${_currentReservation.reservationCode} at ${_currentReservation.restaurantName} was cancelled.',
                  type: ToastType.error,
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isCancelling = false);
                AppToast.showError(
                  context,
                  'Failed to cancel: $e',
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

  @override
  Widget build(BuildContext context) {
    final isConfirmed = _currentReservation.status.toLowerCase() == 'confirmed';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reservation Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Restaurant Header Card with Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RestaurantImage(
                              imageUrl: widget.restaurant?.imageUrl,
                              restaurantName: widget.restaurant?.name,
                              cuisine: widget.restaurant?.cuisine,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              bottom: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.restaurant?.tag ?? 'Italian • Seafood',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Booking Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          // Restaurant Name & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentReservation.restaurantName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reservation ID ${_currentReservation.reservationCode}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isConfirmed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 12,
                                      color: isConfirmed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentReservation.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isConfirmed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 18),

                          _buildDetailRow('Date & Time', '${_currentReservation.date} • ${_currentReservation.time}'),
                          const SizedBox(height: 14),
                          _buildDetailRow('Guests', '${_currentReservation.partySize} Guests'),
                          const SizedBox(height: 14),
                          _buildDetailRow('Assigned Table', 'Table 04 (Indoor Window)'),
                          const SizedBox(height: 14),
                          _buildDetailRow('Guest Name', _currentReservation.guestName),
                          if (_currentReservation.specialNotes != null && _currentReservation.specialNotes!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildDetailRow('Special Notes', _currentReservation.specialNotes!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Action Buttons
            if (isConfirmed) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final updated = await Navigator.push<ReservationModel>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModifyReservationScreen(
                                reservation: _currentReservation,
                                restaurant: widget.restaurant,
                                profile: widget.profile,
                              ),
                            ),
                          );
                          if (updated != null) {
                            setState(() => _currentReservation = updated);
                          }
                        },
                        icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                        label: const Text(
                          'Modify Reservation',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D3B2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _isCancelling ? null : _confirmCancel,
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                      label: _isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2),
                            )
                          : const Text(
                              'Cancel Reservation',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
