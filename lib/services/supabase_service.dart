import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// Active Service for Supabase Operations with standard fallbacks
class SupabaseService {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> listenToQueue(String restaurantId) {
    final client = _client;
    if (client != null) {
      return client
          .from('queue_entries')
          .stream(primaryKey: ['id'])
          .eq('restaurant_id', restaurantId)
          .order('position', ascending: true);
    }
    return _firestore.streamQueue(restaurantId).map((list) => list.map((item) => item.toFirestore()).toList());
  }

  Future<void> joinQueue(String restaurantId, String userId, int partySize) async {
    final client = _client;
    if (client != null) {
      final guestName = client.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'Guest';
      await client.from('queue_entries').insert({
        'restaurant_id': restaurantId,
        'restaurant_name': 'Ocean Bistro',
        'user_id': userId.isNotEmpty ? userId : client.auth.currentUser?.id,
        'guest_name': guestName,
        'party_size': partySize,
        'phone_number': '',
        'status': 'waiting',
        'queue_number': 'Q-${100 + DateTime.now().second}',
        'position': 1,
        'estimated_wait_minutes': 15,
      });
      return;
    }
    await _firestore.joinQueue(
      restaurantId: restaurantId,
      restaurantName: 'Ocean Bistro',
      userId: userId,
      guestName: 'Guest',
      partySize: partySize,
      phoneNumber: '',
    );
  }

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client.from('restaurants').select().eq('is_active', true);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        debugPrint('Supabase getRestaurants notice: $e');
      }
    }
    final restaurants = await _firestore.getActiveRestaurants();
    return restaurants.map((r) => r.toFirestore()).toList();
  }

  Future<UserProfile> signIn(String email, String password) async {
    final client = _client;
    if (client != null) {
      try {
        final AuthResponse res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) {
          final profileData = await client.from('profiles').select().eq('id', res.user!.id).maybeSingle();
          if (profileData != null) {
            return UserProfile.fromJson(profileData, defaultEmail: email);
          }
          return UserProfile(
            id: res.user!.id,
            email: email,
            fullName: res.user!.userMetadata?['full_name'] ?? 'User',
            role: UserRole.fromString(res.user!.userMetadata?['role']),
          );
        }
      } catch (e) {
        debugPrint('Supabase signIn notice: $e');
      }
    }
    return await _auth.signIn(email: email, password: password);
  }

  Future<UserProfile> signUp(String email, String password, String fullName, [String role = 'customer']) async {
    final client = _client;
    if (client != null) {
      try {
        final AuthResponse res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': role,
          },
        );
        if (res.user != null) {
          final userProfile = UserProfile(
            id: res.user!.id,
            email: email,
            fullName: fullName,
            role: UserRole.fromString(role),
          );
          await client.from('profiles').upsert(userProfile.toJson());
          return userProfile;
        }
      } catch (e) {
        debugPrint('Supabase signUp notice: $e');
      }
    }
    return await _auth.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: UserRole.fromString(role),
    );
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final uid = client.auth.currentUser!.id;
        final profileData = await client.from('profiles').select().eq('id', uid).maybeSingle();
        if (profileData != null) {
          return UserProfile.fromJson(profileData, defaultEmail: client.auth.currentUser!.email);
        }
      } catch (e) {
        debugPrint('Supabase getCurrentUserProfile notice: $e');
      }
    }
    return await _auth.getCurrentUserProfile();
  }
}
