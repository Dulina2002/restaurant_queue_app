import 'package:flutter/foundation.dart';
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

  Future<List<Map<String, dynamic>>?> loadUsers() async {
    final client = _client;
    if (client == null) return null;

    try {
      final rows = await client
          .from('profiles')
          .select(
            'id,full_name,role',
          )
          .timeout(const Duration(seconds: 15));

      return rows
          .map((row) => <String, dynamic>{
                'id': row['id'].toString(),
                'name': row['full_name']?.toString() ?? 'User',
                'email': 'Email not available',
                'role': UserRole.fromString(row['role']?.toString()) ==
                        UserRole.admin
                    ? 'Admin'
                    : UserRole.fromString(row['role']?.toString()).displayName,
                'suspended': false,
              })
          .toList();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Admin Supabase profiles read failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    }
  }
}
