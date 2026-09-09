import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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
    final response = await _client
        .from('restaurants')
        .select()
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Authentication ---

  // Sign In
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Up with Role
  Future<AuthResponse> signUp(String email, String password, String fullName, String role) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Insert profile data
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'role': role.toLowerCase(), // Ensure lowercase matching schema
      });
    }

    return response;
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select('role, full_name')
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }
}
