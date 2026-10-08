import 'package:flutter/material.dart';

class DemoQuickLaunchBar extends StatelessWidget {
  final String? activeRole; // 'Customer', 'Receptionist', 'Manager', 'Admin', or null
  final ValueChanged<String> onRoleSelected;

  const DemoQuickLaunchBar({
    super.key,
    this.activeRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    const roles = ['Customer', 'Receptionist', 'Manager', 'Admin'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'OR DEMO QUICK-LAUNCH AS',
          style: TextStyle(
            color: Color(0xFF8BAA99),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Row(
          children: roles.map((role) {
            final isSelected = activeRole != null &&
                activeRole!.isNotEmpty &&
                role.toLowerCase() == activeRole!.toLowerCase();
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () => onRoleSelected(role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF142B1D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.12),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF34D399)
                            : Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
