import 'package:flutter/material.dart';
import '../../../../core/utils/shared_mock_data.dart';
import '../../data/models/floor_table_model.dart';
import '../../data/models/queue_entry_model.dart';

class SeatTableDialog extends StatelessWidget {
  final QueueEntry entry;

  const SeatTableDialog({super.key, required this.entry});

  static Future<FloorTable?> show(BuildContext context, {required QueueEntry entry}) {
    return showDialog<FloorTable>(
      context: context,
      builder: (context) => SeatTableDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableTables = SharedMockData()
        .tables
        .where((t) => t.status == FloorTableStatus.available)
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seat ${entry.guestName} (${entry.partySize} Guests)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an available table to seat this party:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            if (availableTables.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No available tables at the moment.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableTables.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final table = availableTables[index];
                    return InkWell(
                      onTap: () => Navigator.pop(context, table),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              table.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              '${table.seats} Seats',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
