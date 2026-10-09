import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/receptionist_context.dart';
import '../../data/models/floor_table_model.dart';
import '../../data/models/queue_entry_model.dart';

class SeatTableDialog extends StatelessWidget {
  final QueueEntry entry;
  final String? restaurantId;

  const SeatTableDialog({
    super.key,
    required this.entry,
    this.restaurantId,
  });

  static Future<FloorTable?> show(
    BuildContext context, {
    required QueueEntry entry,
    String? restaurantId,
  }) {
    return showDialog<FloorTable>(
      context: context,
      builder: (context) => SeatTableDialog(entry: entry, restaurantId: restaurantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetRestaurantId = (restaurantId != null && restaurantId!.isNotEmpty)
        ? restaurantId!
        : ReceptionistContext().activeRestaurantId;
    final targetRestaurantName = ReceptionistContext().activeRestaurantName;

    return StreamBuilder<List<FloorTable>>(
      stream: SupabaseService().streamFloorTables(restaurantId: targetRestaurantId),
      initialData: SupabaseService().getFloorTablesSync(restaurantId: targetRestaurantId),
      builder: (context, snapshot) {
        final allTables = snapshot.data ?? [];
        final availableTables = allTables
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
                const SizedBox(height: 6),
                Text(
                  'Select an available table at $targetRestaurantName to seat this party:',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                if (availableTables.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.table_restaurant_outlined, size: 36, color: Color(0xFFDC2626)),
                        const SizedBox(height: 8),
                        Text(
                          'No available tables at $targetRestaurantName',
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Please wait for a party to clear or check the floor plan.',
                          style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
                        ),
                      ],
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
                        final fitsComfortably = table.seats >= entry.partySize;

                        return InkWell(
                          onTap: () => Navigator.pop(context, table),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: fitsComfortably
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: fitsComfortably
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.table_restaurant,
                                      size: 18,
                                      color: fitsComfortably
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      table.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: fitsComfortably
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${table.seats} Seats',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: fitsComfortably
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                    if (!fitsComfortably) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Tight fit',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
      },
    );
  }
}
