import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';

class CustomerQueueView extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;

  const CustomerQueueView({
    super.key,
    this.restaurants = const [],
  });

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Please log in to view your queue.'));
    }

    return Container(
      color: Colors.white,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService().listenToUserQueue(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You are not currently in any queue.',
                style: TextStyle(color: Color(0xFF8A92A6), fontSize: 16),
              ),
            );
          }

          final activeQueue = snapshot.data!.first;
          final restaurantId = activeQueue['restaurant_id'];
          final restaurant = restaurants.firstWhere(
            (r) => r['id'] == restaurantId,
            orElse: () => <String, dynamic>{},
          );

          final restaurantName = restaurant['name'] ?? 'Restaurant';
          final estWait = restaurant['est_wait'] ?? 'Calculating...';
          final partySize = activeQueue['party_size'] ?? 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header: Restaurant Name + Virtual Waitlist & Live Indicator ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Virtual Waitlist',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8A92A6),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Your Queue Position & Estimated Wait Card ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF1F3F5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Party Size',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8A92A6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'P',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFE86B43),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$partySize',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFE86B43),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Wait',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8A92A6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                estWait,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E3A34),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: const [
                          Icon(
                            Icons.table_restaurant_outlined,
                            size: 19,
                            color: Color(0xFF1E3A34),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Your table is being prepared.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please stay within 10 min distance of the restaurant.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A92A6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // --- Queue Progress Section Title ---
                const Text(
                  'Queue Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Progress Timeline ---
                _buildTimelineStep(
                  indicator: _buildCompletedIndicator(),
                  title: 'Joined Queue',
                  subtitle: 'Successfully placed in waitlist',
                  hasLineBelow: true,
                  lineColor: const Color(0xFF1E3A34),
                ),
                _buildTimelineStep(
                  indicator: _buildCurrentIndicator(),
                  title: 'Waiting for Table',
                  subtitle: '$estWait remaining',
                  titleColor: const Color(0xFFE86B43),
                  hasLineBelow: true,
                  lineColor: const Color(0xFFE5E7EB),
                ),
                _buildTimelineStep(
                  indicator: _buildUpcomingIndicator(),
                  title: 'Table Ready',
                  subtitle: 'Ready for seating',
                  titleColor: const Color(0xFF6B7280),
                  hasLineBelow: false,
                ),
                const SizedBox(height: 48),

                // --- Cancel Button ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await SupabaseService().updateQueueEntryStatus(activeQueue['id'], 'cancelled');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to leave queue: $e')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Leave Waitlist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep({
    required Widget indicator,
    required String title,
    required String subtitle,
    Color titleColor = const Color(0xFF111827),
    bool hasLineBelow = true,
    Color lineColor = const Color(0xFF1E3A34),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            indicator,
            if (hasLineBelow)
              Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A92A6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A34),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCurrentIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFE86B43),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
    );
  }
}
