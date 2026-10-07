import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/reservation_model.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/firestore_service.dart';
import '../../../services/supabase_service.dart';
import '../../../features/manager/data/models/physical_table_model.dart';
import '../../../shared/theme/app_colors.dart';

class ModifyReservationScreen extends StatefulWidget {
  final ReservationModel reservation;
  final RestaurantModel? restaurant;
  final UserProfile? profile;

  const ModifyReservationScreen({
    super.key,
    required this.reservation,
    this.restaurant,
    this.profile,
  });

  @override
  State<ModifyReservationScreen> createState() => _ModifyReservationScreenState();
}

class _ModifyReservationScreenState extends State<ModifyReservationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late String _selectedDate;
  late String _selectedTime;
  late int _partySize;
  bool _isSaving = false;

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const int _openMinutes = 11 * 60;
  static const int _closeMinutes = 23 * 60;

  // Live availability
  StreamSubscription<List<ReservationModel>>? _reservationsSub;
  StreamSubscription<List<PhysicalTable>>? _tablesSub;
  List<ReservationModel> _restaurantReservations = [];
  int _tableCapacity = 5;

  /// Real upcoming dates (today + 29 days) as label -> DateTime.
  final Map<String, DateTime> _dateMap = () {
    final today = DateTime.now();
    final map = <String, DateTime>{};
    for (int i = 0; i < 30; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      map['${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}'] = d;
    }
    return map;
  }();
  late final List<String> _dates = _dateMap.keys.toList();

  final List<String> _times = [
    '5:30 PM',
    '6:00 PM',
    '7:00 PM',
    '7:30 PM',
    '8:00 PM',
    '8:30 PM',
    '9:00 PM',
    '9:30 PM',
  ];

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.reservation.date.isNotEmpty ? widget.reservation.date : _dates.first;
    // Keep the booking's current date visible even if it is not in the upcoming window
    if (!_dates.contains(_selectedDate)) _dates.insert(0, _selectedDate);
    _selectedTime = widget.reservation.time.isNotEmpty ? widget.reservation.time : _times.first;
    _partySize = widget.reservation.partySize;

    final restaurantId = widget.reservation.restaurantId;
    _reservationsSub = SupabaseService().streamRestaurantReservations(restaurantId).listen((list) {
      if (mounted) setState(() => _restaurantReservations = list);
    });
    _tablesSub = SupabaseService().streamTables(restaurantId: restaurantId).listen((tables) {
      if (mounted && tables.isNotEmpty) setState(() => _tableCapacity = tables.length);
    });
  }

  @override
  void dispose() {
    _reservationsSub?.cancel();
    _tablesSub?.cancel();
    super.dispose();
  }

  // ---- Availability helpers (this booking itself is excluded) ----
  int _bookedCount(String date, String time) => _restaurantReservations
      .where((r) =>
          r.id != widget.reservation.id &&
          r.date == date &&
          r.time == time &&
          r.status != 'cancelled')
      .length;

  bool _isSlotFull(String date, String time) => _bookedCount(date, time) >= _tableCapacity;

  String _slotNote(String date, String time) {
    final left = _tableCapacity - _bookedCount(date, time);
    if (left <= 0) return 'Fully Booked';
    if (left == 1) return '1 slot left';
    if (left <= (_tableCapacity / 2).ceil()) return 'Almost Full';
    return 'Open';
  }

  bool _isDateFull(String date) => _times.every((t) => _isSlotFull(date, t));

  int? _minutesOf(String time) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(time.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!) % 12;
    if (m.group(3) == 'PM') h += 12;
    return h * 60 + int.parse(m.group(2)!);
  }

  String _formatTime(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$hour12:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  bool _isPast(String date, String time) {
    final d = _dateMap[date];
    final mins = _minutesOf(time);
    if (d == null || mins == null) return false;
    return DateTime(d.year, d.month, d.day, mins ~/ 60, mins % 60).isBefore(DateTime.now());
  }

  bool get _isCustomTime => !_times.contains(_selectedTime);

  Future<void> _pickCustomTime() async {
    final initialMins = _minutesOf(_selectedTime) ?? 19 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialMins ~/ 60, minute: initialMins % 60),
      helpText: 'SELECT DINING TIME',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: const Color(0xFF0D3B2E)),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final mins = picked.hour * 60 + picked.minute;
    final formatted = _formatTime(picked);
    String? error;
    if (mins < _openMinutes || mins > _closeMinutes) {
      error = 'We are open 11:00 AM – 11:00 PM. Please pick a time in that range.';
    } else if (_isPast(_selectedDate, formatted)) {
      error = 'That time has already passed. Please pick a later time.';
    } else if (_isSlotFull(_selectedDate, formatted)) {
      error = '$formatted is fully booked. Please choose another time.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }
    setState(() => _selectedTime = formatted);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initialDate = _dateMap[_selectedDate] ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'SELECT DINING DATE',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: const Color(0xFF0D3B2E),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final dateStr = '${_dayNames[picked.weekday - 1]}, ${picked.day} ${_monthNames[picked.month - 1]}';
    _dateMap[dateStr] = picked;
    if (!_dates.contains(dateStr)) {
      _dates.insert(0, dateStr);
    }
    setState(() => _selectedDate = dateStr);
  }

  Future<void> _handleSaveChanges() async {
    if (_isSlotFull(_selectedDate, _selectedTime) || _isPast(_selectedDate, _selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That slot is no longer available. Please choose another date or time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final updated = widget.reservation.copyWith(
      date: _selectedDate,
      time: _selectedTime,
      partySize: _partySize,
    );

    try {
      await _firestoreService.updateReservation(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Modify Reservation',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Booking for ${widget.reservation.restaurantName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Select your updated dining preferences.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),

                    // Select Date Header + Calendar Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Date',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        InkWell(
                          onTap: _pickCustomDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D3B2E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF0D3B2E)),
                                SizedBox(width: 5),
                                Text(
                                  'Calendar Picker',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D3B2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Dates List (Top 5 + Currently Selected)
                    ..._dates.take(6).map((date) {
                      final isSelected = _selectedDate == date;
                      final isFull = _isDateFull(date) && !isSelected;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: isFull ? null : () => setState(() => _selectedDate = date),
                          child: Opacity(
                            opacity: isFull ? 0.5 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF0D3B2E) : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                                  else if (isFull)
                                    const Text('Fully Booked', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600))
                                  else
                                    const Text('Available', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Prominent Calendar Picker Card
                    GestureDetector(
                      onTap: _pickCustomDate,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0D3B2E).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF0D3B2E)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Choose another date from calendar...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D3B2E),
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Color(0xFF0D3B2E)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select Time
                    const Text(
                      'Select Time',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _times.map((time) {
                        final isFull = _isSlotFull(_selectedDate, time) || _isPast(_selectedDate, time);
                        final isSelected = _selectedTime == time && !isFull;
                        final note = _isPast(_selectedDate, time) ? 'Passed' : _slotNote(_selectedDate, time);
                        return GestureDetector(
                          onTap: isFull ? null : () => setState(() => _selectedTime = time),
                          child: Opacity(
                            opacity: isFull ? 0.45 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    isSelected ? 'Selected' : note,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected ? Colors.white70 : (isFull ? Colors.red : AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickCustomTime,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _isCustomTime ? const Color(0xFF0D3B2E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCustomTime ? const Color(0xFF0D3B2E) : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 20, color: _isCustomTime ? Colors.white : const Color(0xFF0D3B2E)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isCustomTime ? 'Custom time: $_selectedTime' : 'Pick a custom time (11 AM – 11 PM)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _isCustomTime ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: _isCustomTime ? Colors.white70 : AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Guests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Guests',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                  '$_partySize',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  ],
                ),
              ),
            ),

            // Bottom Save Changes Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
