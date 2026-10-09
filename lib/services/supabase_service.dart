import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import '../features/manager/data/models/physical_table_model.dart';
import '../features/manager/data/models/live_menu_dish_model.dart';
import '../features/receptionist/data/models/floor_table_model.dart';
import 'reservation_storage_service.dart';
import 'restaurant_image_storage.dart';

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
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1200&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
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

  final List<ReservationModel> _fallbackReservations = [
    // Ocean Bistro
    ReservationModel(
      id: 'rsv_ob_1',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_ayesha',
      guestName: 'Ayesha Perera',
      reservationCode: '#RSV1001',
      date: 'Today',
      time: '7:30 PM',
      partySize: 4,
      status: 'confirmed',
      assignedTable: 'Table 04',
      specialNotes: 'Req: Window seat facing the ocean, celebrating an anniversary.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ReservationModel(
      id: 'rsv_ob_2',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_kamal',
      guestName: 'Kamal Silva',
      reservationCode: '#RSV1002',
      date: 'Today',
      time: '8:00 PM',
      partySize: 2,
      status: 'completed',
      assignedTable: 'Table 02',
      specialNotes: 'Req: Quiet corner table.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ReservationModel(
      id: 'rsv_ob_3',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_nadee',
      guestName: 'Nadeeshani Fernando',
      reservationCode: '#RSV1003',
      date: 'Today',
      time: '7:00 PM',
      partySize: 6,
      status: 'cancelled',
      assignedTable: 'Table 06',
      specialNotes: 'Req: Tatami seating if possible.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ReservationModel(
      id: 'rsv_ob_4',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      userId: 'user_john',
      guestName: 'John Doe',
      reservationCode: '#RSV1004',
      date: 'Today',
      time: '8:30 PM',
      partySize: 3,
      status: 'confirmed',
      assignedTable: 'Table 08',
      specialNotes: 'Req: High chair needed.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),

    // The Mango Tree
    ReservationModel(
      id: 'rsv_mt_1',
      restaurantId: 'mango_tree',
      restaurantName: 'The Mango Tree',
      userId: 'user_samantha',
      guestName: 'Samantha Fernando',
      reservationCode: '#RSV2001',
      date: 'Today',
      time: '7:15 PM',
      partySize: 2,
      status: 'confirmed',
      assignedTable: 'Table 01',
      specialNotes: 'Req: Window booth requested.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ReservationModel(
      id: 'rsv_mt_2',
      restaurantId: 'mango_tree',
      restaurantName: 'The Mango Tree',
      userId: 'user_rohan',
      guestName: 'Rohan Wickramasinghe',
      reservationCode: '#RSV2002',
      date: 'Today',
      time: '8:00 PM',
      partySize: 4,
      status: 'completed',
      assignedTable: 'Table 03',
      specialNotes: 'Req: Birthday celebration table.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ReservationModel(
      id: 'rsv_mt_3',
      restaurantId: 'mango_tree',
      restaurantName: 'The Mango Tree',
      userId: 'user_nilmini',
      guestName: 'Nilmini De Silva',
      reservationCode: '#RSV2003',
      date: 'Today',
      time: '8:45 PM',
      partySize: 3,
      status: 'confirmed',
      assignedTable: 'Table 05',
      specialNotes: 'Req: Mild spices for kids.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),

    // Nihonbashi
    ReservationModel(
      id: 'rsv_nb_1',
      restaurantId: 'nihonbashi',
      restaurantName: 'Nihonbashi',
      userId: 'user_kanchana',
      guestName: 'Kanchana Jayasuriya',
      reservationCode: '#RSV3001',
      date: 'Today',
      time: '7:45 PM',
      partySize: 2,
      status: 'confirmed',
      assignedTable: 'Table 02',
      specialNotes: 'Req: Counter seating for sushi chef.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ReservationModel(
      id: 'rsv_nb_2',
      restaurantId: 'nihonbashi',
      restaurantName: 'Nihonbashi',
      userId: 'user_dinesh',
      guestName: 'Dinesh Gunawardena',
      reservationCode: '#RSV3002',
      date: 'Today',
      time: '8:30 PM',
      partySize: 5,
      status: 'confirmed',
      assignedTable: 'Table 05',
      specialNotes: 'Req: Business dinner with clients.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final StreamController<List<QueueEntryModel>> _queueStreamController = StreamController<List<QueueEntryModel>>.broadcast();
  final StreamController<List<ReservationModel>> _reservationsStreamController = StreamController<List<ReservationModel>>.broadcast();

  final List<ReviewModel> _fallbackReviews = [
    ReviewModel(
      id: 'rev_1',
      userId: 'current_customer_id',
      restaurantId: 'ocean_bistro',
      restaurantName: 'Ocean Bistro',
      rating: 5.0,
      comment: 'Exceptional seafood risotto and swift seating with DineQueue!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewModel(
      id: 'rev_2',
      userId: 'current_customer_id',
      restaurantId: 'mango_tree',
      restaurantName: 'The Mango Tree',
      rating: 4.5,
      comment: 'Delicious butter chicken and courteous service.',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];
  final StreamController<List<ReviewModel>> _reviewsStreamController = StreamController<List<ReviewModel>>.broadcast();

  // ==========================================
  // --- 1. RESTAURANTS ---
  // ==========================================

  Stream<List<RestaurantModel>> streamActiveRestaurants() {
    return streamManagedRestaurants().map(
      (list) => list.where((r) => r.isActive).toList(),
    );
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
            final allEntries = data.map((row) => QueueEntryModel(
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
                )).toList();

            final myActiveEntries = allEntries
                .where((q) =>
                    q.userId == effectiveUid &&
                    (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
                .toList();
            
            if (myActiveEntries.isEmpty) return null;

            final myEntry = myActiveEntries.first;
            final restaurantQueue = allEntries
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
    var activeCount = _fallbackQueue
        .where((q) => q.restaurantId == restaurantId && (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
        .length;
    var queueNumber = 'Q-${_fallbackQueue.length + 101}';

    // Prefer the real database numbers so positions/ticket numbers stay
    // consistent with what the manager and receptionist see.
    final lookupClient = _client;
    if (lookupClient != null) {
      try {
        final rows = await lookupClient.from('queue_entries').select('restaurant_id,status,queue_number');
        activeCount = rows
            .where((r) => r['restaurant_id']?.toString() == restaurantId && (r['status'] == 'waiting' || r['status'] == 'called'))
            .length;
        var maxTicket = 100;
        for (final r in rows) {
          final n = int.tryParse((r['queue_number']?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
          if (n != null && n > maxTicket) maxTicket = n;
        }
        queueNumber = 'Q-${maxTicket + 1}';
      } catch (e) {
        debugPrint('Supabase joinQueue lookup error: $e');
      }
    }
    final currentPos = activeCount + 1;
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
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        _notifyChanged('queue_entries');
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
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': queueId});
      } catch (e) {
        debugPrint('Supabase leaveQueue update error: $e');
      }
      _notifyChanged('queue_entries');
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

  /// Live stream of ALL non-cancelled reservations for a restaurant
  /// ('All' = every restaurant). Used for availability and manager analytics.
  Stream<List<ReservationModel>> streamRestaurantReservations(String restaurantId) {
    final all = _isAll(restaurantId);
    final fallbackJson = _fallbackReservations
        .where((r) => (all || r.restaurantId == restaurantId))
        .map((r) => r.toJson())
        .toList();
    bool keep(ReservationModel r) => r.status.toLowerCase() != 'cancelled';

    if (_client == null) {
      List<ReservationModel> local() =>
          _fallbackReservations.where((r) => (all || r.restaurantId == restaurantId) && keep(r)).toList();
      Future.microtask(() => _reservationsStreamController.add(List.from(_fallbackReservations)));
      return _reservationsStreamController.stream.map((_) => local());
    }

    return _liveRows('reservations', restaurantId: all ? null : restaurantId, initialFallback: fallbackJson).map((rows) {
      return rows
          .map((row) => ReservationModel(
                id: row['id'].toString(),
                restaurantId: row['restaurant_id']?.toString() ?? '',
                restaurantName: row['restaurant_name']?.toString() ?? '',
                userId: row['user_id']?.toString() ?? '',
                guestName: row['guest_name']?.toString() ?? 'Guest',
                reservationCode: row['reservation_code']?.toString() ?? '',
                date: row['date']?.toString() ?? '',
                time: row['time']?.toString() ?? '',
                partySize: (row['party_size'] is num) ? (row['party_size'] as num).toInt() : 2,
                status: row['status']?.toString() ?? 'confirmed',
                specialNotes: row['special_notes']?.toString(),
                createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString())?.toLocal() : null,
              ))
          .where(keep)
          .toList();
    });
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
          'created_at': (item.createdAt ?? DateTime.now()).toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase createReservation error: $e');
      }
      _notifyChanged('reservations');
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
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': reservationId});
      } catch (e) {
        debugPrint('Supabase cancelReservation error: $e');
      }
      _notifyChanged('reservations');
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
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': reservation.id});
      } catch (e) {
        debugPrint('Supabase updateReservation error: $e');
      }
      _notifyChanged('reservations');
    }
    return reservation;
  }

  /// Live stream of ALL reservations for a restaurant (including Confirmed, Completed, Cancelled)
  Stream<List<ReservationModel>> streamAllRestaurantReservations(String restaurantId) {
    final targetId = restaurantId.isNotEmpty ? restaurantId : 'ocean_bistro';
    final fallback = _fallbackReservations.where((r) => r.restaurantId == targetId).toList();
    fallback.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    final fallbackJson = fallback.map((r) => r.toJson()).toList();

    final client = _client;
    if (client == null) {
      Future.microtask(() => _reservationsStreamController.add(List.from(_fallbackReservations)));
      return _reservationsStreamController.stream.map((list) {
        final filtered = list.where((r) => r.restaurantId == targetId).toList();
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return filtered;
      });
    }

    return _liveRows(
      'reservations',
      restaurantId: targetId,
      initialFallback: fallbackJson,
    ).map((rows) {
      final list = rows
          .where((row) => row['restaurant_id']?.toString() == targetId)
          .map((row) => ReservationModel.fromJson(row))
          .toList();

      if (list.isNotEmpty) {
        for (final item in list) {
          final idx = _fallbackReservations.indexWhere((r) => r.id == item.id);
          if (idx != -1) {
            _fallbackReservations[idx] = item;
          } else {
            _fallbackReservations.add(item);
          }
        }
        list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return list;
      }

      final fallbackRes = _fallbackReservations.where((r) => r.restaurantId == targetId).toList();
      fallbackRes.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return fallbackRes;
    });
  }

  Future<void> updateReservationStatus(
    String reservationId,
    String status, {
    String? assignedTable,
  }) async {
    final normalized = status.toLowerCase();
    final idx = _fallbackReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      _fallbackReservations[idx] = _fallbackReservations[idx].copyWith(
        status: normalized,
        assignedTable: assignedTable ?? _fallbackReservations[idx].assignedTable,
      );
      _reservationsStreamController.add(List.from(_fallbackReservations));
    }
    await ReservationStorageService().updateStatus(reservationId, normalized);
    if (assignedTable != null) {
      await ReservationStorageService().updateAssignedTableAndNotes(reservationId, assignedTable);
    }

    final client = _client;
    if (client != null) {
      try {
        await client.from('reservations').update({
          'status': normalized,
          if (assignedTable != null) 'assigned_table': assignedTable,
          'updated_at': DateTime.now().toIso8601String(),
        }).match({'id': reservationId});
      } catch (e) {
        debugPrint('Supabase updateReservationStatus error: $e');
      }
      _notifyChanged('reservations');
    }
  }

  Future<void> reassignReservationTable({
    required String reservationId,
    required String newTable,
    String? updatedNotes,
  }) async {
    final idx = _fallbackReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      _fallbackReservations[idx] = _fallbackReservations[idx].copyWith(
        assignedTable: newTable,
        specialNotes: updatedNotes ?? _fallbackReservations[idx].specialNotes,
      );
      _reservationsStreamController.add(List.from(_fallbackReservations));
    }
    await ReservationStorageService().updateAssignedTableAndNotes(
      reservationId,
      newTable,
      updatedNotes,
    );

    final client = _client;
    if (client != null) {
      try {
        await client.from('reservations').update({
          'assigned_table': newTable,
          if (updatedNotes != null) 'special_notes': updatedNotes,
          'updated_at': DateTime.now().toIso8601String(),
        }).match({'id': reservationId});
      } catch (e) {
        debugPrint('Supabase reassignReservationTable error: $e');
      }
      _notifyChanged('reservations');
    }
  }

  List<ReservationModel> getRestaurantReservationsSync(String restaurantId) {
    final targetId = restaurantId.isNotEmpty ? restaurantId : 'ocean_bistro';
    final list = _fallbackReservations.where((r) => r.restaurantId == targetId).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  // ==========================================
  // --- 4. LIVE DATABASE STREAMS (TABLES, MENU, RESTAURANTS, QUEUE) ---
  // ==========================================

  // Multi-restaurant Floor Tables cache & stream controller
  final Map<String, List<FloorTable>> _fallbackFloorTables = {};
  final StreamController<Map<String, List<FloorTable>>> _floorTablesStreamController =
      StreamController<Map<String, List<FloorTable>>>.broadcast();

  List<FloorTable> _getOrCreateFallbackFloorTables(String restaurantId) {
    final targetId = restaurantId.isNotEmpty ? restaurantId : 'ocean_bistro';
    if (!_fallbackFloorTables.containsKey(targetId)) {
      _fallbackFloorTables[targetId] = List.from(FloorTable.mockListForRestaurant(targetId));
    }
    return _fallbackFloorTables[targetId]!;
  }

  /// Stream live floor tables for a restaurant (Receptionist Floor Overview)
  Stream<List<FloorTable>> streamFloorTables({required String restaurantId}) {
    final targetId = restaurantId.isNotEmpty ? restaurantId : 'ocean_bistro';
    final fallbackList = List<FloorTable>.from(_getOrCreateFallbackFloorTables(targetId));
    final fallbackJson = fallbackList.map((t) => t.toJson()).toList();

    final client = _client;
    if (client == null) {
      Future.microtask(() {
        _floorTablesStreamController.add(Map.from(_fallbackFloorTables));
      });
      return _floorTablesStreamController.stream.map((map) {
        return List<FloorTable>.from(
          map[targetId] ?? _getOrCreateFallbackFloorTables(targetId),
        );
      });
    }

    return _liveRows(
      'tables',
      // Do NOT pass restaurantId here — Supabase stream() only supports filtering
      // by primary-key columns. Passing restaurant_id (a non-PK column) to
      // .stream().eq() causes realtime to return only one row. The client-side
      // .where() below handles the restaurant scoping correctly.
      initialFallback: fallbackJson,
    ).map((rows) {
      final list = rows
          .where((row) => row['restaurant_id']?.toString() == targetId)
          .map((row) => FloorTable.fromJson(row))
          .toList();

      if (list.isEmpty) {
        return List<FloorTable>.from(_getOrCreateFallbackFloorTables(targetId));
      }
      _fallbackFloorTables[targetId] = List.from(list);
      return list;
    });
  }

  /// Update a table's status and guest name across Supabase & in-memory cache
  Future<void> updateFloorTableStatus({
    required String restaurantId,
    required String tableId,
    required FloorTableStatus status,
    String guestName = '',
  }) async {
    final targetId = restaurantId.isNotEmpty ? restaurantId : 'ocean_bistro';
    final currentList = _getOrCreateFallbackFloorTables(targetId);
    final idx = currentList.indexWhere((t) => t.id == tableId);

    if (idx != -1) {
      currentList[idx] = currentList[idx].copyWith(
        status: status,
        guestName: status == FloorTableStatus.available ? '' : guestName,
      );
      _fallbackFloorTables[targetId] = List.from(currentList);
      _floorTablesStreamController.add(Map.from(_fallbackFloorTables));
    }

    final client = _client;
    if (client != null) {
      try {
        await client.from('tables').update({
          'status': status.name,
          'guest_name': status == FloorTableStatus.available ? '' : guestName,
          'updated_at': DateTime.now().toIso8601String(),
        }).match({'id': tableId, 'restaurant_id': targetId});
      } catch (e) {
        debugPrint('Supabase updateFloorTableStatus error: $e');
      }
      _notifyChanged('tables');
    }
  }

  /// Retrieve current cached floor tables synchronously
  List<FloorTable> getFloorTablesSync({required String restaurantId}) {
    final targetId = restaurantId.isNotEmpty ? restaurantId : 'ocean_bistro';
    return List<FloorTable>.from(_getOrCreateFallbackFloorTables(targetId));
  }

  /// Retrieve current cached active queue synchronously
  List<QueueEntryModel> getRestaurantQueueSync(String restaurantId) {
    final all = _isAll(restaurantId);
    return _fallbackQueue
        .where((q) =>
            (all || q.restaurantId == restaurantId) &&
            q.status != QueueStatus.seated &&
            q.status != QueueStatus.cancelled)
        .toList();
  }

  /// Emits a table name whenever this device mutates that table so every
  /// active stream can refetch immediately (without waiting for realtime).
  final StreamController<String> _localChanges = StreamController<String>.broadcast();

  void _notifyChanged(String table) {
    if (!_localChanges.isClosed) _localChanges.add(table);
  }

  bool _isAll(String? id) => id == null || id.isEmpty || id == 'All';

  /// Builds a live stream of raw rows for [table], optionally scoped to one
  /// restaurant. It combines three sources so the UI never goes stale:
  ///  1. an initial / on-demand REST fetch,
  ///  2. Supabase realtime change events,
  ///  3. a slow safety-net poll (covers tables not published to realtime).
  /// Yields [initialFallback] immediately on listen so screen renders in 0ms.
  Stream<List<Map<String, dynamic>>> _liveRows(
    String table, {
    String? restaurantId,
    List<Map<String, dynamic>>? initialFallback,
  }) {
    final client = _client;
    if (client == null) return Stream.value(initialFallback ?? const []);

    late final StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSub;
    StreamSubscription<String>? localSub;
    Timer? poller;
    var fetching = false;

    Future<void> refetch() async {
      if (fetching || controller.isClosed) return;
      fetching = true;
      try {
        final base = client.from(table).select();
        final rows = restaurantId == null ? await base : await base.eq('restaurant_id', restaurantId);
        if (!controller.isClosed) {
          final mapped = rows.map((r) => Map<String, dynamic>.from(r)).toList();
          controller.add(mapped);
        }
      } catch (e) {
        debugPrint('Supabase fetch ($table) error: $e');
        if (!controller.isClosed) {
          if (initialFallback != null) {
            controller.add(initialFallback);
          } else {
            controller.addError(e);
          }
        }
      } finally {
        fetching = false;
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        if (initialFallback != null) {
          controller.add(initialFallback);
        }
        refetch();
        try {
          final builder = client.from(table).stream(primaryKey: ['id']);
          final source = restaurantId == null ? builder : builder.eq('restaurant_id', restaurantId);
          realtimeSub = source.listen(
            (rows) {
              if (!controller.isClosed) {
                var mapped = rows.map((r) => Map<String, dynamic>.from(r)).toList();
                if (restaurantId != null) {
                  mapped = mapped.where((r) => r['restaurant_id'] == restaurantId).toList();
                }
                controller.add(mapped);
              }
            },
            onError: (Object e) => debugPrint('Supabase realtime ($table) error: $e'),
          );
        } catch (e) {
          debugPrint('Supabase realtime ($table) setup error: $e');
        }
        localSub = _localChanges.stream.where((t) => t == table).listen((_) => refetch());
        poller = Timer.periodic(const Duration(seconds: 15), (_) => refetch());
      },
      onCancel: () async {
        poller?.cancel();
        await realtimeSub?.cancel();
        await localSub?.cancel();
      },
    );
    return controller.stream;
  }

  int _naturalCompare(String a, String b) {
    final re = RegExp(r'(\d+)|(\D+)');
    final pa = re.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
    final pb = re.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final na = int.tryParse(pa[i]);
      final nb = int.tryParse(pb[i]);
      final c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  // ---------- Restaurants (manager) ----------

  RestaurantModel _restaurantFromRow(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? 'Restaurant';
    final cuisine = json['cuisine'] as String? ?? 'General';
    final customSaved = RestaurantImageStorage().getImage(
      id: id,
      name: name,
      enableCulinaryFallback: false,
    );
    final rawImg = json['image_url'] as String?;
    final resolvedImageUrl = (customSaved != null && customSaved.trim().isNotEmpty)
        ? customSaved.trim()
        : ((rawImg != null && rawImg.trim().isNotEmpty)
            ? rawImg.trim()
            : RestaurantImageStorage().getImage(id: id, name: name, cuisine: cuisine));

    return RestaurantModel(
      id: id,
      name: name,
      cuisine: cuisine,
      tag: json['tag'] as String? ?? '',
      location: json['location'] as String? ?? '',
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
      reviewsCount: (json['reviews_count'] is num) ? (json['reviews_count'] as num).toInt() : 0,
      isActive: json['is_active'] as bool? ?? true,
      isQueueAvailable: json['is_queue_available'] as bool? ?? true,
      estWait: json['est_wait'] as String? ?? 'Direct Seating',
      waitlistCount: (json['waitlist_count'] is num) ? (json['waitlist_count'] as num).toInt() : 0,
      imageUrl: resolvedImageUrl,
    );
  }

  /// Synchronize restaurant changes into the active memory cache and stream
  void syncRestaurant({
    required String id,
    required String name,
    required String cuisine,
    required String location,
    required String estWait,
    String? imageUrl,
    bool? isActive,
  }) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      RestaurantImageStorage().saveImage(
        id: id,
        name: name,
        imageUrl: imageUrl.trim(),
      );
    }
    final numbers = estWait.replaceAll(RegExp(r'[^0-9]'), '');
    final waitMinutes = int.tryParse(numbers) ?? 0;
    final existingIdx = _fallbackRestaurants.indexWhere((r) => r.id == id);
    final customSaved = RestaurantImageStorage().getImage(
      id: id,
      name: name,
      enableCulinaryFallback: false,
    );
    final effectiveImg = (imageUrl != null && imageUrl.trim().isNotEmpty)
        ? imageUrl.trim()
        : (customSaved ??
            (existingIdx >= 0
                ? _fallbackRestaurants[existingIdx].imageUrl
                : RestaurantImageStorage().getImage(id: id, name: name, cuisine: cuisine)));

    final model = RestaurantModel(
      id: id,
      name: name,
      cuisine: cuisine,
      tag: cuisine,
      location: location,
      rating: existingIdx >= 0 ? _fallbackRestaurants[existingIdx].rating : 4.8,
      reviewsCount: existingIdx >= 0 ? _fallbackRestaurants[existingIdx].reviewsCount : 12,
      isActive: isActive ?? (existingIdx >= 0 ? _fallbackRestaurants[existingIdx].isActive : true),
      isQueueAvailable: waitMinutes > 0,
      estWait: '${waitMinutes}m',
      waitlistCount: existingIdx >= 0 ? _fallbackRestaurants[existingIdx].waitlistCount : 0,
      imageUrl: effectiveImg,
    );
    if (existingIdx >= 0) {
      _fallbackRestaurants[existingIdx] = model;
    } else {
      _fallbackRestaurants.add(model);
    }
    _notifyChanged('restaurants');
  }

  Future<RestaurantModel?> getRestaurant(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final row = await client.from('restaurants').select().eq('id', id).maybeSingle();
        if (row != null) {
          final mapped = _restaurantFromRow(Map<String, dynamic>.from(row));
          if (mapped.imageUrl == null || mapped.imageUrl!.isEmpty) {
            final cached = RestaurantImageStorage().getImage(id: mapped.id, name: mapped.name, cuisine: mapped.cuisine);
            if (cached != null) {
              return mapped.copyWith(imageUrl: cached);
            }
          }
          return mapped;
        }
      } catch (e) {
        debugPrint('Supabase getRestaurant error: $e');
      }
    }
    try {
      final fallback = _fallbackRestaurants.firstWhere((r) => r.id == id);
      if (fallback.imageUrl == null || fallback.imageUrl!.isEmpty) {
        final cached = RestaurantImageStorage().getImage(id: fallback.id, name: fallback.name, cuisine: fallback.cuisine);
        if (cached != null) {
          return fallback.copyWith(imageUrl: cached);
        }
      }
      return fallback;
    } catch (_) {
      return null;
    }
  }

  /// Every restaurant row in the database (the manager can manage them all).
  Stream<List<RestaurantModel>> streamManagedRestaurants() async* {
    final fallbackJson = _fallbackRestaurants.map((r) => r.toJson()).toList();
    if (_client == null) {
      yield List.from(_fallbackRestaurants);
      yield* _localChanges.stream
          .where((t) => t == 'restaurants')
          .map((_) => List<RestaurantModel>.from(_fallbackRestaurants));
      return;
    }
    yield* _liveRows('restaurants', initialFallback: fallbackJson).map((rows) {
      final list = rows.map((row) {
        final r = _restaurantFromRow(row);
        final custom = RestaurantImageStorage().getImage(
          id: r.id,
          name: r.name,
          enableCulinaryFallback: false,
        );
        final existingIdx = _fallbackRestaurants.indexWhere((f) => f.id == r.id);
        final existingImg = existingIdx >= 0 ? _fallbackRestaurants[existingIdx].imageUrl : null;
        final effectiveImg = (custom != null && custom.isNotEmpty)
            ? custom
            : ((r.imageUrl != null && r.imageUrl!.isNotEmpty)
                ? r.imageUrl
                : (existingImg ?? RestaurantImageStorage().getImage(id: r.id, name: r.name, cuisine: r.cuisine)));
        return r.copyWith(imageUrl: effectiveImg);
      }).toList();

      final seenIds = list.map((r) => r.id).toSet();
      for (final r in list) {
        final idx = _fallbackRestaurants.indexWhere((f) => f.id == r.id);
        if (idx >= 0) {
          _fallbackRestaurants[idx] = r;
        } else {
          _fallbackRestaurants.add(r);
        }
      }
      final extraFallback = _fallbackRestaurants.where((r) => !seenIds.contains(r.id));
      final combined = [...list, ...extraFallback];
      combined.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return combined;
    });
  }


  /// Registers a brand new restaurant in the database.
  Future<RestaurantModel> addRestaurant(String name) async {
    final cleanName = name.trim();
    var baseId = cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    if (baseId.isEmpty) baseId = 'restaurant';

    final client = _client;
    if (client == null) {
      var id = baseId;
      var n = 2;
      while (_fallbackRestaurants.any((r) => r.id == id)) {
        id = '${baseId}_${n++}';
      }
      final created = RestaurantModel(
        id: id,
        name: cleanName,
        cuisine: 'General',
        tag: 'New Restaurant',
        location: '',
        rating: 4.5,
        reviewsCount: 0,
        estWait: 'Direct Seating',
        waitlistCount: 0,
      );
      _fallbackRestaurants.add(created);
      _notifyChanged('restaurants');
      return created;
    }

    Set<String> usedIds = {};
    try {
      final existing = await client.from('restaurants').select('id');
      usedIds = existing.map((r) => r['id'].toString()).toSet();
    } catch (_) {}
    usedIds.addAll(_fallbackRestaurants.map((r) => r.id));

    var id = baseId;
    var n = 2;
    while (usedIds.contains(id)) {
      id = '${baseId}_${n++}';
    }

    final created = RestaurantModel(
      id: id,
      name: cleanName,
      cuisine: 'General',
      tag: 'New Restaurant',
      location: '',
      rating: 4.5,
      reviewsCount: 0,
      estWait: 'Direct Seating',
      waitlistCount: 0,
    );

    try {
      await client.from('restaurants').insert(created.toJson()..remove('created_at'));
    } catch (e) {
      debugPrint('Supabase addRestaurant notice (falling back locally): $e');
      // If Supabase RLS policy rejects the insert (e.g. code 42501 Unauthorized)
      // or unauthenticated demo session, keep the restaurant in local fallback
      // cache so manager operations succeed seamlessly without crashing.
    }

    if (!_fallbackRestaurants.any((r) => r.id == created.id)) {
      _fallbackRestaurants.add(created);
    }

    final defaultTables = [
      PhysicalTable(id: '${id}_t1', restaurantId: id, name: 'Table 01', zone: 'Main Dining', seats: 2, guestName: 'No Guest', status: TableStatus.available),
      PhysicalTable(id: '${id}_t2', restaurantId: id, name: 'Table 02', zone: 'Main Dining', seats: 4, guestName: 'No Guest', status: TableStatus.available),
      PhysicalTable(id: '${id}_t3', restaurantId: id, name: 'Table 03', zone: 'Terrace', seats: 4, guestName: 'No Guest', status: TableStatus.available),
      PhysicalTable(id: '${id}_t4', restaurantId: id, name: 'Table 04', zone: 'VIP Area', seats: 6, guestName: 'No Guest', status: TableStatus.available),
    ];
    for (final table in defaultTables) {
      try {
        await addTable(table);
      } catch (_) {}
    }

    _notifyChanged('restaurants');
    return created;
  }

  // ---------- Live restaurant queue (manager / receptionist) ----------

  QueueEntryModel _queueFromRow(Map<String, dynamic> row, {String? fallbackRestaurantId}) {
    return QueueEntryModel(
      id: row['id'].toString(),
      restaurantId: row['restaurant_id']?.toString() ?? fallbackRestaurantId ?? '',
      restaurantName: row['restaurant_name']?.toString() ?? '',
      userId: row['user_id']?.toString(),
      guestName: row['guest_name']?.toString() ?? 'Guest',
      partySize: (row['party_size'] is num) ? (row['party_size'] as num).toInt() : 2,
      phoneNumber: row['phone_number']?.toString() ?? '',
      status: QueueStatus.fromString(row['status']?.toString()),
      queueNumber: row['queue_number']?.toString() ?? '',
      position: (row['position'] is num) ? (row['position'] as num).toInt() : 1,
      estimatedWaitMinutes:
          (row['estimated_wait_minutes'] is num) ? (row['estimated_wait_minutes'] as num).toInt() : 5,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString())?.toLocal() : null,
      updatedAt: row['updated_at'] != null ? DateTime.tryParse(row['updated_at'].toString())?.toLocal() : null,
    );
  }

  /// Live queue rows for one restaurant ('All' = every restaurant), oldest first.
  /// With [activeOnly] seated and cancelled parties are excluded.
  Stream<List<QueueEntryModel>> streamQueueEntries(String restaurantId, {bool activeOnly = true}) {
    final all = _isAll(restaurantId);
    final fallbackJson = _fallbackQueue
        .where((q) => (all || q.restaurantId == restaurantId))
        .map((q) => q.toJson())
        .toList();
    bool keep(QueueEntryModel q) =>
        !activeOnly || (q.status != QueueStatus.seated && q.status != QueueStatus.cancelled);
    List<QueueEntryModel> sorted(List<QueueEntryModel> l) {
      l.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
      return l;
    }

    if (_client == null) {
      List<QueueEntryModel> local(List<QueueEntryModel> list) =>
          sorted(list.where((q) => (all || q.restaurantId == restaurantId) && keep(q)).toList());
      Future.microtask(() => _queueStreamController.add(List.from(_fallbackQueue)));
      return _queueStreamController.stream.map(local);
    }

    return _liveRows('queue_entries', restaurantId: all ? null : restaurantId, initialFallback: fallbackJson)
        .map((rows) => sorted(rows.map((r) => _queueFromRow(r)).where(keep).toList()));
  }

  Stream<List<QueueEntryModel>> streamRestaurantQueue({String restaurantId = 'All'}) =>
      streamQueueEntries(restaurantId);

  Future<void> updateQueueStatus(
    String queueId,
    QueueStatus status, {
    String? restaurantId,
  }) async {
    final idx = _fallbackQueue.indexWhere((q) => q.id == queueId);
    if (idx != -1) {
      _fallbackQueue[idx] = _fallbackQueue[idx].copyWith(status: status);
      _queueStreamController.add(List.from(_fallbackQueue));
    }
    final client = _client;
    if (client == null) return;
    try {
      await client.from('queue_entries').update({
        'status': status.value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', queueId);
    } catch (e) {
      debugPrint('Supabase updateQueueStatus error: $e');
      rethrow;
    }
    _notifyChanged('queue_entries');
  }

  /// Oldest waiting/called party for a restaurant, or null when nobody waits.
  Future<QueueEntryModel?> getNextWaitingParty(String restaurantId) async {
    final client = _client;
    if (client == null) {
      final list = _fallbackQueue
          .where((q) => q.restaurantId == restaurantId && (q.status == QueueStatus.waiting || q.status == QueueStatus.called))
          .toList()
        ..sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
      return list.isEmpty ? null : list.first;
    }
    final rows = await client
        .from('queue_entries')
        .select()
        .eq('restaurant_id', restaurantId)
        .inFilter('status', ['waiting', 'called'])
        .order('created_at', ascending: true)
        .limit(1);
    if (rows.isEmpty) return null;
    return _queueFromRow(Map<String, dynamic>.from(rows.first));
  }

  /// Parties that are still `waiting` (not yet called) for a restaurant, oldest first.
  Future<List<QueueEntryModel>> getWaitingParties(String restaurantId) async {
    final client = _client;
    if (client == null) {
      return _fallbackQueue
          .where((q) => q.restaurantId == restaurantId && q.status == QueueStatus.waiting)
          .toList()
        ..sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
    }
    final rows = await client
        .from('queue_entries')
        .select()
        .eq('restaurant_id', restaurantId)
        .eq('status', 'waiting')
        .order('created_at', ascending: true);
    return rows.map((r) => _queueFromRow(Map<String, dynamic>.from(r))).toList();
  }

  Future<int> callNextWaitingParties(String restaurantId, int count) async {
    if (count <= 0) return 0;
    final waiting = await getWaitingParties(restaurantId);
    final toCall = waiting.take(count).toList();
    for (final party in toCall) {
      await updateQueueStatus(party.id, QueueStatus.called);
    }
    return toCall.length;
  }

  // ---------- Tables ----------

  final List<PhysicalTable> _fallbackTables = List<PhysicalTable>.from(PhysicalTable.mockList());

  List<PhysicalTable> _ensureFallbackTables(String? restaurantId) {
    if (_isAll(restaurantId)) {
      return List<PhysicalTable>.from(_fallbackTables);
    }
    final rId = restaurantId ?? 'ocean_bistro';
    return _fallbackTables.where((t) => t.restaurantId == rId).toList();
  }

  /// The `zone` column is optional in the deployed schema. Once Supabase
  /// reports it missing we stop sending it so table writes keep working.
  bool _tablesZoneColumnSupported = true;

  PhysicalTable _tableFromRow(Map<String, dynamic> row) {
    return PhysicalTable(
      id: row['id'].toString(),
      restaurantId: row['restaurant_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      zone: row['zone']?.toString() ?? 'Main Dining',
      seats: (row['seats'] is num) ? (row['seats'] as num).toInt() : 2,
      guestName: row['guest_name']?.toString() ?? 'No Guest',
      status: TableStatus.fromString(row['status']?.toString()),
    );
  }

  Stream<List<PhysicalTable>> streamTables({String? restaurantId}) {
    final showAll = _isAll(restaurantId);
    final client = _client;
    if (client == null) {
      final fallbackList = _ensureFallbackTables(restaurantId);
      return Stream.value(fallbackList);
    }
    // Don't use initialFallback from mock data when connected to the live database,
    // to prevent the customer UI from showing tables that don't actually exist
    return _liveRows('tables', restaurantId: showAll ? null : restaurantId).map((rows) {
      final dbTables = rows.map(_tableFromRow).toList();
      dbTables.sort((a, b) => _naturalCompare(a.name, b.name));
      return dbTables;
    });
  }

  Future<List<PhysicalTable>> getTables({String? restaurantId}) async {
    final client = _client;
    if (client != null) {
      try {
        final showAll = _isAll(restaurantId);
        final base = client.from('tables').select();
        final rows = showAll ? await base : await base.eq('restaurant_id', restaurantId!);
        final list = (rows as List).map((r) => _tableFromRow(Map<String, dynamic>.from(r))).toList();
        list.sort((a, b) => _naturalCompare(a.name, b.name));
        return list;
      } catch (e) {
        debugPrint('Supabase getTables error: $e');
      }
    }
    return _ensureFallbackTables(restaurantId);
  }


  Future<PhysicalTable> addTable(PhysicalTable table) async {
    final idx = _fallbackTables.indexWhere((t) => t.id == table.id);
    if (idx != -1) {
      _fallbackTables[idx] = table;
    } else {
      _fallbackTables.add(table);
    }

    final client = _client;
    if (client == null) {
      _notifyChanged('tables');
      return table;
    }

    final payload = <String, dynamic>{
      'id': table.id,
      'restaurant_id': table.restaurantId,
      'name': table.name,
      'seats': table.seats,
      'guest_name': table.guestName,
      'status': table.status.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (_tablesZoneColumnSupported) {
        try {
          await client.from('tables').upsert({...payload, 'zone': table.zone});
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST204' || e.message.toLowerCase().contains('zone')) {
            _tablesZoneColumnSupported = false;
            await client.from('tables').upsert(payload);
          } else {
            rethrow;
          }
        }
      } else {
        await client.from('tables').upsert(payload);
      }
    } catch (e) {
      debugPrint('Supabase addTable error: $e');
    }
    _notifyChanged('tables');
    return table;
  }

  Future<PhysicalTable> updateTable(PhysicalTable table) => addTable(table);

  Future<void> deleteTable(String id) async {
    _fallbackTables.removeWhere((t) => t.id == id);
    final client = _client;
    if (client == null) {
      _notifyChanged('tables');
      return;
    }
    try {
      await client.from('tables').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteTable error: $e');
    }
    _notifyChanged('tables');
  }

  /// Sets [status] on every table in [ids]. Freed tables clear their guest.
  Future<void> setTablesStatus(List<String> ids, TableStatus status, {String? guestName}) async {
    if (ids.isEmpty) return;
    for (final id in ids) {
      final idx = _fallbackTables.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _fallbackTables[idx] = _fallbackTables[idx].copyWith(
          status: status,
          guestName: guestName ?? (status == TableStatus.available ? 'No Guest' : _fallbackTables[idx].guestName),
        );
      }
    }

    final client = _client;
    if (client == null) {
      _notifyChanged('tables');
      return;
    }
    final values = <String, dynamic>{
      'status': status.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (status == TableStatus.available) {
      values['guest_name'] = 'No Guest';
    } else if (guestName != null) {
      values['guest_name'] = guestName;
    }
    try {
      await client.from('tables').update(values).inFilter('id', ids);
    } catch (e) {
      debugPrint('Supabase setTablesStatus error: $e');
    }
    _notifyChanged('tables');
  }

  Future<PhysicalTable?> getTable(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final row = await client.from('tables').select().eq('id', id).maybeSingle();
        if (row != null) return _tableFromRow(Map<String, dynamic>.from(row));
      } catch (e) {
        debugPrint('Supabase getTable error: $e');
      }
    }
    try {
      return _fallbackTables.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> seatGuestAtTable({
    required String tableId,
    required String guestName,
    String? queueId,
  }) async {
    await setTablesStatus([tableId], TableStatus.occupied, guestName: guestName);
    if (queueId != null && queueId.isNotEmpty) {
      await updateQueueStatus(queueId, QueueStatus.seated);
    }
  }

  Future<QueueEntryModel?> seatNextQueueParty({required String tableId}) async {
    final table = await getTable(tableId);
    if (table == null) return null;
    final partyToSeat = await getNextWaitingParty(table.restaurantId);
    if (partyToSeat == null) return null;

    await seatGuestAtTable(
      tableId: tableId,
      guestName: partyToSeat.guestName,
      queueId: partyToSeat.id,
    );
    return partyToSeat;
  }

  Future<void> bulkQuickTurnTables(List<String> tableIds) async {
    await setTablesStatus(tableIds, TableStatus.available);
  }

  // ---------- Live menu ----------

  final List<LiveMenuDish> _fallbackDishes = List<LiveMenuDish>.from(LiveMenuDish.mockList());

  List<LiveMenuDish> _ensureFallbackDishes(String? restaurantId) {
    final showAll = _isAll(restaurantId);
    if (showAll) return List<LiveMenuDish>.from(_fallbackDishes);
    final rId = restaurantId ?? 'ocean_bistro';
    final existing = _fallbackDishes.where((d) => d.restaurantId == rId).toList();
    if (existing.isNotEmpty) return existing;
    return [];
  }

  LiveMenuDish _dishFromRow(Map<String, dynamic> row) {
    return LiveMenuDish(
      id: row['id'].toString(),
      restaurantId: row['restaurant_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      restaurant: row['restaurant']?.toString() ?? '',
      category: row['category']?.toString() ?? 'Mains',
      price: (row['price'] is num)
          ? (row['price'] as num).toDouble()
          : double.tryParse(row['price']?.toString() ?? '0') ?? 0.0,
      description: row['description']?.toString() ?? '',
      isAvailable: row['is_available'] as bool? ?? true,
    );
  }

  Stream<List<LiveMenuDish>> streamMenuDishes({String? restaurantId}) {
    final showAll = _isAll(restaurantId);
    final fallbackList = _ensureFallbackDishes(restaurantId);
    final fallbackJson = fallbackList.map((d) => d.toJson()).toList();
    final client = _client;
    if (client == null) {
      return Stream.value(fallbackList);
    }
    return _liveRows('menu_items', restaurantId: showAll ? null : restaurantId, initialFallback: fallbackJson).map((rows) {
      final dbDishes = rows.map(_dishFromRow).toList();
      dbDishes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return dbDishes;
    });
  }


  Future<LiveMenuDish> addMenuItem(LiveMenuDish dish) async {
    final idx = _fallbackDishes.indexWhere((d) => d.id == dish.id);
    if (idx != -1) {
      _fallbackDishes[idx] = dish;
    } else {
      _fallbackDishes.add(dish);
    }

    final client = _client;
    if (client == null) {
      _notifyChanged('menu_items');
      return dish;
    }
    try {
      await client.from('menu_items').upsert({
        'id': dish.id,
        'restaurant_id': dish.restaurantId,
        'name': dish.name,
        'restaurant': dish.restaurant,
        'category': dish.category,
        'price': dish.price,
        'description': dish.description,
        'is_available': dish.isAvailable,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase addMenuItem error: $e');
    }
    _notifyChanged('menu_items');
    return dish;
  }

  Future<LiveMenuDish> updateMenuItem(LiveMenuDish dish) => addMenuItem(dish);

  Future<void> deleteMenuItem(String id) async {
    _fallbackDishes.removeWhere((d) => d.id == id);
    final client = _client;
    if (client == null) {
      _notifyChanged('menu_items');
      return;
    }
    try {
      await client.from('menu_items').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteMenuItem error: $e');
    }
    _notifyChanged('menu_items');
  }

  Future<void> setDishAvailability(String id, bool available) async {
    final idx = _fallbackDishes.indexWhere((d) => d.id == id);
    if (idx != -1) {
      _fallbackDishes[idx] = _fallbackDishes[idx].copyWith(isAvailable: available);
    }

    final client = _client;
    if (client == null) {
      _notifyChanged('menu_items');
      return;
    }
    try {
      await client.from('menu_items').update({
        'is_available': available,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('Supabase setDishAvailability error: $e');
    }
    _notifyChanged('menu_items');
  }

  Future<void> toggleDishAvailability(String id, bool currentStatus) =>
      setDishAvailability(id, !currentStatus);

  // ==========================================
  // --- REVIEWS ---
  // ==========================================

  Stream<List<ReviewModel>> streamUserReviews(String userId) {
    final effectiveUid = (userId.isNotEmpty && userId != 'guest_id') ? userId : 'current_customer_id';
    
    final client = _client;
    if (client == null) {
      Future.microtask(() => _reviewsStreamController.add(List.from(_fallbackReviews)));
      return _reviewsStreamController.stream.map((list) {
        final active = list.where((r) => r.userId == effectiveUid).toList();
        active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return active;
      });
    }

    final controller = StreamController<List<ReviewModel>>.broadcast();
    StreamSubscription? supabaseSub;
    StreamSubscription? fallbackSub;

    controller.onListen = () {
      try {
        supabaseSub = client.from('reviews').stream(primaryKey: ['id']).listen(
          (data) {
            final active = data
                .where((row) => row['user_id']?.toString() == effectiveUid)
                .map((row) => ReviewModel.fromJson(row))
                .toList();
            active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            controller.add(active);
          },
          onError: (e) {
            // Table doesn't exist or RLS issue -> switch to fallback
            Future.microtask(() => _reviewsStreamController.add(List.from(_fallbackReviews)));
            fallbackSub = _reviewsStreamController.stream.listen((fallbackList) {
              final active = fallbackList.where((r) => r.userId == effectiveUid).toList();
              active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              controller.add(active);
            });
          },
        );
      } catch (_) {
        // Fallback immediately
        Future.microtask(() => _reviewsStreamController.add(List.from(_fallbackReviews)));
        fallbackSub = _reviewsStreamController.stream.listen((fallbackList) {
          final active = fallbackList.where((r) => r.userId == effectiveUid).toList();
          active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          controller.add(active);
        });
      }
    };

    controller.onCancel = () {
      supabaseSub?.cancel();
      fallbackSub?.cancel();
    };

    return controller.stream;
  }

  Future<void> addReview(ReviewModel review) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('reviews').insert(review.toJson());
        return; // Success, realtime will handle it
      } catch (e) {
        debugPrint('Supabase addReview error: $e');
        throw Exception(e.toString()); // Bubble up so UI shows the error toast
      }
    }
    
    // Fallback logic only if client is null (no Supabase configured at all)
    _fallbackReviews.add(review);
    _reviewsStreamController.add(List.from(_fallbackReviews));
  }
}

