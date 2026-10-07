import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';
import 'supabase_service.dart';

/// Read-only Admin snapshots. Privileged mutations need verified backend contracts.
/// Null means unconfigured; an empty result is a real, empty database result.
class AdminSupabaseService {
  SupabaseClient? get _client =>
      SupabaseService().isSupabaseConfigured ? Supabase.instance.client : null;

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
        .map((row) => <String, String>{
              'id': row['id'].toString(),
              'name': row['name']?.toString() ?? 'Restaurant',
              'cuisine': row['cuisine']?.toString() ?? 'General',
              'address': row['location']?.toString() ?? '',
              'price': 'Not provided',
              'phone': 'Not provided',
              'waitTime': row['est_wait']?.toString() ?? 'Not provided',
              'status': row['is_active'] == false
                  ? 'Inactive'
                  : row['is_queue_available'] == false
                      ? 'Few Tables Left'
                      : 'Tables Available',
            })
        .toList();
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
                // No persisted suspension column is established in this repository.
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
