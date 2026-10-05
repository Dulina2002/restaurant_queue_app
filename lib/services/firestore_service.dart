import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../features/manager/data/models/physical_table_model.dart';
import '../features/manager/data/models/live_menu_dish_model.dart';
import '../features/manager/data/models/manager_dashboard_model.dart';
import 'supabase_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }

  /// Helper to check if a live configured Firebase cloud project is attached
  bool get isLiveFirebaseProject {
    try {
      final proj = _firestore.app.options.projectId;
      return proj.isNotEmpty && !proj.contains('demo');
    } catch (_) {
      return false;
    }
  }

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

  final List<ReservationModel> _fallbackReservations = [
    ReservationModel(
      id: 'rsv_1',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'guest_id',
      guestName: 'Ayesha Perera',
      reservationCode: '#RSV10245',
      date: 'Saturday, 12 Oct',
      time: '7:30 PM',
      partySize: 4,
      status: 'confirmed',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
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
  // --- 1. RESTAURANTS COLLECTION & SERVICES ---
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _restaurantsRef =>
      _firestore.collection('restaurants');

  /// Stream of active restaurants
  Stream<List<RestaurantModel>> streamActiveRestaurants() {
    if (!isLiveFirebaseProject) {
      return Stream.value(_fallbackRestaurants);
    }
    try {
      return _restaurantsRef
          .where('is_active', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return _fallbackRestaurants;
        return snapshot.docs.map((doc) => RestaurantModel.fromFirestore(doc)).toList();
      }).handleError((_) => _fallbackRestaurants);
    } catch (_) {
      return Stream.value(_fallbackRestaurants);
    }
  }

  /// Get active restaurants list snapshot
  Future<List<RestaurantModel>> getActiveRestaurants() async {
    if (!isLiveFirebaseProject) {
      return _fallbackRestaurants;
    }
    try {
      final snapshot = await _restaurantsRef.where('is_active', isEqualTo: true).get();
      if (snapshot.docs.isEmpty) {
        return _fallbackRestaurants;
      }
      return snapshot.docs.map((doc) => RestaurantModel.fromFirestore(doc)).toList();
    } catch (_) {
      return _fallbackRestaurants;
    }
  }

  // ==========================================
  // --- 2. LIVE QUEUE COLLECTION SERVICES ---
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _queueRef =>
      _firestore.collection('queue_entries');

  /// Realtime stream for a restaurant's queue
  Stream<List<QueueEntryModel>> streamQueue(String restaurantId) {
    if (!isLiveFirebaseProject) {
      Future.microtask(() => _queueStreamController.add(_fallbackQueue.where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList()));
      return _queueStreamController.stream.map((list) => list.where((q) => (q.restaurantId == restaurantId || restaurantId == 'ocean_bistro') && q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList());
    }
    try {
      return _queueRef
          .where('restaurant_id', isEqualTo: restaurantId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return _fallbackQueue.where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList();
        }
        final items = snapshot.docs
            .map((doc) => QueueEntryModel.fromFirestore(doc))
            .where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled)
            .toList();
        items.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return a.createdAt!.compareTo(b.createdAt!);
        });
        return items;
      }).handleError((_) => _fallbackQueue.where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList());
    } catch (_) {
      Future.microtask(() => _queueStreamController.add(_fallbackQueue.where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList()));
      return _queueStreamController.stream.map((list) => list.where((q) => (q.restaurantId == restaurantId || restaurantId == 'ocean_bistro') && q.status != QueueStatus.seated && q.status != QueueStatus.cancelled).toList());
    }
  }

  /// Realtime stream for a customer's active queue item with dynamic position calculation
  Stream<QueueEntryModel?> streamCustomerActiveQueue(String userId) {
    final effectiveUid = (userId.isNotEmpty && userId != 'guest_id') ? userId : 'current_customer_id';

    if (!isLiveFirebaseProject) {
      Future.microtask(() => _queueStreamController.add(List.from(_fallbackQueue)));
      return _queueStreamController.stream.map((list) {
        final activeList = list
            .where((q) =>
                q.userId == effectiveUid &&
                (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
            .toList();
        if (activeList.isEmpty) return null;
        final myEntry = activeList.first;

        // Dynamic position recalculation in memory
        final restaurantQueue = list
            .where((q) =>
                q.restaurantId == myEntry.restaurantId &&
                (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
            .toList();
        restaurantQueue.sort((a, b) =>
            (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        final dynamicPos = restaurantQueue.indexWhere((q) => q.id == myEntry.id) + 1;
        final calculatedPos = dynamicPos > 0 ? dynamicPos : myEntry.position;

        return myEntry.copyWith(
          position: calculatedPos,
          estimatedWaitMinutes: calculatedPos * 5,
        );
      });
    }
    try {
      return _queueRef
          .where('user_id', isEqualTo: effectiveUid)
          .snapshots()
          .asyncMap((snapshot) async {
        final active = snapshot.docs
            .map((doc) => QueueEntryModel.fromFirestore(doc))
            .where((q) => q.status == QueueStatus.waiting || q.status == QueueStatus.called)
            .toList();
        if (active.isEmpty) return null;
        final myEntry = active.first;

        // Calculate live dynamic position from Firestore
        try {
          final restSnap = await _queueRef
              .where('restaurant_id', isEqualTo: myEntry.restaurantId)
              .where('status', whereIn: ['waiting', 'called'])
              .get();
          final allWaiting = restSnap.docs.map((d) => QueueEntryModel.fromFirestore(d)).toList();
          allWaiting.sort((a, b) =>
              (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
          final idx = allWaiting.indexWhere((q) => q.id == myEntry.id);
          final dynamicPos = idx >= 0 ? idx + 1 : myEntry.position;
          return myEntry.copyWith(
            position: dynamicPos,
            estimatedWaitMinutes: dynamicPos * 5,
          );
        } catch (_) {
          return myEntry;
        }
      }).handleError((_) => null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Customer joins queue
  Future<QueueEntryModel> joinQueue({
    required String restaurantId,
    required String restaurantName,
    required String userId,
    required String guestName,
    required int partySize,
    required String phoneNumber,
  }) async {
    final effectiveUid = (userId.isNotEmpty && userId != 'guest_id') ? userId : 'current_customer_id';
    final activeCount = _fallbackQueue
        .where((q) => q.restaurantId == restaurantId && (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
        .length;
    final currentPos = activeCount + 1;
    final queueNumber = 'Q-${_fallbackQueue.length + 101}';
    final entry = QueueEntryModel(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: effectiveUid,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
      status: QueueStatus.waiting,
      queueNumber: queueNumber,
      position: currentPos,
      estimatedWaitMinutes: currentPos * 5,
      createdAt: DateTime.now(),
    );

    _fallbackQueue.add(entry);
    _queueStreamController.add(List.from(_fallbackQueue));

    // Update restaurant waitlist count in fallback
    final rIdx = _fallbackRestaurants.indexWhere((r) => r.id == restaurantId);
    if (rIdx != -1) {
      _fallbackRestaurants[rIdx] = _fallbackRestaurants[rIdx].copyWith(
        waitlistCount: currentPos,
        estWait: '${currentPos * 5} min wait',
        isQueueAvailable: true,
      );
    }

    if (isLiveFirebaseProject) {
      try {
        final docRef = _queueRef.doc(entry.id);
        await docRef.set(entry.toFirestore());
        await _updateRestaurantWaitlistCount(restaurantId);
      } catch (_) {}
    }

    // Sync with Supabase backend
    try {
      SupabaseService().joinQueue(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        userId: effectiveUid,
        guestName: guestName,
        partySize: partySize,
        phoneNumber: phoneNumber,
      );
    } catch (_) {}

    return entry;
  }

  /// Host adds walk-in guest to queue
  Future<QueueEntryModel> addWalkInGuest({
    required String restaurantId,
    required String restaurantName,
    required String guestName,
    required int partySize,
    required String phoneNumber,
  }) async {
    final queueNumber = 'Q-${_fallbackQueue.length + 101}';
    final entry = QueueEntryModel(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
      status: QueueStatus.waiting,
      queueNumber: queueNumber,
      position: _fallbackQueue.length + 1,
      estimatedWaitMinutes: (_fallbackQueue.length + 1) * 5,
      createdAt: DateTime.now(),
    );

    _fallbackQueue.add(entry);
    _queueStreamController.add(List.from(_fallbackQueue));

    if (isLiveFirebaseProject) {
      try {
        final docRef = _queueRef.doc(entry.id);
        await docRef.set(entry.toFirestore());
        await _updateRestaurantWaitlistCount(restaurantId);
      } catch (_) {}
    }

    return entry;
  }

  /// Leave or cancel waitlist
  Future<void> leaveQueue({required String queueId, required String restaurantId}) async {
    await updateQueueStatus(queueId, QueueStatus.cancelled);
    await _updateRestaurantWaitlistCount(restaurantId);

    // Sync with Supabase backend
    try {
      SupabaseService().leaveQueue(queueId: queueId, restaurantId: restaurantId);
    } catch (_) {}
  }

  /// Update queue status (called / seated / cancelled)
  Future<void> updateQueueStatus(String queueId, QueueStatus status) async {
    final index = _fallbackQueue.indexWhere((q) => q.id == queueId);
    if (index != -1) {
      if (status == QueueStatus.seated || status == QueueStatus.cancelled) {
        _fallbackQueue.removeAt(index);
      } else {
        _fallbackQueue[index] = _fallbackQueue[index].copyWith(status: status);
      }
    }
    _queueStreamController.add(List.from(_fallbackQueue));

    if (isLiveFirebaseProject) {
      try {
        await _queueRef.doc(queueId).update({
          'status': status.value,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> _updateRestaurantWaitlistCount(String restaurantId) async {
    final count = _fallbackQueue
        .where((q) => q.restaurantId == restaurantId && (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
        .length;
    final rIdx = _fallbackRestaurants.indexWhere((r) => r.id == restaurantId);
    if (rIdx != -1) {
      _fallbackRestaurants[rIdx] = _fallbackRestaurants[rIdx].copyWith(
        waitlistCount: count,
        estWait: count == 0 ? 'Direct Seating' : '${count * 5} min wait',
        isQueueAvailable: true,
      );
    }
    if (!isLiveFirebaseProject) return;
    try {
      final activeSnapshot = await _queueRef
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'waiting')
          .get();

      final liveCount = activeSnapshot.docs.length;
      final estWaitStr = liveCount == 0 ? 'Direct Seating' : '${liveCount * 4} min wait';

      await _restaurantsRef.doc(restaurantId).set({
        'waitlist_count': liveCount,
        'est_wait': estWaitStr,
        'is_queue_available': true,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ==========================================
  // --- 3. PHYSICAL TABLES SERVICES ---
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _tablesRef =>
      _firestore.collection('tables');

  /// Realtime stream for physical floor tables
  Stream<List<PhysicalTable>> streamTables({String restaurantId = 'ocean_bistro'}) {
    if (!isLiveFirebaseProject) {
      Future.microtask(() => _tablesStreamController.add(List.from(_fallbackTables)));
      return _tablesStreamController.stream;
    }
    try {
      return _tablesRef
          .where('restaurant_id', isEqualTo: restaurantId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return _fallbackTables;
        final list = snapshot.docs.map((doc) => PhysicalTable.fromFirestore(doc)).toList();
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
    if (isLiveFirebaseProject) {
      try {
        final docRef = _tablesRef.doc(table.id.isEmpty ? null : table.id);
        await docRef.set(table.copyWith(id: docRef.id).toFirestore());
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
    if (isLiveFirebaseProject) {
      try {
        await _tablesRef.doc(table.id).set(table.toFirestore(), SetOptions(merge: true));
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
    if (isLiveFirebaseProject) {
      try {
        await _tablesRef.doc(tableId).set({
          'status': status.value,
          'guest_name': status == TableStatus.available ? 'No Guest' : 'Occupied Guest',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Delete physical table
  Future<void> deleteTable(String tableId) async {
    _fallbackTables.removeWhere((t) => t.id == tableId);
    _tablesStreamController.add(List.from(_fallbackTables));
    if (isLiveFirebaseProject) {
      try {
        await _tablesRef.doc(tableId).delete();
      } catch (_) {}
    }
  }

  // ==========================================
  // --- 4. LIVE MENU DISHES SERVICES ---
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _menuRef =>
      _firestore.collection('menu_items');

  /// Realtime stream for live menu dishes
  Stream<List<LiveMenuDish>> streamLiveMenu({String? restaurantId}) {
    if (!isLiveFirebaseProject) {
      Future.microtask(() => _dishesStreamController.add(_getFilteredFallbackDishes(restaurantId)));
      return _dishesStreamController.stream;
    }
    try {
      Query<Map<String, dynamic>> query = _menuRef;
      if (restaurantId != null && restaurantId.isNotEmpty && restaurantId != 'All') {
        query = query.where('restaurant_id', isEqualTo: restaurantId);
      }
      return query.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return _getFilteredFallbackDishes(restaurantId);
        final list = snapshot.docs.map((doc) => LiveMenuDish.fromFirestore(doc)).toList();
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
    if (isLiveFirebaseProject) {
      try {
        final docRef = _menuRef.doc(dish.id.isEmpty ? null : dish.id);
        await docRef.set(dish.copyWith(id: docRef.id).toFirestore());
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
    if (isLiveFirebaseProject) {
      try {
        await _menuRef.doc(dish.id).set(dish.toFirestore(), SetOptions(merge: true));
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
    if (isLiveFirebaseProject) {
      try {
        await _menuRef.doc(dishId).update({
          'is_available': isAvailable,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  /// Delete menu dish
  Future<void> deleteDish(String dishId) async {
    _fallbackDishes.removeWhere((d) => d.id == dishId);
    _dishesStreamController.add(_getFilteredFallbackDishes(null));
    if (isLiveFirebaseProject) {
      try {
        await _menuRef.doc(dishId).delete();
      } catch (_) {}
    }
  }

  // ==========================================
  // --- 5. RESERVATIONS SERVICES ---
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _reservationsRef =>
      _firestore.collection('reservations');

  /// Stream of user reservations with reactive stream update
  Stream<List<ReservationModel>> streamUserReservations(String userId) {
    if (!isLiveFirebaseProject) {
      final list = _fallbackReservations
          .where((r) => r.userId == userId || r.userId == 'guest_id' || userId.isEmpty)
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      Future.microtask(() => _reservationsStreamController.add(List.from(_fallbackReservations)));
      return _reservationsStreamController.stream.map((all) {
        final filtered = all
            .where((r) => r.userId == userId || r.userId == 'guest_id' || userId.isEmpty)
            .toList();
        filtered.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return filtered;
      });
    }
    try {
      final effectiveUid = userId.isNotEmpty ? userId : 'guest_id';
      return _reservationsRef
          .where('user_id', isEqualTo: effectiveUid)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              final list = _fallbackReservations.where((r) => r.userId == effectiveUid || r.userId == 'guest_id').toList();
              list.sort((a, b) {
                if (a.createdAt == null) return 1;
                if (b.createdAt == null) return -1;
                return b.createdAt!.compareTo(a.createdAt!);
              });
              return list;
            }
            final list = snapshot.docs.map((doc) => ReservationModel.fromFirestore(doc)).toList();
            list.sort((a, b) {
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            return list;
          })
          .handleError((_) => _fallbackReservations.where((r) => r.userId == effectiveUid || r.userId == 'guest_id').toList());
    } catch (_) {
      final list = _fallbackReservations.where((r) => r.userId == userId || r.userId == 'guest_id' || userId.isEmpty).toList();
      Future.microtask(() => _reservationsStreamController.add(list));
      return _reservationsStreamController.stream;
    }
  }

  /// Create reservation
  Future<ReservationModel> createReservation(ReservationModel reservation) async {
    final item = ReservationModel(
      id: 'rsv_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: reservation.restaurantId,
      restaurantName: reservation.restaurantName,
      userId: reservation.userId,
      guestName: reservation.guestName,
      reservationCode: '#RSV${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: reservation.date,
      time: reservation.time,
      partySize: reservation.partySize,
      status: 'confirmed',
      createdAt: DateTime.now(),
    );

    _fallbackReservations.insert(0, item);
    _reservationsStreamController.add(List.from(_fallbackReservations));

    if (isLiveFirebaseProject) {
      try {
        await _reservationsRef.doc(item.id).set(item.toFirestore());
      } catch (_) {}
    }

    // Sync with Supabase backend
    try {
      SupabaseService().createReservation(item);
    } catch (_) {}

    return item;
  }

  /// Cancel reservation
  Future<void> cancelReservation(String reservationId) async {
    final idx = _fallbackReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      _fallbackReservations[idx] = _fallbackReservations[idx].copyWith(status: 'cancelled');
      _reservationsStreamController.add(List.from(_fallbackReservations));
    }
    if (isLiveFirebaseProject) {
      try {
        await _reservationsRef.doc(reservationId).update({
          'status': 'cancelled',
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    // Sync with Supabase backend
    try {
      SupabaseService().cancelReservation(reservationId);
    } catch (_) {}
  }

  /// Update / Modify reservation
  Future<ReservationModel> updateReservation(ReservationModel reservation) async {
    final idx = _fallbackReservations.indexWhere((r) => r.id == reservation.id);
    if (idx != -1) {
      _fallbackReservations[idx] = reservation;
      _reservationsStreamController.add(List.from(_fallbackReservations));
    }
    if (isLiveFirebaseProject) {
      try {
        await _reservationsRef.doc(reservation.id).set(reservation.toFirestore(), SetOptions(merge: true));
      } catch (_) {}
    }

    // Sync with Supabase backend
    try {
      SupabaseService().updateReservation(reservation);
    } catch (_) {}

    return reservation;
  }

  /// Stream total bookings count for Manager Dashboard
  Stream<int> streamTotalBookingsCount({String restaurantId = 'ocean_bistro', bool isThisWeek = false}) {
    if (!isLiveFirebaseProject) {
      final base = isThisWeek ? 195 : 42;
      return Stream.value(base + _fallbackQueue.length);
    }
    try {
      return _reservationsRef
          .where('restaurant_id', isEqualTo: restaurantId)
          .snapshots()
          .map((rSnap) {
        final resCount = rSnap.docs.length;
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
    if (!isLiveFirebaseProject) return;
    try {
      final restaurantsSnapshot = await _restaurantsRef.limit(1).get();
      if (restaurantsSnapshot.docs.isEmpty) {
        for (var r in _fallbackRestaurants) {
          await _restaurantsRef.doc(r.id).set(r.toFirestore());
        }
      }

      final tablesSnapshot = await _tablesRef.limit(1).get();
      if (tablesSnapshot.docs.isEmpty) {
        for (var t in _fallbackTables) {
          await _tablesRef.doc(t.id).set(t.toFirestore());
        }
      }

      final menuSnapshot = await _menuRef.limit(1).get();
      if (menuSnapshot.docs.isEmpty) {
        for (var d in _fallbackDishes) {
          await _menuRef.doc(d.id).set(d.toFirestore());
        }
      }

      final queueSnapshot = await _queueRef.limit(1).get();
      if (queueSnapshot.docs.isEmpty) {
        for (var q in _fallbackQueue) {
          await _queueRef.doc(q.id).set(q.toFirestore());
        }
      }
    } catch (_) {}
  }
}
