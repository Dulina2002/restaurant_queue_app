import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/supabase_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const CreateBookingScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _dateOffsetDays = 0;

  // Form State
  DateTime? _selectedDate;
  String? _selectedTime;
  int _guests = 2;
  final TextEditingController _specialRequestController = TextEditingController();

  final List<String> _timeOptions = [
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
    '1:00 PM', '1:30 PM', '2:00 PM', '2:30 PM',
    '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', 
    '8:00 PM', '8:30 PM', '9:00 PM', '9:30 PM', '10:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    // Default to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _confirmBooking() {
    // Parse time
    final dateParts = _selectedTime!.split(' ');
    final timeParts = dateParts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = dateParts[1].toLowerCase() == 'pm';

    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    final bookingDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );

    Navigator.pop(context, {
      'date': bookingDate,
      'party_size': _guests,
      'restaurant_id': widget.restaurant['id'],
      'special_request': _specialRequestController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: _previousStep,
        ),
        title: const Text(
          'Reserve a Table',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Header
            _buildStepper(),
            
            const Divider(color: Color(0xFFE5E7EB), height: 1),

            // Page Content
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService().listenToRestaurantBookings(widget.restaurant['id']),
                builder: (context, snapshot) {
                  final bookings = snapshot.data ?? [];
                  return PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildDateSelection(bookings),
                      _buildTimeSelection(bookings),
                      _buildGuestSelection(),
                      _buildReviewSelection(),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepper() {
    final steps = ['Date', 'Time', 'Guests', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive || isCompleted
                              ? const Color(0xFF0D3B2E)
                              : Colors.white,
                          border: Border.all(
                            color: isActive || isCompleted
                                ? const Color(0xFF0D3B2E)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF111827)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? const Color(0xFF0D3B2E) : const Color(0xFFE5E7EB),
                      margin: const EdgeInsets.only(bottom: 24),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // STEP 1: DATE
  // ==========================================
  Widget _buildDateSelection(List<Map<String, dynamic>> bookings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Reservation Date',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select an available dining day for your visit.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getFormattedMonth(DateTime.now().add(Duration(days: _dateOffsetDays))),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_dateOffsetDays > 0) {
                        setState(() {
                          _dateOffsetDays = (_dateOffsetDays - 7).clamp(0, 365);
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.chevron_left,
                        color: _dateOffsetDays > 0 ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dateOffsetDays += 7;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // Generate 7 days ahead
          ...List.generate(7, (index) {
            final date = DateTime.now().add(Duration(days: index + _dateOffsetDays));
            final isSelected = _selectedDate?.day == date.day && _selectedDate?.month == date.month;
            // Check if day is fully booked
            bool isFullyBooked = true;
            for (String time in _timeOptions) {
              final dateParts = time.split(' ');
              final timeParts = dateParts[0].split(':');
              int hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final isPm = dateParts[1].toLowerCase() == 'pm';

              if (isPm && hour != 12) hour += 12;
              if (!isPm && hour == 12) hour = 0;

              final slotDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                hour,
                minute,
              );

              int totalGuests = 0;
              for (var booking in bookings) {
                final bDate = DateTime.parse(booking['booking_date']).toLocal();
                if (bDate.year == slotDateTime.year &&
                    bDate.month == slotDateTime.month &&
                    bDate.day == slotDateTime.day &&
                    bDate.hour == slotDateTime.hour &&
                    bDate.minute == slotDateTime.minute) {
                  totalGuests += (booking['party_size'] as int? ?? 0);
                }
              }
              
              if (totalGuests + _guests <= 10) {
                isFullyBooked = false; // Found at least one available slot
                break;
              }
            }

            return GestureDetector(
              onTap: () {
                if (!isFullyBooked) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDateDetailed(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF111827),
                        decoration: isFullyBooked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isFullyBooked ? 'Fully Booked' : (isSelected ? 'Selected' : 'Available'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isFullyBooked ? const Color(0xFFDC2626) : const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: TIME
  // ==========================================
  Widget _buildTimeSelection(List<Map<String, dynamic>> bookings) {
    // If no time is selected, default to 7:00 PM for the picker
    DateTime initialTime = DateTime.now();
    if (_selectedTime != null) {
      final dateParts = _selectedTime!.split(' ');
      final timeParts = dateParts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = dateParts[1].toLowerCase() == 'pm';

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      initialTime = DateTime(initialTime.year, initialTime.month, initialTime.day, hour, minute);
    } else {
      initialTime = DateTime(initialTime.year, initialTime.month, initialTime.day, 19, 0); // 7:00 PM
    }

    // Check availability for currently selected time
    bool isUnavailable = false;
    if (_selectedDate != null && _selectedTime != null) {
      final slotDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        initialTime.hour,
        initialTime.minute,
      );

      int totalGuests = 0;
      for (var booking in bookings) {
        final bDate = DateTime.parse(booking['booking_date']).toLocal();
        if (bDate.year == slotDateTime.year &&
            bDate.month == slotDateTime.month &&
            bDate.day == slotDateTime.day &&
            bDate.hour == slotDateTime.hour &&
            bDate.minute == slotDateTime.minute) {
          totalGuests += (booking['party_size'] as int? ?? 0);
        }
      }
      if (totalGuests + _guests > 10) {
        isUnavailable = true;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Dining Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your preferred time. (AM/PM)',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),
          
          Center(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 15,
                  initialDateTime: initialTime,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      int h = newTime.hour;
                      int m = newTime.minute;
                      String ampm = h >= 12 ? 'PM' : 'AM';
                      if (h > 12) h -= 12;
                      if (h == 0) h = 12;
                      String minuteStr = m.toString().padLeft(2, '0');
                      _selectedTime = '$h:$minuteStr $ampm';
                    });
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          if (_selectedTime != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnavailable ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnavailable ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isUnavailable ? Icons.error_outline : Icons.check_circle_outline,
                    color: isUnavailable ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isUnavailable 
                          ? '$_selectedTime is currently fully booked. Please select another time.'
                          : '$_selectedTime is available for your party of $_guests.',
                      style: TextStyle(
                        color: isUnavailable ? const Color(0xFF991B1B) : const Color(0xFF166534),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: GUESTS
  // ==========================================
  Widget _buildGuestSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many guests?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select party size for your table reservation.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),
          
          // Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGuestButton(
                icon: Icons.remove,
                onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
              ),
              Container(
                width: 100,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      '$_guests',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'Guests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _buildGuestButton(
                icon: Icons.add,
                onPressed: _guests < 20 ? () => setState(() => _guests++) : null,
                isPrimary: true,
              ),
            ],
          ),
          
          const SizedBox(height: 50),
          
          // Quick Select
          const Text(
            'Quick Select',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [2, 4, 5, 8].map((numValue) {
              final isSelected = _guests == numValue;
              return GestureDetector(
                onTap: () => setState(() => _guests = numValue),
                child: Container(
                  width: 60,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$numValue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recommended: Table for $_guests',
                    style: const TextStyle(
                      color: Color(0xFFC2410C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4: REVIEW
  // ==========================================
  Widget _buildReviewSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Reservation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please verify your reservation details.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant['name'] ?? 'Restaurant',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '42 Marine Drive, Colombo 03, Sri Lanka',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFE5E7EB), height: 1),
                ),
                _buildReviewDetailRow(Icons.calendar_today, 'Date', _formatDateDetailed(_selectedDate ?? DateTime.now())),
                const SizedBox(height: 12),
                _buildReviewDetailRow(Icons.access_time, 'Time', _selectedTime ?? ''),
                const SizedBox(height: 12),
                _buildReviewDetailRow(Icons.people_alt_outlined, 'Party Size', '$_guests Guests'),
                const SizedBox(height: 12),
                _buildReviewDetailRow(Icons.table_restaurant, 'Selected Table', 'Table for $_guests'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Add a special request (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Window seat', 'Birthday celebration', 'Quiet table'].map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _specialRequestController,
            decoration: InputDecoration(
              hintText: 'E.g., High chair needed, anniversary flower request...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 2,
          ),
          
        ],
      ),
    );
  }

  Widget _buildReviewDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton({required IconData icon, required VoidCallback? onPressed, bool isPrimary = false}) {
    return Material(
      color: onPressed == null
          ? const Color(0xFFF9FAFB)
          : (isPrimary ? const Color(0xFFE8F5E9) : Colors.white),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onPressed == null
                  ? const Color(0xFFE5E7EB)
                  : (isPrimary ? const Color(0xFF0D3B2E).withValues(alpha: 0.3) : const Color(0xFFD1D5DB)),
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: onPressed == null
                ? const Color(0xFFD1D5DB)
                : (isPrimary ? const Color(0xFF0D3B2E) : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM BAR
  // ==========================================
  Widget _buildBottomBar() {
    String buttonText = 'Continue to Time';
    if (_currentStep == 1) buttonText = 'Continue to Guests';
    if (_currentStep == 2) buttonText = 'Continue to Review';
    if (_currentStep == 3) buttonText = 'Confirm Reservation  →';

    bool isEnabled = true;
    if (_currentStep == 0 && _selectedDate == null) isEnabled = false;
    if (_currentStep == 1) {
      // Must have selected time and it must be available
      if (_selectedTime == null) isEnabled = false;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF3F4F6), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isEnabled ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == 3 ? const Color(0xFFEA580C) : const Color(0xFF0D3B2E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDateDetailed(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }
}
