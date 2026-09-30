import 'package:flutter/material.dart';

class ModifyReservationScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(Map<String, dynamic> updatedBooking) onSave;

  const ModifyReservationScreen({
    super.key,
    required this.booking,
    required this.onSave,
  });

  @override
  State<ModifyReservationScreen> createState() =>
      _ModifyReservationScreenState();
}

class _ModifyReservationScreenState extends State<ModifyReservationScreen> {
  late String _selectedDate;
  late String _selectedTime;
  late int _guests;

  final List<String> _dateOptions = [
    'Saturday, 12 September',
    'Sunday, 13 September',
    'Tuesday, 15 September',
  ];

  final List<String> _timeOptions = [
    '7:00 PM',
    '7:30 PM',
    '8:00 PM',
    '8:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.booking['date'] ?? _dateOptions[0];
    if (!_dateOptions.contains(_selectedDate)) {
      _dateOptions.insert(0, _selectedDate);
    }
    _selectedTime = widget.booking['time'] ?? '7:30 PM';
    _guests = widget.booking['guests'] ?? 4;
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName';
  }

  Future<void> _openDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D3B2E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formatted = _formatDate(pickedDate);
      setState(() {
        if (!_dateOptions.contains(formatted)) {
          _dateOptions.add(formatted);
        }
        _selectedDate = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantName =
        widget.booking['restaurantName'] ?? 'Ocean Bistro';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modify Reservation',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Text(
                      'Edit Booking for $restaurantName',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select your updated dining preferences',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 1. Select Date Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        InkWell(
                          onTap: _openDatePicker,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: Color(0xFF0D3B2E),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Calendar',
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
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        ..._dateOptions.map((date) {
                          final isSelected = _selectedDate == date;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => setState(() => _selectedDate = date),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0FDF4)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF165B47)
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF0D3B2E)
                                            : const Color(0xFF374151),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Color(0xFF165B47),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        // Pick Another Date from Calendar tile
                        InkWell(
                          onTap: _openDatePicker,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.date_range_outlined,
                                  size: 16,
                                  color: Color(0xFF4B5563),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Choose another date from calendar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 2. Select Time Section
                    const Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _timeOptions.map((time) {
                        final isSelected = _selectedTime == time;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setState(() => _selectedTime = time),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0D3B2E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0D3B2E)
                                        : const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // 3. Guests Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Guests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: _guests > 1
                                  ? () => setState(() => _guests--)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _guests > 1
                                        ? const Color(0xFF111827)
                                        : const Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_guests',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _guests < 20
                                  ? () => setState(() => _guests++)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                child: const Text(
                                  '+',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Save Changes Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updated = Map<String, dynamic>.from(widget.booking);
                    updated['date'] = _selectedDate;
                    updated['time'] = _selectedTime;
                    updated['guests'] = _guests;
                    widget.onSave(updated);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
