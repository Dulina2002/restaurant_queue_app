import 'package:flutter/material.dart';
import '../../data/models/floor_table_model.dart';

class TableStatusDialog extends StatelessWidget {
  final FloorTable table;
  final ValueChanged<FloorTableStatus> onStatusChanged;

  const TableStatusDialog({
    super.key,
    required this.table,
    required this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required FloorTable table,
    required ValueChanged<FloorTableStatus> onStatusChanged,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => TableStatusDialog(
        table: table,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  String _getStatusLabel(FloorTableStatus status) {
    switch (status) {
      case FloorTableStatus.available:
        return 'Available';
      case FloorTableStatus.reserved:
        return 'Reserved';
      case FloorTableStatus.occupied:
        return 'Occupied';
      case FloorTableStatus.disabled:
        return 'Disabled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusLabel(table.status);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: Table 02 (4 Seats)
            Text(
              '${table.name} (${table.seats} Seats)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),

            // Current Status row
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                children: [
                  const TextSpan(text: 'Current Status: '),
                  TextSpan(
                    text: statusText,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Seated guest row
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                children: [
                  const TextSpan(text: 'Seated: '),
                  TextSpan(
                    text: table.guestName.isNotEmpty
                        ? table.guestName
                        : (table.status == FloorTableStatus.available
                            ? 'None (Vacant)'
                            : 'No Guest'),
                    style: TextStyle(
                      color: table.guestName.isNotEmpty
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                      fontWeight: table.guestName.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            const Text(
              'Update Seating Status:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Mark as Available (Vacant)
            _buildStatusButton(
              context: context,
              label: 'Mark as Available (Vacant)',
              backgroundColor: const Color(0xFF2E9B60),
              status: FloorTableStatus.available,
            ),
            const SizedBox(height: 12),

            // 2. Mark as Occupied (Guest Dining)
            _buildStatusButton(
              context: context,
              label: 'Mark as Occupied (Guest Dining)',
              backgroundColor: const Color(0xFFE53935),
              status: FloorTableStatus.occupied,
            ),
            const SizedBox(height: 12),

            // 3. Mark as Reserved
            _buildStatusButton(
              context: context,
              label: 'Mark as Reserved',
              backgroundColor: const Color(0xFFF5A623),
              status: FloorTableStatus.reserved,
            ),
            const SizedBox(height: 12),

            // 4. Temporarily Disable / Cleaning
            _buildStatusButton(
              context: context,
              label: 'Temporarily Disable / Cleaning',
              backgroundColor: const Color(0xFF788882),
              status: FloorTableStatus.disabled,
            ),
            const SizedBox(height: 18),

            // Cancel action
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required String label,
    required Color backgroundColor,
    required FloorTableStatus status,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          onStatusChanged(status);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
