import 'package:flutter/material.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../services/restaurant_database_service.dart';
import '../../data/models/physical_table_model.dart';

class TablesTabWidget extends StatefulWidget {
  /// All restaurants available in the picker.
  final List<RestaurantModel> restaurants;

  /// Id of the restaurant selected in the dashboard header.
  final String selectedRestaurantId;

  const TablesTabWidget({
    super.key,
    required this.restaurants,
    required this.selectedRestaurantId,
  });

  @override
  State<TablesTabWidget> createState() => _TablesTabWidgetState();
}

class _TablesTabWidgetState extends State<TablesTabWidget> {
  static const String _allFilter = 'All';

  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();

  /// Restaurant id being displayed, or 'All' for every restaurant.
  late String _selectedRestaurantFilter;
  late Stream<List<PhysicalTable>> _tablesStream;
  String _selectedZoneFilter = 'All Zones';
  bool _isGridView = false;
  TableStatus? _selectedStatusFilter;

  final List<String> _zoneOptions = [
    'All Zones',
    'Main Dining',
    'Terrace',
    'VIP Room',
    'Bar Seating',
  ];

  RestaurantModel? _restaurantById(String id) {
    for (final r in widget.restaurants) {
      if (r.id == id) return r;
    }
    return null;
  }

  String _restaurantName(String id) => _restaurantById(id)?.name ?? id;

  /// Filter pills: 'All' plus the restaurant chosen in the dashboard header.
  List<String> get _filterIds => [_allFilter, widget.selectedRestaurantId];

  @override
  void initState() {
    super.initState();
    _selectedRestaurantFilter = widget.selectedRestaurantId;
    _tablesStream = _firestoreService.streamTables(restaurantId: _selectedRestaurantFilter);
  }

