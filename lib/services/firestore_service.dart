import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../features/manager/data/models/physical_table_model.dart';
import '../features/manager/data/models/live_menu_dish_model.dart';
import '../features/manager/data/models/manager_dashboard_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Helper to check if Supabase backend is attached
  bool get isLiveSupabaseProject {
    return _supabase != null;
  }

  // In-memory fallbacks for resilient UI operation
  final List<PhysicalTable> _fallbackTables = List<PhysicalTable>.from(PhysicalTable.mockList());
  final List<LiveMenuDish> _fallbackDishes = List<LiveMenuDish>.from(LiveMenuDish.mockList());

  final StreamController<List<PhysicalTable>> _tablesStreamController = StreamController<List<PhysicalTable>>.broadcast();
  final StreamController<List<LiveMenuDish>> _dishesStreamController = StreamController<List<LiveMenuDish>>.broadcast();
  final List<QueueEntryModel> _fallbackQueue = [
    QueueEntryModel(
      id: 'q1',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      guestName: 'Kamal Perera',
      partySize: 4,
      phoneNumber: '+94 77 123 4567',
      status: QueueStatus.waiting,
      queueNumber: 'Q-101',
      position: 1,
      estimatedWaitMinutes: 14,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    QueueEntryModel(
      id: 'q2',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
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
      guestName: 'Rohan De Silva',
      partySize: 6,
      phoneNumber: '+94 76 555 1234',
      status: QueueStatus.waiting,
      queueNumber: 'Q-103',
      position: 3,
      estimatedWaitMinutes: 22,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  final List<ReservationModel> _fallbackReservations = [];
  final StreamController<List<ReservationModel>> _reservationsStreamController = StreamController<List<ReservationModel>>.broadcast();

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
      tag: 'Japanese • Fine Dining',
      location: 'Colombo 03 • 0.8 km',
      rating: 4.9,
      reviewsCount: 820,
      isActive: true,
      isQueueAvailable: true,
      estWait: '25 min wait',
      waitlistCount: 5,
    ),
  ];

  // ==========================================
  // --- 1. RESTAURANTS SERVICES ---
  // ==========================================

  /// Stream of active restaurants
  Stream<List<RestaurantModel>> streamActiveRestaurants() {
    final client = _supabase;
    if (client == null) {
      return Stream.value(_fallbackRestaurants);
    }
    try {
      return client
          .from('restaurants')
          .stream(primaryKey: ['id'])
          .eq('is_active', true)
          .map((data) => data.map((item) => RestaurantModel.fromFirestore(item)).toList())
          .handleError((_) => _fallbackRestaurants);
    } catch (_) {
      return Stream.value(_fallbackRestaurants);
    }
  }

  /// Get active restaurants list snapshot
  Future<List<RestaurantModel>> getActiveRestaurants() async {
    final client = _supabase;
    if (client == null) {
      return _fallbackRestaurants;
    }
    try {
      final res = await client.from('restaurants').select().eq('is_active', true);
      if ((res as List).isEmpty) return _fallbackRestaurants;
      return res.map((item) => RestaurantModel.fromFirestore(item)).toList();
    } catch (_) {
      return _fallbackRestaurants;
    }
  }

  // ==========================================
  // --- 2. LIVE QUEUE SERVICES ---
  // ==========================================

  /// Realtime stream for a restaurant's queue
  Stream<List<QueueEntryModel>> streamQueue(String restaurantId) {
    final client = _supabase;
    if (client == null) {
      return Stream.value(_fallbackQueue.where((q) => q.status != QueueStatus.seated).toList());
    }
    try {
      return client
          .from('queue_entries')
          .stream(primaryKey: ['id'])
          .eq('restaurant_id', restaurantId)
          .order('position', ascending: true)
          .map((data) => data.map((item) => QueueEntryModel.fromFirestore(item)).toList())
          .handleError((_) => _fallbackQueue);
    } catch (_) {
      return Stream.value(_fallbackQueue);
    }
  }

  /// Join a restaurant's live queue
  Future<QueueEntryModel> joinQueue({
    required String restaurantId,
    required String restaurantName,
    String? userId,
    required String guestName,
    required int partySize,
    required String phoneNumber,
  }) async {
    final newId = 'q_${DateTime.now().millisecondsSinceEpoch}';
    final qNumber = 'Q-${100 + _fallbackQueue.length + 1}';
    final entry = QueueEntryModel(
      id: newId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: userId,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
      status: QueueStatus.waiting,
      queueNumber: qNumber,
      position: _fallbackQueue.where((q) => q.status == QueueStatus.waiting).length + 1,
      estimatedWaitMinutes: 15,
      createdAt: DateTime.now(),
    );

    _fallbackQueue.add(entry);

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('queue_entries').insert(entry.toFirestore());
        _updateRestaurantWaitlistCount(restaurantId);
      } catch (e) {
        debugPrint('Supabase joinQueue notice: $e');
      }
    }
    return entry;
  }

  /// Add walk-in guest to queue
  Future<QueueEntryModel> addWalkInGuest({
    required String restaurantId,
    required String restaurantName,
    required String guestName,
    required int partySize,
    required String phoneNumber,
  }) async {
    return joinQueue(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
    );
  }

  /// Stream active queue entry for a specific customer
  Stream<QueueEntryModel?> streamCustomerActiveQueue(String userId) {
    final client = _supabase;
    if (client == null) {
      try {
        final found = _fallbackQueue.firstWhere((q) => q.userId == userId && q.status != QueueStatus.seated);
        return Stream.value(found);
      } catch (_) {
        return Stream.value(null);
      }
    }
    try {
      return client
          .from('queue_entries')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
        if (data.isEmpty) return null;
        final active = data.where((item) => item['status'] != 'seated' && item['status'] != 'cancelled').toList();
        if (active.isEmpty) return null;
        return QueueEntryModel.fromFirestore(active.first);
      }).handleError((_) => null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Update queue status
  Future<void> updateQueueStatus(String queueId, QueueStatus status) async {
    final idx = _fallbackQueue.indexWhere((q) => q.id == queueId);
    if (idx != -1) {
      _fallbackQueue[idx] = _fallbackQueue[idx].copyWith(status: status);
      if (status == QueueStatus.seated || status == QueueStatus.cancelled) {
        _fallbackQueue.removeAt(idx);
      }
    }

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('queue_entries').update({
          'status': status.value,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', queueId);
      } catch (_) {}
    }
  }

  Future<void> _updateRestaurantWaitlistCount(String restaurantId) async {
    final client = _supabase;
    if (client == null) return;
    try {
      final activeRes = await client
          .from('queue_entries')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('status', 'waiting');

      final count = (activeRes as List).length;
      final estWaitStr = count == 0 ? 'Direct Seating' : '${count * 4} min wait';

      await client.from('restaurants').update({
        'waitlist_count': count,
        'est_wait': estWaitStr,
        'is_queue_available': true,
      }).eq('id', restaurantId);
    } catch (_) {}
  }

  // ==========================================
  // --- 3. PHYSICAL TABLES SERVICES ---
  // ==========================================

  /// Realtime stream for physical floor tables
  Stream<List<PhysicalTable>> streamTables({String restaurantId = 'ocean_bistro'}) {
    final client = _supabase;
    if (client == null) {
      Future.microtask(() => _tablesStreamController.add(List.from(_fallbackTables)));
      return _tablesStreamController.stream;
    }
    try {
      return client
          .from('tables')
          .stream(primaryKey: ['id'])
          .eq('restaurant_id', restaurantId)
          .map((data) {
        if (data.isEmpty) return _fallbackTables;
        final list = data.map((item) => PhysicalTable.fromFirestore(item)).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      }).handleError((_) => _fallbackTables);
    } catch (_) {
      Future.microtask(() => _tablesStreamController.add(List.from(_fallbackTables)));
      return _tablesStreamController.stream;
    }
  }

  /// Add new physical table
  Future<void> addTable(PhysicalTable table) async {
    _fallbackTables.add(table);
    _tablesStreamController.add(List.from(_fallbackTables));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('tables').upsert(table.toFirestore());
      } catch (_) {}
    }
  }

  /// Edit physical table
  Future<void> updateTable(PhysicalTable table) async {
    final idx = _fallbackTables.indexWhere((t) => t.id == table.id);
    if (idx != -1) {
      _fallbackTables[idx] = table;
    }
    _tablesStreamController.add(List.from(_fallbackTables));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('tables').upsert(table.toFirestore());
      } catch (_) {}
    }
  }

  /// Update table status
  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    final idx = _fallbackTables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      _fallbackTables[idx] = _fallbackTables[idx].copyWith(
        status: status,
        guestName: status == TableStatus.available ? 'No Guest' : _fallbackTables[idx].guestName,
      );
    }
    _tablesStreamController.add(List.from(_fallbackTables));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('tables').update({
          'status': status.value,
          'guest_name': status == TableStatus.available ? 'No Guest' : 'Occupied Guest',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', tableId);
      } catch (_) {}
    }
  }

  /// Delete physical table
  Future<void> deleteTable(String tableId) async {
    _fallbackTables.removeWhere((t) => t.id == tableId);
    _tablesStreamController.add(List.from(_fallbackTables));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('tables').delete().eq('id', tableId);
      } catch (_) {}
    }
  }

  // ==========================================
  // --- 4. LIVE MENU DISHES SERVICES ---
  // ==========================================

  /// Realtime stream for live menu dishes
  Stream<List<LiveMenuDish>> streamLiveMenu({String? restaurantId}) {
    final client = _supabase;
    if (client == null) {
      Future.microtask(() => _dishesStreamController.add(_getFilteredFallbackDishes(restaurantId)));
      return _dishesStreamController.stream;
    }
    try {
      return client
          .from('menu_items')
          .stream(primaryKey: ['id'])
          .map((data) {
        if (data.isEmpty) return _getFilteredFallbackDishes(restaurantId);
        var list = data.map((item) => LiveMenuDish.fromFirestore(item)).toList();
        if (restaurantId != null && restaurantId.isNotEmpty && restaurantId != 'All') {
          list = list.where((d) => d.restaurantId == restaurantId || d.restaurant.toLowerCase() == restaurantId.toLowerCase()).toList();
        }
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      }).handleError((_) => _getFilteredFallbackDishes(restaurantId));
    } catch (_) {
      Future.microtask(() => _dishesStreamController.add(_getFilteredFallbackDishes(restaurantId)));
      return _dishesStreamController.stream;
    }
  }

  List<LiveMenuDish> _getFilteredFallbackDishes(String? restaurantId) {
    if (restaurantId == null || restaurantId.isEmpty || restaurantId == 'All') {
      return List.from(_fallbackDishes);
    }
    return _fallbackDishes.where((d) => d.restaurant.toLowerCase() == restaurantId.toLowerCase() || d.restaurantId == restaurantId).toList();
  }

  /// Add new menu dish
  Future<void> addDish(LiveMenuDish dish) async {
    _fallbackDishes.add(dish);
    _dishesStreamController.add(_getFilteredFallbackDishes(dish.restaurantId));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('menu_items').upsert(dish.toFirestore());
      } catch (_) {}
    }
  }

  /// Edit menu dish
  Future<void> updateDish(LiveMenuDish dish) async {
    final idx = _fallbackDishes.indexWhere((d) => d.id == dish.id);
    if (idx != -1) {
      _fallbackDishes[idx] = dish;
    }
    _dishesStreamController.add(_getFilteredFallbackDishes(dish.restaurantId));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('menu_items').upsert(dish.toFirestore());
      } catch (_) {}
    }
  }

  /// Toggle availability (86'd status)
  Future<void> toggleDishAvailability(String dishId, bool isAvailable) async {
    final idx = _fallbackDishes.indexWhere((d) => d.id == dishId);
    if (idx != -1) {
      _fallbackDishes[idx] = _fallbackDishes[idx].copyWith(isAvailable: isAvailable);
    }
    _dishesStreamController.add(_getFilteredFallbackDishes(null));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('menu_items').update({
          'is_available': isAvailable,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', dishId);
      } catch (_) {}
    }
  }

  /// Delete menu dish
  Future<void> deleteDish(String dishId) async {
    _fallbackDishes.removeWhere((d) => d.id == dishId);
    _dishesStreamController.add(_getFilteredFallbackDishes(null));
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('menu_items').delete().eq('id', dishId);
      } catch (_) {}
    }
  }

  // ==========================================
  // --- 5. RESERVATIONS SERVICES ---
  // ==========================================

  /// Stream of user reservations
  Stream<List<ReservationModel>> streamUserReservations(String userId) {
    final client = _supabase;
    if (client == null) {
      return Stream.value(_fallbackReservations.where((r) => r.userId == userId).toList());
    }
    try {
      return client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) => data.map((item) => ReservationModel.fromFirestore(item)).toList())
          .handleError((_) => _fallbackReservations.where((r) => r.userId == userId).toList());
    } catch (_) {
      return Stream.value(_fallbackReservations.where((r) => r.userId == userId).toList());
    }
  }

  /// Create reservation
  Future<ReservationModel> createReservation(ReservationModel reservation) async {
    final item = ReservationModel(
      id: reservation.id.isNotEmpty ? reservation.id : 'rsv_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: reservation.restaurantId,
      restaurantName: reservation.restaurantName,
      userId: reservation.userId,
      guestName: reservation.guestName,
      reservationCode: reservation.reservationCode.isNotEmpty
          ? reservation.reservationCode
          : '#RSV${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: reservation.date,
      time: reservation.time,
      partySize: reservation.partySize,
      status: 'confirmed',
      specialNotes: reservation.specialNotes,
      createdAt: reservation.createdAt ?? DateTime.now(),
    );

    final existingIdx = _fallbackReservations.indexWhere((r) => r.id == item.id);
    if (existingIdx != -1) {
      _fallbackReservations[existingIdx] = item;
    } else {
      _fallbackReservations.insert(0, item);
    }
    _reservationsStreamController.add(List.from(_fallbackReservations));

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('reservations').insert(item.toFirestore());
      } catch (_) {}
    }
    return item;
  }

  /// Update an existing reservation
  Future<void> updateReservation(ReservationModel reservation) async {
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('reservations').upsert(reservation.toFirestore());
      } catch (_) {}
    }
  }

  /// Cancel reservation
  Future<void> cancelReservation(String reservationId) async {
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('reservations').update({'status': 'cancelled'}).eq('id', reservationId);
      } catch (_) {}
    }
  }

  /// Leave queue
  Future<void> leaveQueue({String? queueId, String? restaurantId}) async {
    if (queueId != null && queueId.isNotEmpty) {
      await updateQueueStatus(queueId, QueueStatus.cancelled);
    }
  }

  /// Stream total bookings count for Manager Dashboard
  Stream<int> streamTotalBookingsCount({String restaurantId = 'ocean_bistro', bool isThisWeek = false}) {
    final client = _supabase;
    if (client == null) {
      final base = isThisWeek ? 195 : 42;
      return Stream.value(base + _fallbackQueue.length);
    }
    try {
      return client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .eq('restaurant_id', restaurantId)
          .map((data) {
        final resCount = data.length;
        final queueCount = _fallbackQueue.length;
        return resCount + queueCount + (isThisWeek ? 150 : 25);
      }).handleError((_) => isThisWeek ? 195 : 42);
    } catch (_) {
      return Stream.value(isThisWeek ? 195 : 42);
    }
  }

  /// Realtime stream for hourly floor load & turn velocity
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

  // ==========================================
  // --- 6. SEED INITIAL DATA IF EMPTY ---
  // ==========================================

  Future<void> seedInitialDataIfEmpty() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final restaurants = await client.from('restaurants').select().limit(1);
      if ((restaurants as List).isEmpty) {
        for (var r in _fallbackRestaurants) {
          await client.from('restaurants').upsert(r.toFirestore());
        }
      }

      final tables = await client.from('tables').select().limit(1);
      if ((tables as List).isEmpty) {
        for (var t in _fallbackTables) {
          await client.from('tables').upsert(t.toFirestore());
        }
      }

      final menu = await client.from('menu_items').select().limit(1);
      if ((menu as List).isEmpty) {
        for (var d in _fallbackDishes) {
          await client.from('menu_items').upsert(d.toFirestore());
        }
      }

      final queue = await client.from('queue_entries').select().limit(1);
      if ((queue as List).isEmpty) {
        for (var q in _fallbackQueue) {
          await client.from('queue_entries').upsert(q.toFirestore());
        }
      }
    } catch (_) {}
  }
}
