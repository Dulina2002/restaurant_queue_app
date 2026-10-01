import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _auth = AuthService();

  // Realtime subscription for a restaurant's queue
  Stream<List<Map<String, dynamic>>> listenToQueue(String restaurantId) {
    return _client
        .from('queue_entries')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: true);
  }

  // Realtime subscription for user's active queue
  Stream<List<Map<String, dynamic>>> listenToUserQueue(String userId) {
    return _client
        .from('queue_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .map((events) => events.where((e) => e['status'] == 'waiting').toList());
  }

  // Realtime subscription for user's bookings
  Stream<List<Map<String, dynamic>>> listenToUserBookings(String userId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('booking_date', ascending: true);
  }

  // Realtime subscription for restaurant's bookings
  Stream<List<Map<String, dynamic>>> listenToRestaurantBookings(String restaurantId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .map((events) => events.where((e) => e['status'] == 'confirmed').toList());
  }

  // Add a user to the queue
  Future<void> joinQueue(String restaurantId, String userId, int partySize) async {
    await _client.from('queue_entries').insert({
      'restaurant_id': restaurantId,
      'user_id': userId,
      'party_size': partySize,
      'status': 'waiting',
    });
  }

  // Update a queue entry status
  Future<void> updateQueueEntryStatus(String entryId, String status) async {
    print('Attempting to update queue entry $entryId to status $status');
    final response = await _client.from('queue_entries').update({
      'status': status,
    }).eq('id', entryId).select();
    print('Update queue entry response: $response');
  }

  // Create a booking
  Future<void> createBooking({
    required String restaurantId,
    required String userId,
    required DateTime bookingDate,
    required int partySize,
  }) async {
    await _client.from('bookings').insert({
      'restaurant_id': restaurantId,
      'user_id': userId,
      'party_size': partySize,
      'booking_date': bookingDate.toIso8601String(),
      'status': 'confirmed',
    });
  }

  // Update a booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _client.from('bookings').update({
      'status': status,
    }).eq('id', bookingId);
  }

  // Get active restaurants
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response = await _client
          .from('restaurants')
          .select()
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  // --- Authentication Wrappers ---

  Future<UserProfile> signIn(String email, String password) async {
    return await _auth.signIn(email: email, password: password);
  }

  Future<UserProfile> signUp(String email, String password, String fullName, [String role = 'customer']) async {
    return await _auth.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: UserRole.fromString(role),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    return await _auth.getCurrentUserProfile();
  }
}
