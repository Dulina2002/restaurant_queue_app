import 'package:flutter/material.dart';
import '../../../../models/reservation_model.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/receptionist_context.dart';
import '../../../../shared/widgets/top_toast.dart';
import '../../data/models/floor_table_model.dart';

class ReassignTableDialog extends StatefulWidget {
  final ReservationModel reservation;
  final String? restaurantId;
  final String? restaurantName;

  const ReassignTableDialog({
    super.key,
    required this.reservation,
    this.restaurantId,
    this.restaurantName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ReservationModel reservation,
    String? restaurantId,
    String? restaurantName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReassignTableDialog(
        reservation: reservation,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }

  @override
  State<ReassignTableDialog> createState() => _ReassignTableDialogState();
}

class _ReassignTableDialogState extends State<ReassignTableDialog> {
  String? _selectedTableName;
  final TextEditingController _customTableController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTableName = widget.reservation.assignedTable;
  }

  @override
  void dispose() {
    _customTableController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final chosenTable = _customTableController.text.trim().isNotEmpty
        ? _customTableController.text.trim()
        : _selectedTableName;

    if (chosenTable == null || chosenTable.isEmpty) {
      TopToast.show(
        context,
        message: 'Please select or enter a table to reassign',
        backgroundColor: const Color(0xFFD97706),
        icon: Icons.info_outline,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final targetRestaurantId = (widget.restaurantId != null && widget.restaurantId!.isNotEmpty)
          ? widget.restaurantId!
          : ReceptionistContext().activeRestaurantId;

      // Update special notes so any embedded 'Table: ...' is also updated
      String? updatedNotes = widget.reservation.specialNotes;
      if (updatedNotes != null && updatedNotes.contains('Table: ')) {
        updatedNotes = updatedNotes.replaceAll(RegExp(r'Table:\s*[^•\n]+'), 'Table: $chosenTable');
      }

      await SupabaseService().reassignReservationTable(
        reservationId: widget.reservation.id,
        newTable: chosenTable,
        updatedNotes: updatedNotes,
      );

      // Floor table state sync if available
      final floorTables = SupabaseService().getFloorTablesSync(restaurantId: targetRestaurantId);

      // 1. Free previous table if it was assigned to this guest
      final prevTableStr = widget.reservation.assignedTable ?? '';
      if (prevTableStr.isNotEmpty) {
        final prevMatch = floorTables
            .where((t) =>
                t.name.toLowerCase() == prevTableStr.toLowerCase() ||
                prevTableStr.toLowerCase().contains(t.name.toLowerCase()))
            .firstOrNull;
        if (prevMatch != null && prevMatch.guestName == widget.reservation.guestName) {
          await SupabaseService().updateFloorTableStatus(
            restaurantId: targetRestaurantId,
            tableId: prevMatch.id,
            status: FloorTableStatus.available,
            guestName: '',
          );
        }
      }

      // 2. Mark new table as reserved for this guest if found
      final newMatch = floorTables
          .where((t) =>
              t.name.toLowerCase() == chosenTable.toLowerCase() ||
              chosenTable.toLowerCase().contains(t.name.toLowerCase()))
          .firstOrNull;
      if (newMatch != null) {
        await SupabaseService().updateFloorTableStatus(
          restaurantId: targetRestaurantId,
          tableId: newMatch.id,
          status: FloorTableStatus.reserved,
          guestName: widget.reservation.guestName,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        TopToast.show(
          context,
          message: 'Table reassigned to $chosenTable for ${widget.reservation.guestName}',
          backgroundColor: const Color(0xFF2E9B60),
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        TopToast.show(
          context,
          message: 'Failed to reassign table: $e',
          backgroundColor: const Color(0xFFDC2626),
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetRestaurantId = (widget.restaurantId != null && widget.restaurantId!.isNotEmpty)
        ? widget.restaurantId!
        : ReceptionistContext().activeRestaurantId;
    final targetRestaurantName = (widget.restaurantName != null && widget.restaurantName!.isNotEmpty)
        ? widget.restaurantName!
        : ReceptionistContext().activeRestaurantName;

    final currentTable = (widget.reservation.assignedTable != null && widget.reservation.assignedTable!.isNotEmpty)
        ? widget.reservation.assignedTable!
        : 'Assigned on arrival';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.table_restaurant_rounded,
                      color: Color(0xFF2E9B60),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reassign Table',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.reservation.guestName} • ${widget.reservation.partySize} Guests • ${widget.reservation.time}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current table info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          children: [
                            const TextSpan(text: 'Current Assignment: '),
                            TextSpan(
                              text: currentTable,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            TextSpan(text: ' at $targetRestaurantName'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Select Floor Table',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),

              // Stream of Floor Tables
              Expanded(
                child: StreamBuilder<List<FloorTable>>(
                  stream: SupabaseService().streamFloorTables(restaurantId: targetRestaurantId),
                  initialData: SupabaseService().getFloorTablesSync(restaurantId: targetRestaurantId),
                  builder: (context, snapshot) {
                    var tables = snapshot.data ?? [];
                    if (tables.isEmpty) {
                      tables = FloorTable.mockListForRestaurant(targetRestaurantId);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: tables.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        final isSelected = _selectedTableName == table.name;
                        final isCurrent = table.name.toLowerCase() == currentTable.toLowerCase();
                        final isAvailable = table.status == FloorTableStatus.available;
                        final fitsParty = table.seats >= widget.reservation.partySize;

                        Color borderColor = const Color(0xFFE2E8F0);
                        Color bgColor = Colors.white;

                        if (isSelected) {
                          borderColor = const Color(0xFF2E9B60);
                          bgColor = const Color(0xFFF0FDF4);
                        } else if (isCurrent) {
                          borderColor = const Color(0xFFBBF7D0);
                          bgColor = const Color(0xFFF7FEE7);
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTableName = table.name;
                              _customTableController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.table_bar_rounded,
                                  size: 20,
                                  color: isSelected
                                      ? const Color(0xFF2E9B60)
                                      : (isAvailable
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            table.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? const Color(0xFF166534)
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (isCurrent)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Current',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${table.seats} Seats • ${fitsParty ? "Accommodates ${widget.reservation.partySize}" : "Tight capacity"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: fitsParty ? const Color(0xFF64748B) : const Color(0xFFD97706),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statusBg(table.status),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _statusLabel(table.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(table.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? const Color(0xFF2E9B60) : const Color(0xFFCBD5E1),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Custom table input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTableController,
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _selectedTableName != null) {
                          setState(() => _selectedTableName = null);
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Or custom table (e.g. Table 01 - Main Dining)',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2E9B60)),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E9B60),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Reassignment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBg(FloorTableStatus status) {
    switch (status) {
      case FloorTableStatus.available:
        return const Color(0xFFECFDF5);
      case FloorTableStatus.occupied:
        return const Color(0xFFFFF7ED);
      case FloorTableStatus.reserved:
        return const Color(0xFFEFF6FF);
      case FloorTableStatus.disabled:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusColor(FloorTableStatus status) {
    switch (status) {
      case FloorTableStatus.available:
        return const Color(0xFF059669);
      case FloorTableStatus.occupied:
        return const Color(0xFFEA580C);
      case FloorTableStatus.reserved:
        return const Color(0xFF2563EB);
      case FloorTableStatus.disabled:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel(FloorTableStatus status) {
    switch (status) {
      case FloorTableStatus.available:
        return 'Available';
      case FloorTableStatus.occupied:
        return 'Occupied';
      case FloorTableStatus.reserved:
        return 'Reserved';
      case FloorTableStatus.disabled:
        return 'Disabled';
    }
  }
}
