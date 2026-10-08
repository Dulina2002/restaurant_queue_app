import 'package:flutter/material.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/user_profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/restaurant_image.dart';
import '../../../services/restaurant_database_service.dart';
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
                        SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: RestaurantImage(
                            imageUrl: restaurant.imageUrl,
                            restaurantId: restaurant.id,
                            restaurantName: restaurant.name,
                            cuisine: restaurant.cuisine,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
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
                            stream: RestaurantDatabaseService().streamTables(restaurantId: restaurant.id),
                            builder: (context, snapshot) {
                              final tables = snapshot.data ?? [];
                              if (tables.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Text(
                                    'No tables configured for this restaurant.',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return Column(
                                children: tables.map((t) {
                                  final isAvailable = t.status == TableStatus.available;
                                  final statusText = isAvailable ? 'Available' : 'Occupied / Reserved';
                                  final statusColor = isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                                  final bgColor = isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReserveTableStepperScreen(
                                              restaurant: restaurant,
                                              profile: profile,
                                              initialTable: t,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: _buildTableAvailabilityCard(
                                        title: t.name,
                                        subtitle: 'Up to ${t.seats} guests',
                                        statusText: statusText,
                                        statusColor: statusColor,
                                        bgColor: bgColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
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