  @override
  void didUpdateWidget(TablesTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRestaurantId != oldWidget.selectedRestaurantId) {
      _setRestaurantFilter(widget.selectedRestaurantId);
    }
  }

  /// Changes which restaurant is shown and re-subscribes to its live tables.
  void _setRestaurantFilter(String id) {
    setState(() {
      _selectedRestaurantFilter = id;
      _tablesStream = _firestoreService.streamTables(restaurantId: id);
    });
  }

  Future<void> _addNewTable(PhysicalTable newTable) async {
    try {
      await _firestoreService.addTable(newTable);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Physical table saved to the database',
        title: 'Table Added',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error adding table: $e',
        title: 'Error',
      );
    }
  }

  Future<void> _editTable(PhysicalTable updatedTable) async {
    try {
      await _firestoreService.updateTable(updatedTable);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Physical table updated in the database',
        title: 'Table Updated',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error updating table: $e',
        title: 'Error',
      );
    }
  }

  Future<void> _deleteTable(String id) async {
    try {
      await _firestoreService.deleteTable(id);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Table removed from the database',
        title: 'Table Removed',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error deleting table: $e',
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PhysicalTable>>(
      stream: _tablesStream,
      builder: (context, snapshot) {
        final rawTables = snapshot.data ?? const <PhysicalTable>[];

        final availCount = rawTables.where((t) => t.status == TableStatus.available).length;
        final occCount = rawTables.where((t) => t.status == TableStatus.occupied).length;
        final resCount = rawTables.where((t) => t.status == TableStatus.reserved).length;

        final tables = rawTables.where((t) {
          if (_selectedZoneFilter != 'All Zones' && t.zone.toLowerCase() != _selectedZoneFilter.toLowerCase()) {
            return false;
          }
          if (_selectedStatusFilter != null && t.status != _selectedStatusFilter) {
            return false;
          }
          return true;
        }).toList();
        final isLoading = snapshot.data == null && !snapshot.hasError;
        final loadError = snapshot.data == null ? snapshot.error : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section: Title, View Switcher & + New Table Button ---
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
                        'Add, configure seating, update status, or delete tables for the selected restaurant.',
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
                Row(
                  children: [
                    // Layout Toggle Button (List vs Grid)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                        icon: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddOrEditTableDialog(currentTablesCount: tables.length),
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
              ],
            ),
            const SizedBox(height: 14),

            // --- Floor Summary KPI Counter Chips ---
            Row(
              children: [
                _buildKpiChip(
                  label: 'Available',
                  count: availCount,
                  color: const Color(0xFF10B981),
                  isSelected: _selectedStatusFilter == TableStatus.available,
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = _selectedStatusFilter == TableStatus.available ? null : TableStatus.available;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildKpiChip(
                  label: 'Occupied',
                  count: occCount,
                  color: const Color(0xFFEF4444),
                  isSelected: _selectedStatusFilter == TableStatus.occupied,
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = _selectedStatusFilter == TableStatus.occupied ? null : TableStatus.occupied;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildKpiChip(
                  label: 'Reserved',
                  count: resCount,
                  color: const Color(0xFFF59E0B),
                  isSelected: _selectedStatusFilter == TableStatus.reserved,
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = _selectedStatusFilter == TableStatus.reserved ? null : TableStatus.reserved;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Restaurant & Zone Filter Pills ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._filterIds.map((restId) {
                    final isSelected = _selectedRestaurantFilter == restId;
                    final rest = restId == _allFilter ? 'All' : _restaurantName(restId);
                    return GestureDetector(
                      onTap: () => _setRestaurantFilter(restId),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          rest,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                  Container(
                    height: 20,
                    width: 1,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  ..._zoneOptions.map((zone) {
                    final isSelected = _selectedZoneFilter == zone;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedZoneFilter = zone),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          zone,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Table Cards (Grid or List View) ---
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (loadError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'Could not load tables: $loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () => _setRestaurantFilter(_selectedRestaurantFilter),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (tables.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No tables configured yet for this selection.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else if (_isGridView)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 155,
                ),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return _buildGridTableCard(table);
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tables.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return _buildTableCard(table);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildKpiChip({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
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
            const SizedBox(width: 5),
            Text(
              '$label: $count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTableCard(PhysicalTable table) {
    final statusColor = table.status == TableStatus.occupied
        ? const Color(0xFFEF4444)
        : table.status == TableStatus.reserved
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_restaurant,
                  color: statusColor,
                  size: 18,
                ),
              ),
              _buildStatusBadge(table.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            table.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${table.seats} Seats • ${table.zone}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            table.guestName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: table.status == TableStatus.available ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showAddOrEditTableDialog(table: table),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _confirmDeleteTable(table),
                child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
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
                  '${table.seats} Seats • ${table.zone} • ${table.guestName}',
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

  void _showAddOrEditTableDialog({PhysicalTable? table, int currentTablesCount = 4}) {
    final isEditing = table != null;
    final nameController = TextEditingController(text: isEditing ? table.name : 'Table 0${currentTablesCount + 1}');
    final seatsController = TextEditingController(text: isEditing ? table.seats.toString() : '4');
    final guestController = TextEditingController(text: isEditing ? table.guestName : 'No Guest');
    TableStatus selectedStatus = isEditing ? table.status : TableStatus.available;
    String selectedZone = isEditing ? table.zone : 'Main Dining';

    String selectedRestaurantId = isEditing
        ? table.restaurantId
        : (_selectedRestaurantFilter == _allFilter ? widget.selectedRestaurantId : _selectedRestaurantFilter);

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

                    // Restaurant Dropdown Selector
                    const Text(
                      'Restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: widget.restaurants.any((r) => r.id == selectedRestaurantId)
                          ? selectedRestaurantId
                          : (widget.restaurants.isNotEmpty ? widget.restaurants.first.id : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                      ),
                      items: widget.restaurants.isEmpty
                          ? [
                              DropdownMenuItem<String>(
                                value: selectedRestaurantId,
                                child: Text(selectedRestaurantId),
                              ),
                            ]
                          : widget.restaurants.map((restaurant) {
                              return DropdownMenuItem<String>(
                                value: restaurant.id,
                                child: Text(
                                  restaurant.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                      onChanged: (newId) {
                        if (newId != null) {
                          setSheetState(() => selectedRestaurantId = newId);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Floor Zone Selector Pills
                    const Text(
                      'Floor Zone',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Main Dining', 'Terrace', 'VIP Room', 'Bar Seating'].map((z) {
                        final isSel = selectedZone == z;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedZone = z),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              z,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                                restaurantId: selectedRestaurantId,
                                name: name,
                                zone: selectedZone,
                                seats: seats,
                                guestName: guest,
                                status: selectedStatus,
                              ));
                            } else {
                              _addNewTable(PhysicalTable(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                restaurantId: selectedRestaurantId,
                                name: name,
                                zone: selectedZone,
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
