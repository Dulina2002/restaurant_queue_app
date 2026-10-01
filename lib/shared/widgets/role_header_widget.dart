import 'package:flutter/material.dart';

class RoleHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String roleName;
  final Color roleColor;
  final bool isSigningOut;
  final VoidCallback onSignOut;

  const RoleHeaderWidget({
    super.key,
    required this.roleName,
    required this.roleColor,
    required this.isSigningOut,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF143621),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              roleName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: isSigningOut ? null : onSignOut,
            child: isSigningOut
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Tap to switch role',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
          ),
          const Text(
            'DineQueue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
