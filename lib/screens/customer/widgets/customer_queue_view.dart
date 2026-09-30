import 'package:flutter/material.dart';

class CustomerQueueView extends StatelessWidget {
  const CustomerQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
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
                  children: const [
                    Text(
                      'Ocean Bistro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
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
                            'Your Queue Position',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A92A6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: '#',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE86B43),
                                  ),
                                ),
                                TextSpan(
                                  text: '1',
                                  style: TextStyle(
                                    fontSize: 36,
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
                        children: const [
                          Text(
                            'Estimated Wait',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A92A6),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '22 min',
                            style: TextStyle(
                              fontSize: 28,
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
                    '0 groups ahead of you. Please stay within 10 min distance.',
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
              subtitle: 'Confirmed ticket Q10',
              hasLineBelow: true,
              lineColor: const Color(0xFF1E3A34),
            ),
            _buildTimelineStep(
              indicator: _buildCompletedIndicator(),
              title: 'Position #5',
              subtitle: 'Waitlist processing',
              hasLineBelow: true,
              lineColor: const Color(0xFF1E3A34),
            ),
            _buildTimelineStep(
              indicator: _buildCurrentIndicator(),
              title: 'Position #3 (Current)',
              subtitle: '22 mins remaining',
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
            const SizedBox(height: 24),
          ],
        ),
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
