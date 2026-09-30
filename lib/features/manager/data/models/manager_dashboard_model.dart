class HourlyVelocityData {
  final String hour;
  final double value;
  final bool isPeak;

  const HourlyVelocityData({
    required this.hour,
    required this.value,
    this.isPeak = false,
  });
}

class ManagerDashboardData {
  final String totalBookings;
  final String floorTurnover;
  final String avgQueueWait;
  final String activeTables;
  final List<HourlyVelocityData> hourlyVelocity;

  const ManagerDashboardData({
    required this.totalBookings,
    required this.floorTurnover,
    required this.avgQueueWait,
    required this.activeTables,
    required this.hourlyVelocity,
  });

  /// Initial sample data matching the Stitch UI design mock
  factory ManagerDashboardData.mock() {
    return const ManagerDashboardData(
      totalBookings: '196',
      floorTurnover: '3.8x',
      avgQueueWait: '36 min',
      activeTables: '5/12',
      hourlyVelocity: [
        HourlyVelocityData(hour: '12 PM', value: 0.45),
        HourlyVelocityData(hour: '1 PM', value: 0.70),
        HourlyVelocityData(hour: '2 PM', value: 0.35),
        HourlyVelocityData(hour: '7 PM', value: 0.85, isPeak: false),
        HourlyVelocityData(hour: '8 PM', value: 0.95, isPeak: true),
        HourlyVelocityData(hour: '9 PM', value: 0.65),
      ],
    );
  }
}
