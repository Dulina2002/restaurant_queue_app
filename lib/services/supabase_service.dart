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

  // Add a user to the queue
  Future<void> joinQueue(String restaurantId, String userId, int partySize) async {
    await _client.from('queue_entries').insert({
      'restaurant_id': restaurantId,
      'user_id': userId,
      'party_size': partySize,
      'status': 'waiting',
    });
  }

  // Get active restaurants
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response = await _client
          .from('restaurants')
          .select()
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
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
