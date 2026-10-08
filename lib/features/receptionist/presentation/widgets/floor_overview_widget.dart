import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/receptionist_context.dart';
import '../../../../models/restaurant_model.dart';
import '../../data/models/floor_table_model.dart';
import 'table_status_dialog.dart';

class FloorOverviewWidget extends StatefulWidget {
  const FloorOverviewWidget({super.key});

  @override
  State<FloorOverviewWidget> createState() => _FloorOverviewWidgetState();
}

class _FloorOverviewWidgetState extends State<FloorOverviewWidget> {
  StreamSubscription<List<FloorTable>>? _tablesSub;
  List<FloorTable> _tables = [];
  bool _isLoading = true;

  String get _currentRestaurantId => ReceptionistContext().activeRestaurantId;
  String get _currentRestaurantName => ReceptionistContext().activeRestaurantName;

  @override
  void initState() {
    super.initState();
    ReceptionistContext().activeRestaurantNotifier.addListener(_onRestaurantChanged);
    _subscribeToTables();
  }

  void _onRestaurantChanged() {
    if (mounted) {
      _subscribeToTables();
    }
  }

  void _subscribeToTables() {
    _tablesSub?.cancel();
    setState(() => _isLoading = true);

    final restaurantId = _currentRestaurantId;
    _tablesSub = SupabaseService()
        .streamFloorTables(restaurantId: restaurantId)
        .listen((tables) {
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _tablesSub?.cancel();
    ReceptionistContext().activeRestaurantNotifier.removeListener(_onRestaurantChanged);
    super.dispose();
  }

  Future<void> _updateTableStatus(FloorTable table, FloorTableStatus newStatus) async {
    final restaurantId = _currentRestaurantId;
    try {
      await SupabaseService().updateFloorTableStatus(
        restaurantId: restaurantId,
        tableId: table.id,
        status: newStatus,
        guestName: newStatus == FloorTableStatus.available ? '' : table.guestName,
      );

      if (mounted) {
        AppToast.showSuccess(
          context,
          '${table.name} updated to ${_getStatusLabel(newStatus)}',
          title: 'Table Status Updated',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'Failed to update table status: $e',
          title: 'Update Error',
        );
      }
    }
  }

  void _showTableStatusDialog(FloorTable table) {
    TableStatusDialog.show(
      context,
      table: table,
      onStatusChanged: (newStatus) {
        _updateTableStatus(table, newStatus);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = _tables.where((t) => t.status == FloorTableStatus.available).length;
    final reservedCount = _tables.where((t) => t.status == FloorTableStatus.reserved).length;
    final occupiedCount = _tables.where((t) => t.status == FloorTableStatus.occupied).length;
    final disabledCount = _tables.where((t) => t.status == FloorTableStatus.disabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Floor Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Text(
                          _currentRestaurantName,
                          style: const TextStyle(
                            color: Color(0xFFC2410C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$availableCount Available • ${_tables.length} Total',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Restaurant Quick Switcher
            StreamBuilder<List<RestaurantModel>>(
              stream: SupabaseService().streamActiveRestaurants(),
              builder: (context, snapshot) {
                final restaurants = snapshot.data ?? [];
                if (restaurants.isEmpty) return const SizedBox.shrink();

                return PopupMenuButton<RestaurantModel>(
                  tooltip: 'Switch Restaurant',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: Colors.white,
                  elevation: 8,
                  onSelected: (selected) {
                    ReceptionistContext().setActiveRestaurant(selected);
                  },
                  itemBuilder: (context) {
                    return restaurants.map((r) {
                      final isSelected = r.id == _currentRestaurantId;
                      return PopupMenuItem<RestaurantModel>(
                        value: r,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.storefront_outlined,
                              size: 18,
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, size: 16, color: Color(0xFF475569)),
                        SizedBox(width: 4),
                        Text(
                          'Switch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
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
        const SizedBox(height: 6),
        const Text(
          'Tap any table to modify seating status or mark available',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Legend with Live Counts
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLegendItem('Available ($availableCount)', const Color(0xFF10B981)),
            _buildLegendItem('Reserved ($reservedCount)', const Color(0xFFD97706)),
            _buildLegendItem('Occupied ($occupiedCount)', const Color(0xFFEF4444)),
            _buildLegendItem('Disabled ($disabledCount)', const Color(0xFF94A3B8)),
          ],
        ),
        const SizedBox(height: 20),

        // Tables Content
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            ),
          )
        else if (_tables.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.table_restaurant_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  'No tables configured for $_currentRestaurantName',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _tables.length,
            itemBuilder: (context, index) {
              return _buildTableCard(_tables[index]);
            },
          ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTableCard(FloorTable table) {
    final colors = _getStatusColors(table.status);
    final statusLabel = _getStatusLabel(table.status);

    return GestureDetector(
      onTap: () => _showTableStatusDialog(table),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors['border']!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors['dot']!.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table name + status dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    table.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors['dot'],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${table.seats} Seats',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (table.guestName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                table.guestName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            // Status badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: colors['badgeBg'],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors['badgeText'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors(FloorTableStatus status) {
    switch (status) {
      case FloorTableStatus.available:
        return {
          'border': const Color(0xFF10B981).withValues(alpha: 0.4),
          'dot': const Color(0xFF10B981),
          'badgeBg': const Color(0xFFECFDF5),
          'badgeText': const Color(0xFF059669),
        };
      case FloorTableStatus.reserved:
        return {
          'border': const Color(0xFFD97706).withValues(alpha: 0.4),
          'dot': const Color(0xFFD97706),
          'badgeBg': const Color(0xFFFFFBEB),
          'badgeText': const Color(0xFFD97706),
        };
      case FloorTableStatus.occupied:
        return {
          'border': const Color(0xFFEF4444).withValues(alpha: 0.4),
          'dot': const Color(0xFFEF4444),
          'badgeBg': const Color(0xFFFEF2F2),
          'badgeText': const Color(0xFFDC2626),
        };
      case FloorTableStatus.disabled:
        return {
          'border': const Color(0xFFE2E8F0),
          'dot': const Color(0xFF94A3B8),
          'badgeBg': const Color(0xFFF1F5F9),
          'badgeText': const Color(0xFF94A3B8),
        };
    }
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
}
