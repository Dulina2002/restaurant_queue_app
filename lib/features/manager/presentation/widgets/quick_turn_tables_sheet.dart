import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class QuickTurnTablesSheet extends StatefulWidget {
  const QuickTurnTablesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickTurnTablesSheet(),
    );
  }

  @override
  State<QuickTurnTablesSheet> createState() => _QuickTurnTablesSheetState();
}

class _QuickTurnTablesSheetState extends State<QuickTurnTablesSheet> {
  final List<Map<String, dynamic>> _dirtyTables = [
    {
      'id': 4,
      'number': 'Table 04',
      'capacity': 6,
      'status': 'Bussing in progress',
      'timeOccupied': '42 mins',
      'selected': true,
    },
    {
      'id': 5,
      'number': 'Table 05',
      'capacity': 2,
      'status': 'Guest paid / Leaving',
      'timeOccupied': '35 mins',
      'selected': true,
    },
    {
      'id': 8,
      'number': 'Table 08',
      'capacity': 4,
      'status': 'Guest paid',
      'timeOccupied': '50 mins',
      'selected': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCount = _dirtyTables.where((t) => t['selected'] == true).length;
    final selectedNumbers = _dirtyTables
        .where((t) => t['selected'] == true)
        .map((t) => t['number'])
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
                      decoration: BoxDecoration(
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
                            '$selectedCount tables auto-selected based on turnover priority. Confirming will notify waiting queue parties.',
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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dirtyTables.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final table = _dirtyTables[index];
                      final isSelected = table['selected'] as bool;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            table['selected'] = !isSelected;
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
                                          table['number'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          table['timeOccupied'],
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
                                          'Cap: ${table['capacity']} Seats',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.amberTint,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            table['status'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.accentAmber,
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
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '⚡ $selectedNumbers marked Available! Next $selectedCount queue parties notified.',
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
  }
}
