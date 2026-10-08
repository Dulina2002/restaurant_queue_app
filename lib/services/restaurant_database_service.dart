import 'dart:async';
import '../models/restaurant_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import '../features/manager/data/models/physical_table_model.dart';
import '../features/manager/data/models/live_menu_dish_model.dart';
import '../features/manager/data/models/manager_dashboard_model.dart';
import 'supabase_service.dart';

/// Single data-access entry point for restaurants, queue, tables, menu and
/// reservations.
///
/// When Supabase is configured every read is a live database stream scoped to
/// the requested restaurant id and every write goes to the database (errors
/// are thrown so the UI can report them). The in-memory lists below are only
/// used for offline/demo mode when Supabase credentials are missing.
class RestaurantDatabaseService {
  static final RestaurantDatabaseService _instance = RestaurantDatabaseService._internal();
  factory RestaurantDatabaseService() => _instance;
  RestaurantDatabaseService._internal();

  final SupabaseService _supabaseService = SupabaseService();


  // ==========================================
  // --- 1. RESTAURANTS ---
  // ==========================================

  Stream<List<RestaurantModel>> streamActiveRestaurants() {
    return _supabaseService.streamActiveRestaurants();
  }

  /// Every restaurant in the database, used by the manager restaurant picker.
  Stream<List<RestaurantModel>> streamManagedRestaurants() {
    return _supabaseService.streamManagedRestaurants();
  }

  Future<RestaurantModel> addRestaurant(String name) {
    return _supabaseService.addRestaurant(name);
  }

  Future<List<RestaurantModel>> getActiveRestaurants() async {
    return _supabaseService.streamActiveRestaurants().first;
  }

  Future<RestaurantModel?> getRestaurant(String id) async {
    return _supabaseService.getRestaurant(id);
  }

  // ==========================================
  // --- 2. LIVE QUEUE ---
  // ==========================================

  /// Active (waiting / called) parties for one restaurant, oldest first.
  Stream<List<QueueEntryModel>> streamQueue(String restaurantId) {
    return _supabaseService.streamQueueEntries(restaurantId);
  }

  Stream<List<QueueEntryModel>> streamActiveQueue({String restaurantId = 'All'}) {
    return streamQueue(restaurantId);
  }

  Stream<QueueEntryModel?> streamCustomerActiveQueue(String userId) {
    return _supabaseService.streamCustomerActiveQueue(userId);
  }

  /// Every queue entry (including seated / cancelled) for one restaurant.
  Stream<List<QueueEntryModel>> streamAllQueueEntries({String restaurantId = 'All'}) {
    return _supabaseService.streamQueueEntries(restaurantId, activeOnly: false);
  }

  Future<QueueEntryModel> joinQueue({
    required String restaurantId,
    required String restaurantName,
    required String userId,
    required String guestName,
    required int partySize,
    required String phoneNumber,
  }) async {
    return _supabaseService.joinQueue(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: userId,
      guestName: guestName,
      partySize: partySize,
      phoneNumber: phoneNumber,
    );
  }

  Future<QueueEntryModel> walkInQueue({
    required String guestName,
    required int partySize,
    required String phoneNumber,
    required String restaurantId,
    required String restaurantName,
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
    String? restaurantId,
  }) async {
    await _supabaseService.updateQueueStatus(queueId, status);
  }

  /// Marks the next [count] waiting parties of a restaurant as `called` so
  /// their customer apps show the table is ready. Returns how many were called.
  Future<int> callNextWaitingParties(String restaurantId, int count) async {
    return _supabaseService.callNextWaitingParties(restaurantId, count);
  }

  Future<void> leaveQueue({required String queueId, required String restaurantId}) async {
    await _supabaseService.leaveQueue(queueId: queueId, restaurantId: restaurantId);
  }

  // ==========================================
  // --- 3. TABLES MANAGEMENT ---
  // ==========================================

  /// Live tables for one restaurant id ('All' = every restaurant).
  Stream<List<PhysicalTable>> streamTables({String restaurantId = 'All'}) {
    return _supabaseService.streamTables(restaurantId: restaurantId);
  }

  Future<List<PhysicalTable>> getTables({String restaurantId = 'ocean_bistro'}) async {
    return _supabaseService.getTables(restaurantId: restaurantId);
  }

  Future<PhysicalTable> addTable(PhysicalTable table) async {
    final newTable = table.copyWith(id: table.id.isEmpty ? 'tbl_${DateTime.now().millisecondsSinceEpoch}' : table.id);
    return _supabaseService.addTable(newTable);
  }

  Future<PhysicalTable> updateTable(PhysicalTable table) => addTable(table);

