import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/models/floor_table_model.dart';

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

  void _showTableActionSheet(FloorTable table) {
    if (table.status == FloorTableStatus.disabled) {
      // Only allow enabling a disabled table
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildActionSheet(table),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionSheet(table),
    );
  }

  Widget _buildActionSheet(FloorTable table) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            '${table.name} — Modify Status',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (table.guestName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${table.seats} Seats • ${table.guestName}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '${table.seats} Seats',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Change Status To',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Mark Available',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            isActive: table.status == FloorTableStatus.available,
            onTap: () {
              _updateTableStatus(table, FloorTableStatus.available);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Mark Occupied',
            icon: Icons.no_meals_outlined,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
            isActive: table.status == FloorTableStatus.occupied,
            onTap: () {
              _updateTableStatus(table, FloorTableStatus.occupied);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Mark Reserved',
            icon: Icons.bookmark_outline,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            isActive: table.status == FloorTableStatus.reserved,
            onTap: () {
              _updateTableStatus(table, FloorTableStatus.reserved);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Disable Table',
            icon: Icons.block_outlined,
            color: const Color(0xFF94A3B8),
            bgColor: const Color(0xFFF8FAFC),
            isActive: table.status == FloorTableStatus.disabled,
            onTap: () {
              _updateTableStatus(table, FloorTableStatus.disabled);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? bgColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withOpacity(0.4) : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isActive ? color : AppColors.textMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? color : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(Icons.check_circle_rounded, size: 18, color: color),
          ],
        ),
      ),
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
      onTap: () => _showTableActionSheet(table),
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
