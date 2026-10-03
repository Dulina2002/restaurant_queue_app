import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// Legacy Service Alias wrapping Firebase Operations
class SupabaseService {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

  Stream<List<Map<String, dynamic>>> listenToQueue(String restaurantId) {
    return _firestore.streamQueue(restaurantId).map((list) => list.map((item) => item.toFirestore()).toList());
  }

  Future<void> joinQueue(String restaurantId, String userId, int partySize) async {
    await _firestore.joinQueue(
      restaurantId: restaurantId,
      restaurantName: 'Ocean Bistro',
      userId: userId,
      guestName: _auth.currentUser?.displayName ?? 'Guest',
      partySize: partySize,
      phoneNumber: '',
    );
  }

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final restaurants = await _firestore.getActiveRestaurants();
    return restaurants.map((r) => r.toFirestore()).toList();
  }

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