  Future<void> deleteTable(String id) async {
    await _supabaseService.deleteTable(id);
  }

  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    await setTablesStatus([tableId], status);
  }

  Future<void> setTablesStatus(List<String> ids, TableStatus status, {String? guestName}) async {
    await _supabaseService.setTablesStatus(ids, status, guestName: guestName);
  }

  /// Seat a specific guest at a physical table
  Future<void> seatGuestAtTable({
    required String tableId,
    required String guestName,
    String? queueId,
  }) async {
    await _supabaseService.seatGuestAtTable(tableId: tableId, guestName: guestName, queueId: queueId);
  }

  /// Seat the next waiting queue party of the table's restaurant at [tableId].
  Future<QueueEntryModel?> seatNextQueueParty({required String tableId}) async {
    return _supabaseService.seatNextQueueParty(tableId: tableId);
  }

  /// Bulk turn specified tables to available
  Future<void> bulkQuickTurnTables(List<String> tableIds) async {
    await _supabaseService.bulkQuickTurnTables(tableIds);
  }

  // ==========================================
  // --- 4. LIVE MENU DISHES ---
  // ==========================================

  /// Live dishes for one restaurant id ('All' = every restaurant).
  Stream<List<LiveMenuDish>> streamLiveMenu({String restaurantId = 'All'}) {
    return _supabaseService.streamMenuDishes(restaurantId: restaurantId);
  }

  Future<LiveMenuDish> addMenuItem(LiveMenuDish dish) async {
    final newDish = dish.copyWith(id: dish.id.isEmpty ? 'dish_${DateTime.now().millisecondsSinceEpoch}' : dish.id);
    return _supabaseService.addMenuItem(newDish);
  }

  Future<LiveMenuDish> addDish(LiveMenuDish dish) => addMenuItem(dish);

  Future<LiveMenuDish> updateMenuItem(LiveMenuDish dish) => addMenuItem(dish);

  Future<LiveMenuDish> updateDish(LiveMenuDish dish) => updateMenuItem(dish);

  Future<void> deleteMenuItem(String id) async {
    await _supabaseService.deleteMenuItem(id);
  }

  Future<void> deleteDish(String id) => deleteMenuItem(id);

  /// Sets a dish explicitly available (true) or 86'd (false).
  Future<void> setDishAvailability(String id, bool available) async {
    await _supabaseService.setDishAvailability(id, available);
  }

  /// Flips availability relative to [currentStatus].
  Future<void> toggleDishAvailability(String id, bool currentStatus) =>
      _supabaseService.toggleDishAvailability(id, currentStatus);


  // ==========================================
  // --- 5. RESERVATIONS ---
  // ==========================================

  Stream<List<ReservationModel>> streamReservations({String restaurantId = 'All'}) {
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

  // ==========================================
  // --- 6. REVIEWS ---
  // ==========================================

  Stream<List<ReviewModel>> streamUserReviews(String userId) {
    return _supabaseService.streamUserReviews(userId);
  }

  Future<void> addReview(ReviewModel review) async {
    return await _supabaseService.addReview(review);
  }

  // ==========================================
  // --- 7. MANAGER LIVE DASHBOARD ---
  // ==========================================

  /// Combines the live tables, queue and reservation streams of ONE restaurant
  /// into a single [ManagerLiveSnapshot]. Switching restaurants simply means
  /// subscribing to a new snapshot stream with the new id.
  Stream<ManagerLiveSnapshot> streamManagerSnapshot(String restaurantId) {
    late final StreamController<ManagerLiveSnapshot> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    List<PhysicalTable>? tables;
    List<QueueEntryModel>? queue;
    List<ReservationModel>? reservations;

    void emit() {
      if (controller.isClosed) return;
      controller.add(ManagerLiveSnapshot(
        tables: tables ?? const [],
        queue: queue ?? const [],
        reservations: reservations ?? const [],
      ));
    }

    controller = StreamController<ManagerLiveSnapshot>.broadcast(
      onListen: () {
        subscriptions.add(streamTables(restaurantId: restaurantId).listen(
          (value) {
            tables = value;
            emit();
          },
          onError: controller.addError,
        ));
        // Queue / reservation failures degrade to "empty" instead of blanking
        // the whole dashboard, since the floor data is still valid.
        subscriptions.add(streamAllQueueEntries(restaurantId: restaurantId).listen(
          (value) {
            queue = value;
            emit();
          },
          onError: (Object _) {
            queue ??= const [];
            emit();
          },
        ));
        subscriptions.add(streamReservations(restaurantId: restaurantId).listen(
          (value) {
            reservations = value;
            emit();
          },
          onError: (Object _) {
            reservations ??= const [];
            emit();
          },
        ));
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
        subscriptions.clear();
      },
    );
    return controller.stream;
  }

  Future<void> seedInitialDataIfEmpty() async {
    // Initial data is handled by Supabase / in-memory fallbacks
  }
}

// Backward compatibility alias for any un-updated references
typedef FirestoreService = RestaurantDatabaseService;
