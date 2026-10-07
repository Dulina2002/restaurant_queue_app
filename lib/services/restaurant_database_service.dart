import 'dart:async';
import '../models/restaurant_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../features/manager/data/models/physical_table_model.dart';
import '../features/manager/data/models/live_menu_dish_model.dart';
import '../features/manager/data/models/manager_dashboard_model.dart';
import 'supabase_service.dart';

class RestaurantDatabaseService {
  static final RestaurantDatabaseService _instance = RestaurantDatabaseService._internal();
  factory RestaurantDatabaseService() => _instance;
  RestaurantDatabaseService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  // In-memory fallbacks for resilient UI operation
  final List<PhysicalTable> _fallbackTables = List<PhysicalTable>.from(PhysicalTable.mockList());
  final List<LiveMenuDish> _fallbackDishes = List<LiveMenuDish>.from(LiveMenuDish.mockList());

  final StreamController<List<PhysicalTable>> _tablesStreamController = StreamController<List<PhysicalTable>>.broadcast();
  final StreamController<List<LiveMenuDish>> _dishesStreamController = StreamController<List<LiveMenuDish>>.broadcast();
  final StreamController<List<QueueEntryModel>> _queueStreamController = StreamController<List<QueueEntryModel>>.broadcast();

  final List<QueueEntryModel> _fallbackQueue = [
    QueueEntryModel(
      id: 'q1',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_kamal',
      guestName: 'Kamal Perera',
      partySize: 4,
      phoneNumber: '+94 77 123 4567',
      status: QueueStatus.waiting,
      queueNumber: 'Q-101',
      position: 1,
      estimatedWaitMinutes: 5,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    QueueEntryModel(
      id: 'q2',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_sarah',
      guestName: 'Sarah Jenkins',
      partySize: 2,
      phoneNumber: '+94 71 987 6543',
      status: QueueStatus.called,
      queueNumber: 'Q-102',
      position: 2,
      estimatedWaitMinutes: 8,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    QueueEntryModel(
      id: 'q3',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_rohan',
      guestName: 'Rohan De Silva',
      partySize: 6,
      phoneNumber: '+94 76 555 1234',
      status: QueueStatus.waiting,
      queueNumber: 'Q-103',
      position: 3,
      estimatedWaitMinutes: 15,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  final List<RestaurantModel> _fallbackRestaurants = [
    const RestaurantModel(
      id: 'ocean_bistro',
      name: 'Ocean Bistro',
      cuisine: 'Italian',
      tag: 'Italian • Seafood',
      location: 'Colombo 03 • 1.2 km',
      rating: 4.8,
      reviewsCount: 342,
      isActive: true,
      isQueueAvailable: true,
      estWait: '12 min wait',
      waitlistCount: 3,
    ),
    const RestaurantModel(
      id: 'mango_tree',
      name: 'The Mango Tree',
      cuisine: 'Indian',
      tag: 'Indian • North Indian',
      location: 'Colombo 07 • 2.1 km',
      rating: 4.8,
      reviewsCount: 512,
      isActive: true,
      isQueueAvailable: false,
      estWait: 'Direct Seating',
      waitlistCount: 0,
    ),
    const RestaurantModel(
      id: 'nihonbashi',
      name: 'Nihonbashi',
      cuisine: 'Japanese',
      tag: 'Japanese • Sushi & Robata',
      location: 'Colombo 03 • 3.4 km',
      rating: 4.9,
      reviewsCount: 620,
      isActive: true,
      isQueueAvailable: true,
      estWait: '20 min wait',
      waitlistCount: 5,
    ),
  ];

  // ==========================================
  // --- 1. RESTAURANTS ---
  // ==========================================

  Stream<List<RestaurantModel>> streamActiveRestaurants() {
    return _supabaseService.streamActiveRestaurants();
  }

  Future<List<RestaurantModel>> getActiveRestaurants() async {
    return _fallbackRestaurants;
  }

  Future<RestaurantModel?> getRestaurant(String id) async {
    try {
      return _fallbackRestaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // --- 2. LIVE QUEUE ---
  // ==========================================

  Stream<List<QueueEntryModel>> streamQueue(String restaurantId) async* {
    List<QueueEntryModel> filter(List<QueueEntryModel> list) {
      return list.where((q) => (q.restaurantId == restaurantId || restaurantId == 'ocean_bistro') && q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList();
    }

    yield filter(_fallbackQueue);

    await for (final list in _queueStreamController.stream) {
      yield filter(list);
    }
  }

  Stream<List<QueueEntryModel>> streamActiveQueue({String restaurantId = 'ocean_bistro'}) {
    return streamQueue(restaurantId);
  }

  Stream<QueueEntryModel?> streamCustomerActiveQueue(String userId) {
    return _supabaseService.streamCustomerActiveQueue(userId);
  }

  Stream<List<QueueEntryModel>> streamAllQueueEntries({String restaurantId = 'ocean_bistro'}) async* {
    List<QueueEntryModel> filter(List<QueueEntryModel> list) {
      return list.where((q) => q.restaurantId == restaurantId || restaurantId == 'ocean_bistro').toList();
    }

    yield filter(_fallbackQueue);

    await for (final list in _queueStreamController.stream) {
      yield filter(list);
    }
  }

  Future<QueueEntryModel> joinQueue({
    required String restaurantId,
    required String restaurantName,
    required String userId,
    required String guestName,
    required int partySize,
    required String phoneNumber,
  }) async {
    final entry = await _supabaseService.joinQueue(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: userId,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
    );

    final idx = _fallbackQueue.indexWhere((q) => q.id == entry.id);
    if (idx != -1) {
      _fallbackQueue[idx] = entry;
    } else {
      _fallbackQueue.add(entry);
    }
    _queueStreamController.add(List.from(_fallbackQueue));

    return entry;
  }

  Future<QueueEntryModel> walkInQueue({
    required String guestName,
    required int partySize,
    required String phoneNumber,
    String restaurantId = 'ocean_bistro',
    String restaurantName = 'Ocean Bistro',
  }) async {
    return joinQueue(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: 'walk_in_${DateTime.now().millisecondsSinceEpoch}',
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> updateQueueStatus(
    String queueId,
    QueueStatus status, {
    String restaurantId = 'ocean_bistro',
  }) async {
    final idx = _fallbackQueue.indexWhere((q) => q.id == queueId);
    if (idx != -1) {
      _fallbackQueue[idx] = _fallbackQueue[idx].copyWith(status: status);
      _queueStreamController.add(List.from(_fallbackQueue));
    }
  }

  Future<void> leaveQueue({required String queueId, required String restaurantId}) async {
    _fallbackQueue.removeWhere((q) => q.id == queueId);
    _queueStreamController.add(List.from(_fallbackQueue));
    await _supabaseService.leaveQueue(queueId: queueId, restaurantId: restaurantId);
  }

  // ==========================================
  // --- 3. TABLES MANAGEMENT ---
  // ==========================================

  Stream<List<PhysicalTable>> streamTables({String restaurantId = 'All'}) async* {
    List<PhysicalTable> filter(List<PhysicalTable> list) {
      if (restaurantId == 'All' || restaurantId.isEmpty) {
        return list;
      }
      final lower = restaurantId.toLowerCase();
      String targetId = lower.contains('ocean')
          ? 'ocean_bistro'
          : lower.contains('mango')
              ? 'mango_tree'
              : lower.contains('nihon')
                  ? 'nihonbashi'
                  : restaurantId;
      return list.where((t) => t.restaurantId == restaurantId || t.restaurantId == targetId).toList();
    }

    yield filter(_fallbackTables);

    await for (final list in _tablesStreamController.stream) {
      yield filter(list);
    }
  }

  Future<List<PhysicalTable>> getTables({String restaurantId = 'ocean_bistro'}) async {
    return _fallbackTables.where((t) => t.restaurantId == restaurantId).toList();
  }

  Future<PhysicalTable> addTable(PhysicalTable table) async {
    final newTable = table.copyWith(id: table.id.isEmpty ? 'tbl_${DateTime.now().millisecondsSinceEpoch}' : table.id);
    final idx = _fallbackTables.indexWhere((t) => t.id == newTable.id);
    if (idx != -1) {
      _fallbackTables[idx] = newTable;
    } else {
      _fallbackTables.add(newTable);
    }
    _tablesStreamController.add(List.from(_fallbackTables));
    await _supabaseService.addTable(newTable);
    return newTable;
  }

  Future<PhysicalTable> updateTable(PhysicalTable table) async {
    final idx = _fallbackTables.indexWhere((t) => t.id == table.id);
    if (idx != -1) {
      _fallbackTables[idx] = table;
      _tablesStreamController.add(List.from(_fallbackTables));
    }
    await _supabaseService.updateTable(table);
    return table;
  }

  Future<void> deleteTable(String id) async {
    _fallbackTables.removeWhere((t) => t.id == id);
    _tablesStreamController.add(List.from(_fallbackTables));
    await _supabaseService.deleteTable(id);
  }

  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    final idx = _fallbackTables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      _fallbackTables[idx] = _fallbackTables[idx].copyWith(
        status: status,
        guestName: status == TableStatus.available ? 'No Guest' : _fallbackTables[idx].guestName,
      );
      _tablesStreamController.add(List.from(_fallbackTables));
    }
  }

  /// Seat a specific guest at a physical table
  Future<void> seatGuestAtTable({
    required String tableId,
    required String guestName,
    String? queueId,
  }) async {
    final idx = _fallbackTables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      _fallbackTables[idx] = _fallbackTables[idx].copyWith(
        status: TableStatus.occupied,
        guestName: guestName,
      );
      _tablesStreamController.add(List.from(_fallbackTables));
    }

    if (queueId != null && queueId.isNotEmpty) {
      await updateQueueStatus(queueId, QueueStatus.seated);
    }
  }

  /// Seat the next waiting queue party at the specified table
  Future<QueueEntryModel?> seatNextQueueParty({required String tableId}) async {
    final waitingParties = _fallbackQueue.where((q) => q.status == QueueStatus.waiting || q.status == QueueStatus.called).toList();
    if (waitingParties.isEmpty) return null;

    final partyToSeat = waitingParties.first;
    await seatGuestAtTable(
      tableId: tableId,
      guestName: partyToSeat.guestName,
      queueId: partyToSeat.id,
    );
    return partyToSeat;
  }

  /// Bulk turn specified tables to available
  Future<void> bulkQuickTurnTables(List<String> tableIds) async {
    for (final id in tableIds) {
      final idx = _fallbackTables.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _fallbackTables[idx] = _fallbackTables[idx].copyWith(
          status: TableStatus.available,
          guestName: 'No Guest',
        );
      }
    }
    _tablesStreamController.add(List.from(_fallbackTables));
  }

  // ==========================================
  // --- 4. LIVE MENU DISHES ---
  // ==========================================

  Stream<List<LiveMenuDish>> streamLiveMenu({String restaurantId = 'All'}) async* {
    List<LiveMenuDish> filter(List<LiveMenuDish> list) {
      if (restaurantId == 'All' || restaurantId.isEmpty) {
        return list;
      }
      return list.where((d) => d.restaurantId == restaurantId || d.restaurant == restaurantId).toList();
    }

    yield filter(_fallbackDishes);

    await for (final list in _dishesStreamController.stream) {
      yield filter(list);
    }
  }

  Future<LiveMenuDish> addMenuItem(LiveMenuDish dish) async {
    final newDish = dish.copyWith(id: dish.id.isEmpty ? 'dish_${DateTime.now().millisecondsSinceEpoch}' : dish.id);
    final idx = _fallbackDishes.indexWhere((d) => d.id == newDish.id);
    if (idx != -1) {
      _fallbackDishes[idx] = newDish;
    } else {
      _fallbackDishes.add(newDish);
    }
    _dishesStreamController.add(List.from(_fallbackDishes));
    await _supabaseService.addMenuItem(newDish);
    return newDish;
  }

  Future<LiveMenuDish> addDish(LiveMenuDish dish) => addMenuItem(dish);

  Future<LiveMenuDish> updateMenuItem(LiveMenuDish dish) async {
    final idx = _fallbackDishes.indexWhere((d) => d.id == dish.id);
    if (idx != -1) {
      _fallbackDishes[idx] = dish;
      _dishesStreamController.add(List.from(_fallbackDishes));
    }
    await _supabaseService.updateMenuItem(dish);
    return dish;
  }

  Future<LiveMenuDish> updateDish(LiveMenuDish dish) => updateMenuItem(dish);

  Future<void> deleteMenuItem(String id) async {
    _fallbackDishes.removeWhere((d) => d.id == id);
    _dishesStreamController.add(List.from(_fallbackDishes));
    await _supabaseService.deleteMenuItem(id);
  }

  Future<void> deleteDish(String id) => deleteMenuItem(id);

  Future<void> toggleDishAvailability(String id, bool currentStatus) async {
    final idx = _fallbackDishes.indexWhere((d) => d.id == id);
    if (idx != -1) {
      _fallbackDishes[idx] = _fallbackDishes[idx].copyWith(isAvailable: !currentStatus);
      _dishesStreamController.add(List.from(_fallbackDishes));
    }
    await _supabaseService.toggleDishAvailability(id, currentStatus);
  }

  // ==========================================
  // --- 5. RESERVATIONS ---
  // ==========================================

  Stream<List<ReservationModel>> streamReservations({String restaurantId = 'ocean_bistro'}) {
    return _supabaseService.streamRestaurantReservations(restaurantId);
  }

  Stream<List<ReservationModel>> streamUserReservations(String userId) {
    return _supabaseService.streamUserReservations(userId);
  }

  Future<ReservationModel> createReservation(ReservationModel reservation) async {
    return await _supabaseService.createReservation(reservation);
  }

  Future<void> cancelReservation(String reservationId) async {
    await _supabaseService.cancelReservation(reservationId);
  }

  Future<ReservationModel> updateReservation(ReservationModel reservation) async {
    return await _supabaseService.updateReservation(reservation);
  }

  Stream<int> streamTotalBookingsCount({String restaurantId = 'ocean_bistro', bool isThisWeek = false}) {
    final base = isThisWeek ? 195 : 42;
    return Stream.value(base + _fallbackQueue.length);
  }

  Stream<List<HourlyVelocityData>> streamHourlyVelocity({String restaurantId = 'ocean_bistro'}) {
    return streamQueue(restaurantId).map((queueList) {
      if (queueList.isEmpty) {
        return ManagerDashboardData.mock().hourlyVelocity;
      }

      final slots = ['12 PM', '1 PM', '2 PM', '7 PM', '8 PM', '9 PM'];
      final Map<String, int> counts = {for (var s in slots) s: 0};

      for (final q in queueList) {
        final hour = q.createdAt?.hour ?? 12;
        if (hour == 12) {
          counts['12 PM'] = counts['12 PM']! + 1;
        } else if (hour == 13) {
          counts['1 PM'] = counts['1 PM']! + 1;
        } else if (hour == 14) {
          counts['2 PM'] = counts['2 PM']! + 1;
        } else if (hour == 19) {
          counts['7 PM'] = counts['7 PM']! + 1;
        } else if (hour == 20) {
          counts['8 PM'] = counts['8 PM']! + 1;
        } else if (hour == 21) {
          counts['9 PM'] = counts['9 PM']! + 1;
        }
      }

      final maxVal = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
      if (maxVal == 0) {
        return ManagerDashboardData.mock().hourlyVelocity;
      }

      String maxHour = '8 PM';
      int maxCount = -1;
      counts.forEach((hour, valCount) {
        if (valCount > maxCount) {
          maxCount = valCount;
          maxHour = hour;
        }
      });

      return slots.map((hour) {
        final c = counts[hour] ?? 0;
        final val = c == 0 ? 0.25 : (c / maxVal).clamp(0.25, 1.0);
        return HourlyVelocityData(
          hour: hour,
          value: val,
          isPeak: hour == maxHour && c > 0,
        );
      }).toList();
    });
  }

  Future<void> seedInitialDataIfEmpty() async {
    // Initial data is handled by Supabase / in-memory fallbacks
  }
}

// Backward compatibility alias for any un-updated references
typedef FirestoreService = RestaurantDatabaseService;
