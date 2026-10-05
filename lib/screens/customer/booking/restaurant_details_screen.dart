import 'package:flutter/material.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/user_profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../../features/manager/data/models/physical_table_model.dart';
import 'reserve_table_stepper_screen.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final RestaurantModel restaurant;
  final UserProfile? profile;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Hero Banner with Back Button & Cuisine Tag ---
                    Stack(
                      children: [
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF14382A), Color(0xFF092017)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              size: 110,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        // Top Bar Actions
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.4),
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.4),
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cuisine Tag Pill
                        Positioned(
                          left: 20,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant_menu_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  restaurant.tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // --- Restaurant Details Card ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name & Availability Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tables Available',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Rating & Price category
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toString(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                ' (${restaurant.reviewsCount} reviews) • \$\$\$ Fine Dining',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Address & Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.location.isNotEmpty ? restaurant.location : '42 Marine Drive, Colombo 03, Sri Lanka',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Open until 11:00 PM',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.near_me_outlined, size: 18, color: AppColors.primary),
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 20),

                          // --- Table Availability Section with Live Firestore Stream ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Table Availability',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE OVERVIEW',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981), letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          StreamBuilder<List<PhysicalTable>>(
                            stream: FirestoreService().streamTables(restaurantId: restaurant.id),
                            builder: (context, snapshot) {
                              final tables = snapshot.data ?? [];
                              final tablesFor2 = tables.where((t) => t.seats == 2).toList();
                              final tablesFor4 = tables.where((t) => t.seats == 4).toList();
                              final tablesFor6 = tables.where((t) => t.seats == 6).toList();
                              final tablesFor8Plus = tables.where((t) => t.seats >= 8).toList();

                              final hasAvail2 = tablesFor2.isEmpty || tablesFor2.any((t) => t.status == TableStatus.available);
                              final hasAvail4 = tablesFor4.isEmpty || tablesFor4.any((t) => t.status == TableStatus.available);
                              final hasAvail6 = tablesFor6.isEmpty || tablesFor6.any((t) => t.status == TableStatus.available);

                              return Column(
                                children: [
                                  _buildTableAvailabilityCard(
                                    title: 'Table for 2',
                                    subtitle: 'Up to 2 guests',
                                    statusText: hasAvail2 ? 'Available' : 'Occupied',
                                    statusColor: hasAvail2 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    bgColor: hasAvail2 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTableAvailabilityCard(
                                    title: 'Table for 4',
                                    subtitle: 'Up to 4 guests',
                                    statusText: hasAvail4 ? 'Available' : 'Occupied',
                                    statusColor: hasAvail4 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    bgColor: hasAvail4 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTableAvailabilityCard(
                                    title: 'Table for 6',
                                    subtitle: 'Up to 6 guests',
                                    statusText: hasAvail6 ? 'Few Available' : 'Waitlist Only',
                                    statusColor: hasAvail6 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                                    bgColor: hasAvail6 ? const Color(0xFFFFFBEB) : const Color(0xFFFFEBEE),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTableAvailabilityCard(
                                    title: 'Private Dining (8-12)',
                                    subtitle: 'Up to 12 guests',
                                    statusText: tablesFor8Plus.any((t) => t.status == TableStatus.available) ? 'Available' : 'Requires 24h Advance',
                                    statusColor: tablesFor8Plus.any((t) => t.status == TableStatus.available) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    bgColor: tablesFor8Plus.any((t) => t.status == TableStatus.available) ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Fixed Bottom "Reserve a Table" Button ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReserveTableStepperScreen(
                          restaurant: restaurant,
                          profile: profile,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text(
                    'Reserve a Table',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableAvailabilityCard({
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_restaurant_outlined, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: statusColor),
                const SizedBox(width: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
