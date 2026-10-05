import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/models/floor_table_model.dart';
import 'table_status_dialog.dart';

class FloorOverviewWidget extends StatefulWidget {
  const FloorOverviewWidget({super.key});

  @override
  State<FloorOverviewWidget> createState() => _FloorOverviewWidgetState();
}

class _FloorOverviewWidgetState extends State<FloorOverviewWidget> {
  late List<FloorTable> _tables;

  @override
  void initState() {
    super.initState();
    _tables = FloorTable.mockList();
  }

  void _updateTableStatus(FloorTable table, FloorTableStatus newStatus) {
    setState(() {
      final index = _tables.indexWhere((t) => t.id == table.id);
      if (index != -1) {
        _tables[index] = table.copyWith(status: newStatus);
      }
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Live Floor Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap any table to modify seating status or mark available',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Legend
        Row(
          children: [
            _buildLegendItem('Available', const Color(0xFF10B981)),
            const SizedBox(width: 16),
            _buildLegendItem('Reserved', const Color(0xFFD97706)),
            const SizedBox(width: 16),
            _buildLegendItem('Occupied', const Color(0xFFEF4444)),
            const SizedBox(width: 16),
            _buildLegendItem('Disabled', const Color(0xFF94A3B8)),
          ],
        ),
        const SizedBox(height: 20),

        // Table Grid
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
          'border': const Color(0xFF10B981).withOpacity(0.4),
          'dot': const Color(0xFF10B981),
          'badgeBg': const Color(0xFFECFDF5),
          'badgeText': const Color(0xFF059669),
        };
      case FloorTableStatus.reserved:
        return {
          'border': const Color(0xFFD97706).withOpacity(0.4),
          'dot': const Color(0xFFD97706),
          'badgeBg': const Color(0xFFFFFBEB),
          'badgeText': const Color(0xFFD97706),
        };
      case FloorTableStatus.occupied:
        return {
          'border': const Color(0xFFEF4444).withOpacity(0.4),
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
