import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/models/physical_table_model.dart';

class TablesTabWidget extends StatefulWidget {
  const TablesTabWidget({super.key});

  @override
  State<TablesTabWidget> createState() => _TablesTabWidgetState();
}

class _TablesTabWidgetState extends State<TablesTabWidget> {
  late List<PhysicalTable> _tables;

  @override
  void initState() {
    super.initState();
    _tables = PhysicalTable.mockList();
  }

  void _addNewTable(PhysicalTable newTable) {
    setState(() {
      _tables.add(newTable);
    });
  }

  void _editTable(PhysicalTable updatedTable) {
    setState(() {
      final index = _tables.indexWhere((t) => t.id == updatedTable.id);
      if (index != -1) {
        _tables[index] = updatedTable;
      }
    });
  }

  void _deleteTable(String id) {
    setState(() {
      _tables.removeWhere((t) => t.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section: Title & + New Table Button ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Restaurant Physical Floor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tables',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add, configure seating, update status, or delete tables.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddOrEditTableDialog(),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'New Table',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // --- Table Cards List ---
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tables.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final table = _tables[index];
            return _buildTableCard(table);
          },
        ),
      ],
    );
  }

  Widget _buildTableCard(PhysicalTable table) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Table Circle Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.table_restaurant,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Middle Title & Status Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      table.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusBadge(table.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${table.seats} Seats • ${table.guestName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right Action Buttons (Edit & Delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showAddOrEditTableDialog(table: table),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: const Color(0xFF64748B),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                tooltip: 'Edit Table',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _confirmDeleteTable(table),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFEF4444),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                tooltip: 'Delete Table',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TableStatus status) {
    Color color;
    String label;

    switch (status) {
      case TableStatus.occupied:
        color = const Color(0xFFEF4444);
        label = 'Occupied';
        break;
      case TableStatus.reserved:
        color = const Color(0xFFF59E0B);
        label = 'Reserved';
        break;
      case TableStatus.available:
        color = const Color(0xFF10B981);
        label = 'Available';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddOrEditTableDialog({PhysicalTable? table}) {
    final isEditing = table != null;
    final nameController = TextEditingController(text: isEditing ? table.name : 'Table 0${_tables.length + 1}');
    final seatsController = TextEditingController(text: isEditing ? table.seats.toString() : '4');
    final guestController = TextEditingController(text: isEditing ? table.guestName : 'No Guest');
    TableStatus selectedStatus = isEditing ? table.status : TableStatus.available;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Edit Table' : 'Add New Physical Table',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Table Name',
                        hintText: 'e.g. Table 05',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seatsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Seats Count',
                        hintText: 'e.g. 4',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: guestController,
                      decoration: InputDecoration(
                        labelText: 'Guest / Reservation Name',
                        hintText: 'e.g. No Guest or Guest Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Table Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: TableStatus.values.map((st) {
                        final isSel = selectedStatus == st;
                        String stLabel = st == TableStatus.occupied
                            ? 'Occupied'
                            : st == TableStatus.reserved
                                ? 'Reserved'
                                : 'Available';
                        Color stColor = st == TableStatus.occupied
                            ? const Color(0xFFEF4444)
                            : st == TableStatus.reserved
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981);

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedStatus = st;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? stColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel ? stColor : AppColors.border,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: stColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? stColor : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final seats = int.tryParse(seatsController.text.trim()) ?? 2;
                          final guest = guestController.text.trim().isEmpty
                              ? 'No Guest'
                              : guestController.text.trim();

                          if (name.isNotEmpty) {
                            if (isEditing) {
                              _editTable(table.copyWith(
                                name: name,
                                seats: seats,
                                guestName: guest,
                                status: selectedStatus,
                              ));
                            } else {
                              _addNewTable(PhysicalTable(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: name,
                                seats: seats,
                                guestName: guest,
                                status: selectedStatus,
                              ));
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Add Table',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTable(PhysicalTable table) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Table'),
          content: Text('Are you sure you want to delete ${table.name}?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteTable(table.id);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
