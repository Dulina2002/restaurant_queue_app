import '../../../../models/queue_entry_model.dart';
import '../../../../models/reservation_model.dart';
import 'physical_table_model.dart';

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

/// A point-in-time view of everything the manager Overview tab needs for ONE
/// restaurant, built entirely from live database rows (tables, queue entries
/// and reservations). All KPI figures are derived here so the numbers always
/// match the data shown in the Tables tab and receptionist screens.
class ManagerLiveSnapshot {
  final List<PhysicalTable> tables;

  /// Every queue entry for the restaurant, including seated / cancelled ones.
  final List<QueueEntryModel> queue;

  /// Non-cancelled reservations for the restaurant.
  final List<ReservationModel> reservations;

  const ManagerLiveSnapshot({
    required this.tables,
    required this.queue,
    required this.reservations,
  });

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Opening-hour windows used by the hourly chart (each covers two hours).
  static const _slotStarts = [11, 13, 15, 17, 19, 21];
  static const _slotLabels = ['11 AM', '1 PM', '3 PM', '5 PM', '7 PM', '9 PM'];

  // ---- Floor ----

  int get totalTables => tables.length;

  int get availableTables => tables.where((t) => t.status == TableStatus.available).length;

  String get availableTablesRatio => '$availableTables / $totalTables';

  // ---- Queue ----

  List<QueueEntryModel> get activeQueue =>
      queue.where((q) => q.status == QueueStatus.waiting || q.status == QueueStatus.called).toList();

  /// Average estimated wait of parties currently waiting (0 when nobody waits).
  int get avgQueueWaitMinutes {
    final active = activeQueue;
    if (active.isEmpty) return 0;
    final total = active.fold<int>(0, (sum, q) => sum + q.estimatedWaitMinutes);
    return (total / active.length).round();
  }

  // ---- Period helpers ----

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// True when [date] falls today (or inside the current Monday-Sunday week).
  static bool _inPeriod(DateTime? date, {required bool isWeek, required DateTime now}) {
    if (date == null) return false;
    final today = _startOfDay(now);
    final day = _startOfDay(date);
    if (!isWeek) return day == today;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !day.isBefore(weekStart) && day.isBefore(weekEnd);
  }

  /// Parses customer reservation dates such as "Wednesday, 7 October".
  /// The stored string has no year, so the year closest to [now] is used.
  static DateTime? parseReservationDate(String text, DateTime now) {
    final match = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})').firstMatch(text);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = _months[match.group(2)!.toLowerCase()];
    if (day == null || month == null) return null;
    var best = DateTime(now.year, month, day);
    for (final year in [now.year - 1, now.year + 1]) {
      final candidate = DateTime(year, month, day);
      if (candidate.difference(now).abs() < best.difference(now).abs()) best = candidate;
    }
    return best;
  }

  /// Parses reservation times such as "6:10 PM" into a 24h hour.
  static int? parseReservationHour(String text) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(text);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    if (hour == null) return null;
    final meridiem = match.group(3)?.toLowerCase();
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return hour;
  }

  // ---- Period KPIs ----

  List<ReservationModel> _reservationsIn(bool isWeek, DateTime now) => reservations
      .where((r) => _inPeriod(parseReservationDate(r.date, now), isWeek: isWeek, now: now))
      .toList();

  List<QueueEntryModel> _queueJoinedIn(bool isWeek, DateTime now) => queue
      .where((q) => q.status != QueueStatus.cancelled && _inPeriod(q.createdAt, isWeek: isWeek, now: now))
      .toList();

  /// Reservations dated in the period plus queue tickets issued in the period.
  int totalBookings({required bool isWeek, DateTime? now}) {
    final ref = now ?? DateTime.now();
    return _reservationsIn(isWeek, ref).length + _queueJoinedIn(isWeek, ref).length;
  }

  /// Parties seated during the period divided by the number of tables.
  String floorTurnover({required bool isWeek, DateTime? now}) {
    final ref = now ?? DateTime.now();
    if (totalTables == 0) return '0.0x';
    final seated = queue
        .where((q) =>
            q.status == QueueStatus.seated &&
            _inPeriod(q.updatedAt ?? q.createdAt, isWeek: isWeek, now: ref))
        .length;
    return '${(seated / totalTables).toStringAsFixed(1)}x';
  }

  /// Demand per two-hour window built from queue tickets and reservations.
  List<HourlyVelocityData> hourlyVelocity({required bool isWeek, DateTime? now}) {
    final ref = now ?? DateTime.now();
    final counts = List<int>.filled(_slotStarts.length, 0);

    void bump(int hour) {
      var idx = ((hour - _slotStarts.first) ~/ 2).clamp(0, _slotStarts.length - 1);
      if (hour < _slotStarts.first) idx = 0;
      counts[idx]++;
    }

    for (final q in _queueJoinedIn(isWeek, ref)) {
      bump(q.createdAt!.hour);
    }
    for (final r in _reservationsIn(isWeek, ref)) {
      final hour = parseReservationHour(r.time);
      if (hour != null) bump(hour);
    }

    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);
    final peakIndex = maxCount == 0 ? -1 : counts.indexOf(maxCount);
    return List.generate(_slotStarts.length, (i) {
      final value = maxCount == 0 ? 0.06 : (counts[i] / maxCount).clamp(0.06, 1.0).toDouble();
      return HourlyVelocityData(hour: _slotLabels[i], value: value, isPeak: i == peakIndex);
    });
  }
}
