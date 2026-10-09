import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../services/restaurant_database_service.dart';
import '../../data/models/physical_table_model.dart';

class QuickTurnTablesSheet extends StatefulWidget {
  /// Restaurant whose tables are shown and turned.
  final String restaurantId;

  const QuickTurnTablesSheet({super.key, required this.restaurantId});

  static Future<void> show(BuildContext context, {required String restaurantId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickTurnTablesSheet(restaurantId: restaurantId),
    );
  }

  @override
  State<QuickTurnTablesSheet> createState() => _QuickTurnTablesSheetState();
}

class _QuickTurnTablesSheetState extends State<QuickTurnTablesSheet> {
  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();
  final Set<String> _selectedTableIds = {};
  bool _initialized = false;
  bool _isSubmitting = false;
  late final Stream<List<PhysicalTable>> _tablesStream;

  @override
  void initState() {
    super.initState();
    _tablesStream = _firestoreService.streamTables(restaurantId: widget.restaurantId);
  }

  Future<void> _confirmTurn(List<String> tableIds, String tableNames) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _firestoreService.bulkQuickTurnTables(tableIds);
      final called = await _firestoreService.callNextWaitingParties(widget.restaurantId, tableIds.length);
      if (!mounted) return;
      navigator.pop();
      AppToast.showSuccess(
        messenger.context,
        called > 0
            ? '$tableNames marked Available! $called waiting ${called == 1 ? 'party' : 'parties'} notified.'
            : '$tableNames marked Available! No parties are waiting.',
        title: 'Tables Turned',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, 'Could not turn tables: $e', title: 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PhysicalTable>>(
      stream: _tablesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.data == null) {
          return Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load tables: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        if (snapshot.data == null) {
          return Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final allTables = snapshot.data!;
        final dirtyTables = allTables.where((t) => t.status != TableStatus.available).toList();

        if (!_initialized && dirtyTables.isNotEmpty) {
          _selectedTableIds.addAll(dirtyTables.map((t) => t.id));
          _initialized = true;
        }

        final selectedCount = dirtyTables.where((t) => _selectedTableIds.contains(t.id)).length;
        final selectedNumbers = dirtyTables
            .where((t) => _selectedTableIds.contains(t.id))
            .map((t) => t.name)
            .join(' & ');

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.peachTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.accentOrange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Quick Turn Tables',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fast-track table turnover & notify queue',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Auto-Selection Banner ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.peachTint.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.accentOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dirtyTables.isEmpty
                                    ? 'All physical tables are currently available!'
                                    : '$selectedCount ${selectedCount == 1 ? 'table' : 'tables'} auto-selected for fast turn. Confirming will mark available & call waiting parties.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Select Tables to Mark Available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- Table Selection List ---
                      if (dirtyTables.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'No occupied or reserved tables to turn right now.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dirtyTables.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final table = dirtyTables[index];
                            final isSelected = _selectedTableIds.contains(table.id);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedTableIds.remove(table.id);
                                  } else {
                                    _selectedTableIds.add(table.id);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.mintTint.withValues(alpha: 0.4) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Custom Checkbox
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),

                                    // Table icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.table_restaurant,
                                        color: AppColors.accentOrange,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Table Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                table.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                '${table.seats} Seats',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text(
                                                'Guest: ${table.guestName}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: table.status == TableStatus.occupied
                                                      ? AppColors.peachTint
                                                      : AppColors.amberTint,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  table.status == TableStatus.occupied ? 'Occupied' : 'Reserved',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: table.status == TableStatus.occupied
                                                        ? AppColors.accentOrange
                                                        : AppColors.accentAmber,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // --- Bottom Action Button ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedCount == 0 || _isSubmitting
                          ? null
                          : () => _confirmTurn(
                                dirtyTables.where((t) => _selectedTableIds.contains(t.id)).map((t) => t.id).toList(),
                                selectedNumbers,
                              ),
                      icon: const Icon(Icons.bolt, size: 20),
                      label: Text(
                        selectedCount == 0
                            ? 'Select at least 1 table'
                            : 'Turn $selectedCount Table${selectedCount > 1 ? 's' : ''} & Notify Queue',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
