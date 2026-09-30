import 'package:flutter/material.dart';

class CancelReservationDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onConfirmCancel;

  const CancelReservationDialog({
    super.key,
    required this.booking,
    required this.onConfirmCancel,
  });

  @override
  State<CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<CancelReservationDialog> {
  String _selectedReason = 'Change of plans';

  final List<String> _reasons = [
    'Change of plans',
    'Found another restaurant',
    'Time no longer suitable',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Cancel Reservation?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Are you sure you want to cancel this reservation? This cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Reason Prompt
            const Text(
              'Please select a reason:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),

            // Radio Options
            Column(
              children: _reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = reason),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Custom Coral/Red Radio Icon
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFDC4437)
                                  : const Color(0xFF9CA3AF),
                              width: 1.8,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFDC4437),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Primary Cancel Button (Coral/Red)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onConfirmCancel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC4437),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel Reservation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Keep Reservation Button
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Keep Reservation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D3B2E),
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
