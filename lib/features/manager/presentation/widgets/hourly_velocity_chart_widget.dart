import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/models/manager_dashboard_model.dart';

class HourlyVelocityChartWidget extends StatelessWidget {
  final List<HourlyVelocityData> data;

  const HourlyVelocityChartWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final peakItem = data.firstWhere(
      (item) => item.isPeak,
      orElse: () => data.isNotEmpty
          ? data.reduce((a, b) => a.value >= b.value ? a : b)
          : const HourlyVelocityData(hour: '8 PM', value: 0.95, isPeak: true),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Hourly Floor Load & Turn Velocity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Peak: ${peakItem.hour}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final Color barColor = item.isPeak ? AppColors.accentOrange : AppColors.primary;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: item.value,
                          child: Container(
                            width: 22,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.hour,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
