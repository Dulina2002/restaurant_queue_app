import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';
import 'supabase_service.dart';

class AdminSupabaseService {
  SupabaseClient? get _client =>
      SupabaseService().isSupabaseConfigured ? Supabase.instance.client : null;

  Map<String, String> _mapRestaurant(Map<String, dynamic> row) {
    return <String, String>{
      'id': row['id'].toString(),
      'name': row['name']?.toString() ?? 'Restaurant',
      'cuisine': row['cuisine']?.toString() ?? 'General',
      'address': row['location']?.toString() ?? '',
      // These columns do not currently exist in the deployed restaurants table.
      'price': 'Not provided',
      'phone': 'Not provided',
      'waitTime': row['est_wait']?.toString() ?? 'Not provided',
      'status': row['is_active'] == false
          ? 'Inactive'
          : row['is_queue_available'] == false
              ? 'Few Tables Left'
              : 'Tables Available',
    };
  }

  String _generateRestaurantId(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final safeSlug = slug.isEmpty ? 'restaurant' : slug;

    return '${safeSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<List<Map<String, String>>?> loadRestaurants() async {
    final client = _client;
    if (client == null) return null;

    final rows = await client
        .from('restaurants')
        .select(
          'id,name,cuisine,location,is_active,is_queue_available,est_wait',
        )
        .timeout(const Duration(seconds: 15));

    return rows
        .map(
          (row) => _mapRestaurant(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<Map<String, String>?> addRestaurant({
    required String name,
    required String cuisine,
    required String location,
    required String estimatedWait,
  }) async {
    final client = _client;
    if (client == null) return null;

    final id = _generateRestaurantId(name);

    final row = await client
        .from('restaurants')
        .insert({
          'id': id,
          'name': name,
          'cuisine': cuisine,
          // tag is required by the current deployed schema.
          'tag': cuisine,
          'location': location.trim().isEmpty
              ? 'Address not provided'
              : location.trim(),
          'is_active': true,
          'is_queue_available': true,
          'est_wait': estimatedWait.trim().isEmpty
              ? 'Direct Seating'
              : estimatedWait.trim(),
        })
        .select(
          'id,name,cuisine,location,is_active,is_queue_available,est_wait',
        )
        .single()
        .timeout(const Duration(seconds: 15));

    return _mapRestaurant(Map<String, dynamic>.from(row));
  }

  Future<Map<String, String>?> updateRestaurant({
    required String id,
    required String name,
    required String cuisine,
    required String location,
    required String estimatedWait,
  }) async {
    final client = _client;
    if (client == null) return null;

    final row = await client
        .from('restaurants')
        .update({
          'name': name,
          'cuisine': cuisine,
          'tag': cuisine,
          'location': location.trim().isEmpty
              ? 'Address not provided'
              : location.trim(),
          'est_wait': estimatedWait.trim().isEmpty
              ? 'Direct Seating'
              : estimatedWait.trim(),
        })
        .eq('id', id)
        .select(
          'id,name,cuisine,location,is_active,is_queue_available,est_wait',
        )
        .single()
        .timeout(const Duration(seconds: 15));

    return _mapRestaurant(Map<String, dynamic>.from(row));
  }

  Future<Map<String, String>?> toggleRestaurantAvailability({
    required String id,
    required bool makeAvailable,
  }) async {
    final client = _client;
    if (client == null) return null;

    final row = await client
        .from('restaurants')
        .update({
          'is_queue_available': makeAvailable,
          'est_wait': makeAvailable ? '0m' : '15m',
        })
        .eq('id', id)
        .select(
          'id,name,cuisine,location,is_active,is_queue_available,est_wait',
        )
        .single()
        .timeout(const Duration(seconds: 15));

    return _mapRestaurant(Map<String, dynamic>.from(row));
  }

  Future<bool> deleteRestaurant(String id) async {
    final client = _client;
    if (client == null) return false;

    final deletedRows = await client
        .from('restaurants')
        .delete()
        .eq('id', id)
        .select('id')
        .timeout(const Duration(seconds: 15));

    return deletedRows.isNotEmpty;
  }

  Map<String, dynamic> _mapUser(dynamic row) => {
        'id': row['id'],
        'name': row['full_name'] ?? 'User',
        'email': row['email'] ?? '',
        'role': row['role'] == null
            ? 'Profile missing'
            : row['role'] == 'admin'
                ? 'Admin'
                : UserRole.fromString(row['role']).displayName,
        'suspended': row['suspended'] == true,
      };

  Future<dynamic> _usersRequest(Map<String, dynamic> body) async {
    final client = _client;
    final token = client?.auth.currentSession?.accessToken;
    if (client == null || token == null) {
      throw StateError('Sign in with Supabase to manage users.');
    }
    try {
      final response = await client.functions.invoke('admin-users',
          body: body, headers: {'Authorization': 'Bearer $token'});
      final payload = response.data;
      if (payload is! Map || payload['success'] != true) {
        throw StateError(payload is Map
            ? payload['error']?.toString() ?? 'Admin request failed.'
            : 'Invalid Admin response.');
      }
      return payload['data'];
    } on FunctionException catch (error) {
      final details = error.details;
      throw StateError(details is Map
          ? details['error']?.toString() ??
              'Admin request failed (${error.status}).'
          : 'Admin request failed (${error.status}). Check function deployment and permissions.');
    }
  }

  Future<List<Map<String, dynamic>>?> loadUsers() async {
    if (_client == null) return null;
    final rows = await _usersRequest({'action': 'list'}) as List;
    return rows.map(_mapUser).toList();
  }

  Future<Map<String, dynamic>> inviteUser(
          {required String email,
          required String fullName,
          required String role}) async =>
      _mapUser(await _usersRequest({
        'action': 'invite',
        'email': email,
        'full_name': fullName,
        'role': role.toLowerCase()
      }));

  Future<Map<String, dynamic>> changeUserRole(
          {required String id, required String role}) async =>
      _mapUser(await _usersRequest({
        'action': 'change_role',
        'user_id': id,
        'role': role.toLowerCase()
      }));

  Future<Map<String, dynamic>> setUserSuspended(
          {required String id, required bool suspended}) async =>
      _mapUser(await _usersRequest(
          {'action': suspended ? 'suspend' : 'activate', 'user_id': id}));

  Future<void> deleteUser(String id) async {
    await _usersRequest({'action': 'delete', 'user_id': id});
  }
}
