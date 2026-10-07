import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/reservation_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/firestore_service.dart';
import '../../../services/supabase_service.dart';
import '../../../features/manager/data/models/physical_table_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../features/manager/data/models/live_menu_dish_model.dart';
import 'booking_confirmation_screen.dart';

class ReserveTableStepperScreen extends StatefulWidget {
  final RestaurantModel restaurant;
  final UserProfile? profile;

  const ReserveTableStepperScreen({
    super.key,
    required this.restaurant,
    this.profile,
  });

  @override
  State<ReserveTableStepperScreen> createState() => _ReserveTableStepperScreenState();
}

class _ReserveTableStepperScreenState extends State<ReserveTableStepperScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentStep = 0; // 0: Date, 1: Time, 2: Guests, 3: Confirm

  // Step 1: Date
  int _selectedDateIndex = 0;
  late DateTime _displayMonth;

  // Live availability data
  StreamSubscription<List<ReservationModel>>? _reservationsSub;
  StreamSubscription<List<PhysicalTable>>? _tablesSub;
  List<ReservationModel> _restaurantReservations = [];
  int _tableCapacity = 5; // max concurrent bookings per time slot

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _reservationsSub = SupabaseService()
        .streamRestaurantReservations(widget.restaurant.id)
        .listen((list) {
      if (mounted) setState(() => _restaurantReservations = list);
    });
    _tablesSub = SupabaseService()
        .streamTables(restaurantId: widget.restaurant.id)
        .listen((tables) {
      if (mounted && tables.isNotEmpty) setState(() => _tableCapacity = tables.length);
    });
  }

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  int _bookedCount(String dateStr, String time) => _restaurantReservations
      .where((r) => r.date == dateStr && r.time == time && r.status != 'cancelled')
      .length;

  bool _isSlotFull(String dateStr, String time) => _bookedCount(dateStr, time) >= _tableCapacity;

  String _slotNote(String dateStr, String time) {
    final left = _tableCapacity - _bookedCount(dateStr, time);
    if (left <= 0) return 'Fully Booked';
    if (left == 1) return '1 slot left';
    if (left <= (_tableCapacity / 2).ceil()) return 'Almost Full';
    return 'Open';
  }

  /// Dates from today (or the 1st for future months) to the end of the displayed month.
  List<Map<String, dynamic>> get _dateSlots {
    final today = DateTime.now();
    final month = _displayMonth;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == today.year && month.month == today.month;
    final startDay = isCurrentMonth ? today.day : 1;

    final List<Map<String, dynamic>> slots = [];
    for (int day = startDay; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateStr = '${_dayNames[date.weekday - 1]}, $day ${_monthNames[date.month - 1]}';
      final fullyBooked = _timeSlots.every((t) => _isSlotFull(dateStr, t['time']!));
      slots.add({
        'date': dateStr,
        'dt': date,
        'status': fullyBooked ? 'Fully Booked' : 'Available',
      });
    }
    return slots;
  }

  // ---- Time helpers & custom time picker ----
  static const int _openMinutes = 11 * 60; // 11:00 AM
  static const int _closeMinutes = 23 * 60; // 11:00 PM

  String _formatTime(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  int? _minutesOf(String time) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(time.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!) % 12;
    if (m.group(3) == 'PM') h += 12;
    return h * 60 + int.parse(m.group(2)!);
  }

  DateTime? get _selectedDateTime {
    final slots = _dateSlots;
    if (slots.isEmpty) return null;
    return slots[_selectedDateIndex.clamp(0, slots.length - 1)]['dt'] as DateTime;
  }

  bool _isPast(String time) {
    final date = _selectedDateTime;
    final mins = _minutesOf(time);
    if (date == null || mins == null) return false;
    final slot = DateTime(date.year, date.month, date.day, mins ~/ 60, mins % 60);
    return slot.isBefore(DateTime.now());
  }

  bool get _isCustomTime => !_timeSlots.any((t) => t['time'] == _selectedTime);

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
    } else if (_isPast(formatted)) {
      error = 'That time has already passed. Please pick a later time.';
    } else if (_isSlotFull(_selectedDateTime == null ? '' : _dateSlots[_selectedDateIndex.clamp(0, _dateSlots.length - 1)]['date'] as String, formatted)) {
      error = '$formatted is fully booked. Please choose another time.';
    }

    if (error != null) {
      AppToast.showError(context, error);
      return;
    }
    setState(() => _selectedTime = formatted);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'SELECT RESERVATION DATE',
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

    setState(() {
      _displayMonth = DateTime(picked.year, picked.month);
      final slots = _dateSlots;
      final idx = slots.indexWhere((s) {
        final dt = s['dt'] as DateTime?;
        return dt != null && dt.year == picked.year && dt.month == picked.month && dt.day == picked.day;
      });
      _selectedDateIndex = idx >= 0 ? idx : 0;
    });
  }

  bool get _canGoPrevious {
    final now = DateTime.now();
    return _displayMonth.isAfter(DateTime(now.year, now.month));
  }

  void _previousMonth() {
    if (!_canGoPrevious) return;
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      _selectedDateIndex = 0;
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
      _selectedDateIndex = 0;
    });
  }

  String _getMonthName(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  // Step 2: Time
  String _selectedTime = '7:30 PM';
  final List<Map<String, String>> _timeSlots = [
    {'time': '5:30 PM'},
    {'time': '6:00 PM'},
    {'time': '7:00 PM'},
    {'time': '7:30 PM'},
    {'time': '8:00 PM'},
    {'time': '8:30 PM'},
    {'time': '9:00 PM'},
    {'time': '9:30 PM'},
  ];

  // Step 3: Guests
  int _partySize = 4;

  // Step 4: Special Requests & Pre-orders
  final Set<String> _selectedSpecialRequests = {'Window seat'};
  final TextEditingController _specialNotesController = TextEditingController();
  final Set<String> _preorderedDishes = {};
  bool _isSubmitting = false;

  final List<String> _quickSpecialRequests = [
    'Window seat',
    'Birthday celebration',
    'Quiet table',
    'Accessibility assistance',
    'High chair needed',
  ];

  @override
  void dispose() {
    _reservationsSub?.cancel();
    _tablesSub?.cancel();
    _specialNotesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleConfirmReservation() async {
    final selectedDateStr = _dateSlots[_selectedDateIndex]['date'] as String;
    if (_isSlotFull(selectedDateStr, _selectedTime) || _isPast(_selectedTime)) {
      AppToast.showError(
        context,
        'Sorry, that time slot was just booked. Please choose another time.',
      );
      setState(() => _currentStep = 1);
      return;
    }
    setState(() => _isSubmitting = true);

    final notesList = <String>[];
    if (_selectedSpecialRequests.isNotEmpty) {
      notesList.add('Requests: ${_selectedSpecialRequests.join(", ")}');
    }
    if (_specialNotesController.text.trim().isNotEmpty) {
      notesList.add('Note: ${_specialNotesController.text.trim()}');
    }
    if (_preorderedDishes.isNotEmpty) {
      notesList.add('Pre-orders: ${_preorderedDishes.join(", ")}');
    }
    final combinedNotes = notesList.isNotEmpty ? notesList.join(" • ") : null;

    try {
      final reservation = await _firestoreService.createReservation(
        ReservationModel(
          id: '',
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          userId: (widget.profile?.id.isNotEmpty == true) ? widget.profile!.id : 'guest_id',
          guestName: (widget.profile?.fullName.isNotEmpty == true) ? widget.profile!.fullName : 'Guest',
          reservationCode: '',
          date: selectedDateStr,
          time: _selectedTime,
          partySize: _partySize,
          status: 'confirmed',
          specialNotes: combinedNotes,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            reservation: reservation,
            restaurant: widget.restaurant,
            profile: widget.profile,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(
        context,
        'Failed to confirm reservation: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Header with Step Progress Indicator ---
            _buildTopAppBar(),

            // --- Stepper Indicator ---
            _buildStepIndicator(),

            // --- Step Body Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepContent(),
              ),
            ),

            // --- Fixed Bottom Action Button ---
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _previousStep,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reserve a Table',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.restaurant.name,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Date', 'Time', 'Guests', 'Confirm'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : (isCurrent ? const Color(0xFFF27B50) : AppColors.surface),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : (isCurrent ? const Color(0xFFF27B50) : AppColors.border),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFFF27B50)
                          : (isCompleted ? AppColors.textPrimary : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              if (index < steps.length - 1)
                Container(
                  width: MediaQuery.of(context).size.width * 0.12,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                  color: isCompleted ? const Color(0xFF10B981) : AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDateStep();
      case 1:
        return _buildTimeStep();
      case 2:
        return _buildGuestsStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // --- STEP 1: SELECT RESERVATION DATE ---
  // ==========================================
  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Reservation Date',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select an available dining day for your visit.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),

        // Month Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _pickCustomDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF0D3B2E)),
                      const SizedBox(width: 6),
                      Text(
                        _getMonthName(_displayMonth),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.primary),
                    onPressed: _previousMonth,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.primary),
                    onPressed: _nextMonth,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Dates List
        ...List.generate(_dateSlots.length, (index) {
          final slot = _dateSlots[index];
          final isSelected = _selectedDateIndex == index;
          final isFullyBooked = slot['status'] == 'Fully Booked';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: isFullyBooked ? null : () => setState(() => _selectedDateIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0D3B2E)
                      : (isFullyBooked ? const Color(0xFFF9FAFB) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0D3B2E)
                        : (isFullyBooked ? const Color(0xFFE5E7EB) : AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : (isFullyBooked ? const Color(0xFF9CA3AF) : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          slot['date'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isFullyBooked ? const Color(0xFF9CA3AF) : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isFullyBooked ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSelected ? 'Selected' : slot['status'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isFullyBooked ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // --- STEP 2: SELECT DINING TIME ---
  // ==========================================
  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Dining Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose your preferred seating slot.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final dateStr = _dateSlots.isNotEmpty
                ? _dateSlots[_selectedDateIndex.clamp(0, _dateSlots.length - 1)]['date'] as String
                : '';
            final isFull = _isSlotFull(dateStr, slot['time']!) || _isPast(slot['time']!);
            final isSelected = _selectedTime == slot['time'] && !isFull;
            final note = _isPast(slot['time']!) ? 'Passed' : _slotNote(dateStr, slot['time']!);

            return GestureDetector(
              onTap: isFull ? null : () => setState(() => _selectedTime = slot['time']!),
              child: Opacity(
                opacity: isFull ? 0.45 : 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot['time']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected ? 'Selected' : note,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white70 : (isFull ? Colors.red : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // --- Custom time picker ---
        GestureDetector(
          onTap: _pickCustomTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _isCustomTime ? const Color(0xFF0D3B2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isCustomTime ? const Color(0xFF0D3B2E) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: _isCustomTime ? Colors.white : const Color(0xFF0D3B2E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCustomTime ? 'Custom time: $_selectedTime' : 'Pick a custom time',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isCustomTime ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Open daily 11:00 AM – 11:00 PM',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isCustomTime ? Colors.white70 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _isCustomTime ? Colors.white70 : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // --- STEP 3: HOW MANY GUESTS? ---
  // ==========================================
  Widget _buildGuestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How many guests?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select party size for your table reservation.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),

        // Big Stepper Counter
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 36, color: AppColors.textMuted),
                  onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                ),
                const SizedBox(width: 28),
                Column(
                  children: [
                    Text(
                      '$_partySize',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Guests',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 28),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 36, color: Color(0xFF10B981)),
                  onPressed: _partySize < 12 ? () => setState(() => _partySize++) : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Quick Select Pills
        const Text(
          'Quick Select',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [2, 4, 6, 8].map((count) {
            final isSelected = _partySize == count;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _partySize = count),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Recommendation Pill Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE8B2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD9531E), size: 22),
              const SizedBox(width: 12),
              Text(
                'Recommended: Table for $_partySize',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD9531E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // --- STEP 4: REVIEW RESERVATION ---
  // ==========================================
  Widget _buildReviewStep() {
    final selectedDateStr = _dateSlots[_selectedDateIndex]['date'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Reservation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please confirm your dining details.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),

        // Restaurant & Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.restaurant.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                widget.restaurant.location.isNotEmpty ? widget.restaurant.location : '42 Marine Drive, Colombo 03, Sri Lanka',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),

              _buildReviewRow(Icons.calendar_today_outlined, 'Date', selectedDateStr),
              const SizedBox(height: 12),
              _buildReviewRow(Icons.access_time_rounded, 'Time', _selectedTime),
              const SizedBox(height: 12),
              _buildReviewRow(Icons.people_outline_rounded, 'Party Size', '$_partySize Guests'),
              const SizedBox(height: 12),
              _buildReviewRow(Icons.table_restaurant_outlined, 'Selected Table', 'Table for $_partySize'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Special Requests
        const Text(
          'Add a special request (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSpecialRequests.map((req) {
            final isSelected = _selectedSpecialRequests.contains(req);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSpecialRequests.remove(req);
                  } else {
                    _selectedSpecialRequests.add(req);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                  ),
                ),
                child: Text(
                  req,
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
        const SizedBox(height: 12),

        TextField(
          controller: _specialNotesController,
          decoration: InputDecoration(
            hintText: 'e.g., High chair needed, anniversary celebration...',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Pre-order Dishes (Live Menu)
        const Text(
          'Pre-order Dishes (Live Menu)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select dishes to be prepared ahead for your table.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),

        StreamBuilder<List<LiveMenuDish>>(
          stream: FirestoreService().streamLiveMenu(restaurantId: widget.restaurant.id),
          builder: (context, snapshot) {
            final dishes = (snapshot.data ?? [])
                .where((d) => d.isAvailable)
                .toList();

            if (dishes.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Grilled Calamari & Aioli',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text('Rs. 1,850 • Starters', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          if (_preorderedDishes.contains('Grilled Calamari')) {
                            _preorderedDishes.remove('Grilled Calamari');
                          } else {
                            _preorderedDishes.add('Grilled Calamari');
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _preorderedDishes.contains('Grilled Calamari')
                              ? const Color(0xFF10B981)
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _preorderedDishes.contains('Grilled Calamari') ? '✓ Added' : '+ Pre-order',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _preorderedDishes.contains('Grilled Calamari')
                              ? const Color(0xFF10B981)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: dishes.map((dish) {
                final isAdded = _preorderedDishes.contains(dish.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAdded ? const Color(0xFF10B981) : AppColors.border,
                        width: isAdded ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dish.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rs. ${dish.price.toInt()} • ${dish.category}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              if (isAdded) {
                                _preorderedDishes.remove(dish.name);
                              } else {
                                _preorderedDishes.add(dish.name);
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isAdded ? const Color(0xFF10B981) : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isAdded ? '✓ Added' : '+ Pre-order',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAdded ? const Color(0xFF10B981) : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 3;
    final buttonLabel = _currentStep == 0
        ? 'Continue to Time'
        : (_currentStep == 1
            ? 'Continue to Guests'
            : (_currentStep == 2 ? 'Continue to Review' : 'Confirm Reservation'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : (isLastStep ? _handleConfirmReservation : _nextStep),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLastStep ? const Color(0xFFF27B50) : const Color(0xFF0D3B2E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    if (isLastStep) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
