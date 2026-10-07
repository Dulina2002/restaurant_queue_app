import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../features/manager/data/models/physical_table_model.dart';
import '../features/manager/data/models/live_menu_dish_model.dart';
import 'reservation_storage_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isSupabaseConfigured => _client != null;

  // In-memory fallbacks for resilient UI operation
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
  ];

  final List<ReservationModel> _fallbackReservations = [];

  final StreamController<List<QueueEntryModel>> _queueStreamController = StreamController<List<QueueEntryModel>>.broadcast();
  final StreamController<List<ReservationModel>> _reservationsStreamController = StreamController<List<ReservationModel>>.broadcast();

  // ==========================================
  // --- 1. RESTAURANTS ---
  // ==========================================

  Stream<List<RestaurantModel>> streamActiveRestaurants() {
    final client = _client;
    if (client == null) {
      return Stream.value(_fallbackRestaurants);
    }
    try {
      return client
          .from('restaurants')
          .stream(primaryKey: ['id'])
          .map((data) {
            if (data.isEmpty) return _fallbackRestaurants;
            return data.map((json) => RestaurantModel(
              id: json['id'].toString(),
              name: json['name'] as String? ?? 'Restaurant',
              cuisine: json['cuisine'] as String? ?? 'General',
              tag: json['tag'] as String? ?? '',
              location: json['location'] as String? ?? '',
              rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
              reviewsCount: (json['reviews_count'] is num) ? (json['reviews_count'] as num).toInt() : int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
              isActive: json['is_active'] as bool? ?? true,
              isQueueAvailable: json['is_queue_available'] as bool? ?? true,
              estWait: json['est_wait'] as String? ?? 'Direct Seating',
              waitlistCount: (json['waitlist_count'] is num) ? (json['waitlist_count'] as num).toInt() : 0,
            )).toList();
          })
          .handleError((e) {
            debugPrint('Supabase restaurants stream error: $e');
            return _fallbackRestaurants;
          });
    } catch (_) {
      return Stream.value(_fallbackRestaurants);
    }
  }

  // ==========================================
  // --- 2. LIVE QUEUE ---
  // ==========================================

  Stream<QueueEntryModel?> streamCustomerActiveQueue(String userId) {
    final effectiveUid = (userId.isNotEmpty && userId != 'guest_id') ? userId : 'current_customer_id';
    final client = _client;

    if (client == null) {
      Future.microtask(() => _queueStreamController.add(List.from(_fallbackQueue)));
      return _queueStreamController.stream.map((list) {
        final activeList = list
            .where((q) =>
                q.userId == effectiveUid &&
                (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
            .toList();
        if (activeList.isEmpty) return null;
        final myEntry = activeList.first;
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
      return client
          .from('queue_entries')
          .stream(primaryKey: ['id'])
          .map((data) {
            final active = data
                .where((row) =>
                    row['user_id']?.toString() == effectiveUid &&
                    (row['status'] == 'waiting' || row['status'] == 'called'))
                .map((row) => QueueEntryModel(
                      id: row['id'].toString(),
                      restaurantId: row['restaurant_id']?.toString() ?? 'ocean_bistro',
                      restaurantName: row['restaurant_name']?.toString() ?? 'Ocean Bistro',
                      userId: row['user_id']?.toString() ?? effectiveUid,
                      guestName: row['guest_name']?.toString() ?? 'Guest',
                      partySize: (row['party_size'] is num) ? (row['party_size'] as num).toInt() : 2,
                      phoneNumber: row['phone_number']?.toString() ?? '',
                      status: QueueStatus.fromString(row['status']?.toString()),
                      queueNumber: row['queue_number']?.toString() ?? 'Q-101',
                      position: (row['position'] is num) ? (row['position'] as num).toInt() : 1,
                      estimatedWaitMinutes: (row['estimated_wait_minutes'] is num)
                          ? (row['estimated_wait_minutes'] as num).toInt()
                          : 5,
                      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
                    ))
                .toList();
            return active.isNotEmpty ? active.first : null;
          })
          .handleError((_) => null);
    } catch (_) {
      return Stream.value(null);
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

    final client = _client;
    if (client != null) {
      try {
        await client.from('queue_entries').insert({
          'id': entry.id,
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
          'user_id': effectiveUid,
          'guest_name': guestName,
          'party_size': partySize,
          'phone_number': phoneNumber,
          'status': 'waiting',
          'queue_number': queueNumber,
          'position': currentPos,
          'estimated_wait_minutes': currentPos * 5,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase joinQueue insert error: $e');
      }
    }

    return entry;
  }

  Future<void> leaveQueue({required String queueId, required String restaurantId}) async {
    _fallbackQueue.removeWhere((q) => q.id == queueId);
    _queueStreamController.add(List.from(_fallbackQueue));

    final client = _client;
    if (client != null) {
      try {
        await client.from('queue_entries').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).match({'id': queueId});
      } catch (e) {
        debugPrint('Supabase leaveQueue update error: $e');
      }
    }
  }

  /// Stream full live queue for a restaurant (receptionist view)
  Stream<List<QueueEntryModel>> streamRestaurantQueue({String restaurantId = 'ocean_bistro'}) {
    final client = _client;
    if (client == null) {
      Future.microtask(() => _queueStreamController.add(List.from(_fallbackQueue)));
      return _queueStreamController.stream.map((list) => list
          .where((q) =>
              (q.restaurantId == restaurantId || restaurantId == 'ocean_bistro') &&
              q.status != QueueStatus.seated &&
              q.status != QueueStatus.cancelled)
          .toList());
    }

    try {
      return client
          .from('queue_entries')
          .stream(primaryKey: ['id'])
          .map((data) {
            final list = data
                .where((row) =>
                    (row['restaurant_id']?.toString() == restaurantId || restaurantId == 'ocean_bistro') &&
                    row['status'] != 'seated' &&
                    row['status'] != 'cancelled')
                .map((row) => QueueEntryModel(
                      id: row['id'].toString(),
                      restaurantId: row['restaurant_id']?.toString() ?? restaurantId,
                      restaurantName: row['restaurant_name']?.toString() ?? 'Ocean Bistro',
                      userId: row['user_id']?.toString(),
                      guestName: row['guest_name']?.toString() ?? 'Guest',
                      partySize: (row['party_size'] is num) ? (row['party_size'] as num).toInt() : 2,
                      phoneNumber: row['phone_number']?.toString() ?? '',
                      status: QueueStatus.fromString(row['status']?.toString()),
                      queueNumber: row['queue_number']?.toString() ?? 'Q-101',
                      position: (row['position'] is num) ? (row['position'] as num).toInt() : 1,
                      estimatedWaitMinutes: (row['estimated_wait_minutes'] is num)
                          ? (row['estimated_wait_minutes'] as num).toInt()
                          : 5,
                      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
                    ))
                .toList();
            return list.isEmpty
                ? _fallbackQueue
                    .where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled)
                    .toList()
                : list;
          })
          .handleError((_) => _fallbackQueue
              .where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled)
              .toList());
    } catch (_) {
      return Stream.value(_fallbackQueue
          .where((q) => q.status != QueueStatus.seated && q.status != QueueStatus.cancelled)
          .toList());
    }
  }

  /// Add a walk-in guest record directly to Supabase queue_entries
  Future<QueueEntryModel> addWalkIn({
    required String guestName,
    required int partySize,
    String phoneNumber = '',
    String restaurantId = 'ocean_bistro',
    String restaurantName = 'Ocean Bistro',
  }) async {
    final walkInUid = 'walk_in_${DateTime.now().millisecondsSinceEpoch}';
    return await joinQueue(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: walkInUid,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
    );
  }

  // ==========================================
  // --- 3. RESERVATIONS ---
  // ==========================================

  Stream<List<ReservationModel>> streamUserReservations(String userId) {
    final effectiveUid = userId.isNotEmpty ? userId : 'guest_id';
    final client = _client;

    // Load locally persisted reservations immediately
    Future.microtask(() async {
      final stored = await ReservationStorageService().getStoredReservations();
      for (final r in stored) {
        final idx = _fallbackReservations.indexWhere((existing) => existing.id == r.id);
        if (idx != -1) {
          _fallbackReservations[idx] = r;
        } else {
          _fallbackReservations.add(r);
        }
      }
      _reservationsStreamController.add(List.from(_fallbackReservations));
    });

    if (client == null) {
      return _reservationsStreamController.stream.map((all) {
        final filtered = all
            .where((r) => r.userId == effectiveUid)
            .toList();
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return filtered;
      });
    }

    try {
      return client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .asyncMap((data) async {
            final stored = await ReservationStorageService().getStoredReservations();
            final remoteList = data
                .where((row) => row['user_id']?.toString() == effectiveUid)
                .map((row) => ReservationModel(
                      id: row['id'].toString(),
                      restaurantId: row['restaurant_id']?.toString() ?? '',
                      restaurantName: row['restaurant_name']?.toString() ?? 'Restaurant',
                      userId: row['user_id']?.toString() ?? effectiveUid,
                      guestName: row['guest_name']?.toString() ?? 'Guest',
                      reservationCode: row['reservation_code']?.toString() ?? '#RSV1000',
                      date: row['date']?.toString() ?? '',
                      time: row['time']?.toString() ?? '',
                      partySize: (row['party_size'] is num) ? (row['party_size'] as num).toInt() : 2,
                      status: row['status']?.toString() ?? 'confirmed',
                      specialNotes: row['special_notes']?.toString(),
                      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
                    ))
                .toList();

            // Merge remote items with local storage items
            final mergedMap = <String, ReservationModel>{};
            for (final r in stored.where((r) => r.userId == effectiveUid)) {
              mergedMap[r.id] = r;
            }
            for (final r in remoteList) {
              mergedMap[r.id] = r;
            }

            final list = mergedMap.values.toList();
            list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            await ReservationStorageService().saveReservations(mergedMap.values.toList());
            return list;
          })
          .handleError((e) {
            debugPrint('Supabase streamUserReservations error: $e');
            return _fallbackReservations.where((r) => r.userId == effectiveUid).toList();
          });
    } catch (_) {
      return _reservationsStreamController.stream.map((all) => all.where((r) => r.userId == effectiveUid).toList());
    }
  }

  /// Live stream of ALL non-cancelled reservations for a restaurant (used for availability).
  Stream<List<ReservationModel>> streamRestaurantReservations(String restaurantId) async* {
    final client = _client;
    List<ReservationModel> fallbackFor() => _fallbackReservations
        .where((r) => r.restaurantId == restaurantId && r.status.toLowerCase() != 'cancelled')
        .toList();

    if (client == null) {
      yield fallbackFor();
      yield* _reservationsStreamController.stream.map((_) => fallbackFor());
      return;
    }

    try {
      yield* client.from('reservations').stream(primaryKey: ['id']).map((data) {
        return data
            .where((row) => row['restaurant_id']?.toString() == restaurantId && row['status']?.toString().toLowerCase() != 'cancelled')
            .map((row) => ReservationModel(
                  id: row['id'].toString(),
                  restaurantId: restaurantId,
                  restaurantName: row['restaurant_name']?.toString() ?? '',
                  userId: row['user_id']?.toString() ?? '',
                  guestName: row['guest_name']?.toString() ?? 'Guest',
                  reservationCode: row['reservation_code']?.toString() ?? '',
                  date: row['date']?.toString() ?? '',
                  time: row['time']?.toString() ?? '',
                  partySize: (row['party_size'] is num) ? (row['party_size'] as num).toInt() : 2,
                  status: row['status']?.toString() ?? 'confirmed',
                  specialNotes: row['special_notes']?.toString(),
                ))
            .toList();
      });
    } catch (e) {
      debugPrint('Supabase restaurant reservations stream error: $e');
      yield fallbackFor();
    }
  }

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
    await ReservationStorageService().upsertReservation(item);

    final client = _client;
    if (client != null) {
      try {
        await client.from('reservations').upsert({
          'id': item.id,
          'restaurant_id': item.restaurantId,
          'restaurant_name': item.restaurantName,
          'user_id': item.userId,
          'guest_name': item.guestName,
          'reservation_code': item.reservationCode,
          'date': item.date,
          'time': item.time,
          'party_size': item.partySize,
          'status': 'confirmed',
          'special_notes': item.specialNotes,
          'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase createReservation error: $e');
      }
    }

    return item;
  }

  Future<void> cancelReservation(String reservationId) async {
    final idx = _fallbackReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      _fallbackReservations[idx] = _fallbackReservations[idx].copyWith(status: 'cancelled');
      _reservationsStreamController.add(List.from(_fallbackReservations));
    }
    await ReservationStorageService().updateStatus(reservationId, 'cancelled');

    final client = _client;
    if (client != null) {
      try {
        await client.from('reservations').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).match({'id': reservationId});
      } catch (e) {
        debugPrint('Supabase cancelReservation error: $e');
      }
    }
  }

  Future<ReservationModel> updateReservation(ReservationModel reservation) async {
    final idx = _fallbackReservations.indexWhere((r) => r.id == reservation.id);
    if (idx != -1) {
      _fallbackReservations[idx] = reservation;
      _reservationsStreamController.add(List.from(_fallbackReservations));
    }
    await ReservationStorageService().upsertReservation(reservation);

    final client = _client;
    if (client != null) {
      try {
        await client.from('reservations').update({
          'date': reservation.date,
          'time': reservation.time,
          'party_size': reservation.partySize,
          'status': reservation.status,
          'special_notes': reservation.specialNotes,
          'updated_at': DateTime.now().toIso8601String(),
        }).match({'id': reservation.id});
      } catch (e) {
        debugPrint('Supabase updateReservation error: $e');
      }
    }
    return reservation;
  }

  // ==========================================
  // --- 4. TABLES & MENU STREAMING ---
  // ==========================================

  Stream<List<PhysicalTable>> streamTables({String restaurantId = 'ocean_bistro'}) {
    final client = _client;
    if (client == null) {
      return Stream.value(PhysicalTable.mockList().where((t) => t.restaurantId == restaurantId).toList());
    }

    try {
      return client
          .from('tables')
          .stream(primaryKey: ['id'])
          .map((data) {
            final list = data
                .where((row) => row['restaurant_id']?.toString() == restaurantId)
                .map((row) => PhysicalTable(
                      id: row['id'].toString(),
                      restaurantId: row['restaurant_id']?.toString() ?? restaurantId,
                      name: row['name']?.toString() ?? '',
                      seats: (row['seats'] is num) ? (row['seats'] as num).toInt() : 2,
                      guestName: row['guest_name']?.toString() ?? 'No Guest',
                      status: TableStatus.fromString(row['status']?.toString()),
                    ))
                .toList();
            return list.isEmpty ? PhysicalTable.mockList().where((t) => t.restaurantId == restaurantId).toList() : list;
          })
          .handleError((_) => PhysicalTable.mockList().where((t) => t.restaurantId == restaurantId).toList());
    } catch (_) {
      return Stream.value(PhysicalTable.mockList().where((t) => t.restaurantId == restaurantId).toList());
    }
  }

  Stream<List<LiveMenuDish>> streamMenuDishes({String? restaurantId}) {
    final client = _client;
    if (client == null) {
      return Stream.value(
        restaurantId != null
            ? LiveMenuDish.mockList().where((d) => d.restaurantId == restaurantId).toList()
            : LiveMenuDish.mockList(),
      );
    }

    try {
      return client
          .from('menu_items')
          .stream(primaryKey: ['id'])
          .map((data) {
            final list = data
                .where((row) => restaurantId == null || row['restaurant_id']?.toString() == restaurantId)
                .map((row) => LiveMenuDish(
                      id: row['id'].toString(),
                      restaurantId: row['restaurant_id']?.toString() ?? 'ocean_bistro',
                      name: row['name']?.toString() ?? '',
                      restaurant: row['restaurant']?.toString() ?? 'Ocean Bistro',
                      category: row['category']?.toString() ?? 'Mains',
                      price: (row['price'] is num) ? (row['price'] as num).toDouble() : double.tryParse(row['price']?.toString() ?? '0') ?? 0.0,
                      description: row['description']?.toString() ?? '',
                      isAvailable: row['is_available'] as bool? ?? true,
                    ))
                .toList();
            return list.isEmpty
                ? (restaurantId != null
                    ? LiveMenuDish.mockList().where((d) => d.restaurantId == restaurantId).toList()
                    : LiveMenuDish.mockList())
                : list;
          })
          .handleError((_) => restaurantId != null
              ? LiveMenuDish.mockList().where((d) => d.restaurantId == restaurantId).toList()
              : LiveMenuDish.mockList());
    } catch (_) {
      return Stream.value(restaurantId != null
          ? LiveMenuDish.mockList().where((d) => d.restaurantId == restaurantId).toList()
          : LiveMenuDish.mockList());
    }
  }
}
