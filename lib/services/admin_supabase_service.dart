import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';
import 'supabase_service.dart';
import 'restaurant_image_storage.dart';

class AdminSupabaseService {
  SupabaseClient get _requiredClient {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured.');
    return client;
  }

  Map<String, dynamic> _mapBroadcast(Map<String, dynamic> row) => {
        'id': row['id'],
        'title': row['title'] ?? '',
        'message': row['message'] ?? '',
        'priority': row['priority'] ?? 'NORMAL',
        'isActive': row['is_active'] == true,
        'createdAt': row['created_at'],
        'createdBy': row['created_by'],
      };

  Future<List<Map<String, dynamic>>> loadBroadcasts() async {
    final rows = await _requiredClient
        .from('broadcasts')
        .select('id,title,message,priority,is_active,created_at,created_by')
        .order('created_at', ascending: false);
    return rows.map((row) => _mapBroadcast(row)).toList();
  }

  Future<Map<String, dynamic>> createBroadcast(
      {required String title,
      required String message,
      required String priority}) async {
    if (!['NORMAL', 'WARNING', 'URGENT'].contains(priority)) {
      throw ArgumentError('Invalid announcement priority.');
    }
    if (title.trim().isEmpty || message.trim().isEmpty) {
      throw ArgumentError('Announcement title and message are required.');
    }
    final row = await _requiredClient
        .from('broadcasts')
        .insert({
          'title': title.trim(),
          'message': message.trim(),
          'priority': priority,
        })
        .select('id,title,message,priority,is_active,created_at,created_by')
        .single();
    return _mapBroadcast(row);
  }

  Future<bool> loadPlatformFreeze() async {
    final row = await _requiredClient
        .from('platform_settings')
        .select('platform_frozen')
        .eq('id', 'global')
        .maybeSingle();
    if (row == null || row['platform_frozen'] is! bool) {
      throw StateError(
          'The global platform settings row is missing or invalid.');
    }
    return row['platform_frozen'] as bool;
  }

  Future<bool> setPlatformFreeze(bool frozen) async {
    final result = await _requiredClient
        .rpc('set_platform_freeze', params: {'p_frozen': frozen});
    final dynamic row =
        result is List && result.length == 1 ? result.single : result;
    if (row is! Map || row['platform_frozen'] is! bool) {
      throw StateError('Invalid platform freeze confirmation from Supabase.');
    }
    return row['platform_frozen'] as bool;
  }

  Future<int> flushWaitlists() async {
    final result = await _requiredClient.rpc('flush_waitlists');
    if (result is! int || result < 0) {
      throw StateError('Invalid waitlist cancellation count from Supabase.');
    }
    return result;
  }

  SupabaseClient? get _client =>
      SupabaseService().isSupabaseConfigured ? Supabase.instance.client : null;

  Map<String, String> _mapRestaurant(Map<String, dynamic> row) {
    final estWait = row['est_wait']?.toString() ?? '0m';
    final numbers = estWait.replaceAll(RegExp(r'[^0-9]'), '');
    final waitMinutes = int.tryParse(numbers) ?? 0;
    final id = row['id']?.toString() ?? '';
    final name = row['name']?.toString() ?? 'Restaurant';
    final cuisine = row['cuisine']?.toString() ?? 'General';
    final customSaved = RestaurantImageStorage().getImage(
      id: id,
      name: name,
      enableCulinaryFallback: false,
    );
    var img = (customSaved != null && customSaved.trim().isNotEmpty)
        ? customSaved.trim()
        : row['image_url']?.toString();
    if (img == null || img.trim().isEmpty) {
      img = RestaurantImageStorage().getImage(id: id, name: name, cuisine: cuisine);
    }

    return <String, String>{
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'address': row['location']?.toString() ?? '',
      // These columns do not currently exist in the deployed restaurants table.
      'price': 'Not provided',
      'phone': 'Not provided',
      'waitTime': '${waitMinutes}m',
      'imageUrl': img ?? '',
      'status': row['is_active'] == false
          ? 'Inactive'
          : waitMinutes > 0
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

  static bool? _hasImageUrlColumn;

  bool _isMissingImageUrlError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('image_url') || str.contains('42703');
  }

  Future<List<Map<String, String>>?> loadRestaurants() async {
    final client = _client;
    if (client == null) return null;

    List<dynamic> rows;
    if (_hasImageUrlColumn == false) {
      rows = await client
          .from('restaurants')
          .select(
            'id,name,cuisine,location,is_active,is_queue_available,est_wait',
          )
          .timeout(const Duration(seconds: 15));
    } else {
      try {
        rows = await client
            .from('restaurants')
            .select(
              'id,name,cuisine,location,is_active,is_queue_available,est_wait,image_url',
            )
            .timeout(const Duration(seconds: 15));
        _hasImageUrlColumn = true;
      } catch (e) {
        if (_isMissingImageUrlError(e)) {
          _hasImageUrlColumn = false;
        }
        rows = await client
            .from('restaurants')
            .select(
              'id,name,cuisine,location,is_active,is_queue_available,est_wait',
            )
            .timeout(const Duration(seconds: 15));
      }
    }

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
    String? imageUrl,
  }) async {
    final client = _client;
    if (client == null) return null;

    final id = _generateRestaurantId(name);
    final numbers = estimatedWait.replaceAll(RegExp(r'[^0-9]'), '');
    final waitMinutes = int.tryParse(numbers) ?? 0;
    final isQueue = waitMinutes > 0;
    final cleanWait = '${waitMinutes}m';

    if (imageUrl != null && imageUrl.isNotEmpty) {
      RestaurantImageStorage().saveImage(id: id, name: name, imageUrl: imageUrl);
    }

    final insertPayload = <String, dynamic>{
      'id': id,
      'name': name,
      'cuisine': cuisine,
      // tag is required by the current deployed schema.
      'tag': cuisine,
      'location': location.trim().isEmpty
          ? 'Address not provided'
          : location.trim(),
      'is_active': true,
      'is_queue_available': isQueue,
      'est_wait': cleanWait,
    };

    dynamic row;
    if (_hasImageUrlColumn == false) {
      row = await client
          .from('restaurants')
          .insert(insertPayload)
          .select(
            'id,name,cuisine,location,is_active,is_queue_available,est_wait',
          )
          .single()
          .timeout(const Duration(seconds: 15));
    } else {
      final payloadWithImg = Map<String, dynamic>.from(insertPayload);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        payloadWithImg['image_url'] = imageUrl;
      }

      try {
        row = await client
            .from('restaurants')
            .insert(payloadWithImg)
            .select(
              'id,name,cuisine,location,is_active,is_queue_available,est_wait,image_url',
            )
            .single()
            .timeout(const Duration(seconds: 15));
        _hasImageUrlColumn = true;
      } catch (e) {
        if (_isMissingImageUrlError(e)) {
          _hasImageUrlColumn = false;
        }
        row = await client
            .from('restaurants')
            .insert(insertPayload)
            .select(
              'id,name,cuisine,location,is_active,is_queue_available,est_wait',
            )
            .single()
            .timeout(const Duration(seconds: 15));
      }
    }

    final mapped = _mapRestaurant(Map<String, dynamic>.from(row));
    if (imageUrl != null && imageUrl.isNotEmpty && (mapped['imageUrl'] == null || mapped['imageUrl']!.isEmpty)) {
      mapped['imageUrl'] = imageUrl;
    }
    return mapped;
  }

  Future<Map<String, String>?> updateRestaurant({
    required String id,
    required String name,
    required String cuisine,
    required String location,
    required String estimatedWait,
    String? imageUrl,
  }) async {
    final client = _client;
    if (client == null) return null;

    final numbers = estimatedWait.replaceAll(RegExp(r'[^0-9]'), '');
    final waitMinutes = int.tryParse(numbers) ?? 0;
    final isQueue = waitMinutes > 0;
    final cleanWait = '${waitMinutes}m';

    if (imageUrl != null && imageUrl.isNotEmpty) {
      RestaurantImageStorage().saveImage(id: id, name: name, imageUrl: imageUrl);
    }

    final basePayload = <String, dynamic>{
      'name': name,
      'cuisine': cuisine,
      'tag': cuisine,
      'location': location.trim().isEmpty
          ? 'Address not provided'
          : location.trim(),
      'est_wait': cleanWait,
      'is_queue_available': isQueue,
    };

    dynamic row;
    if (_hasImageUrlColumn == false) {
      row = await client
          .from('restaurants')
          .update(basePayload)
          .eq('id', id)
          .select(
            'id,name,cuisine,location,is_active,is_queue_available,est_wait',
          )
          .single()
          .timeout(const Duration(seconds: 15));
    } else {
      final payloadWithImg = Map<String, dynamic>.from(basePayload);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        payloadWithImg['image_url'] = imageUrl;
      }

      try {
        row = await client
            .from('restaurants')
            .update(payloadWithImg)
            .eq('id', id)
            .select(
              'id,name,cuisine,location,is_active,is_queue_available,est_wait,image_url',
            )
            .single()
            .timeout(const Duration(seconds: 15));
        _hasImageUrlColumn = true;
      } catch (e) {
        if (_isMissingImageUrlError(e)) {
          _hasImageUrlColumn = false;
        }
        row = await client
            .from('restaurants')
            .update(basePayload)
            .eq('id', id)
            .select(
              'id,name,cuisine,location,is_active,is_queue_available,est_wait',
            )
            .single()
            .timeout(const Duration(seconds: 15));
      }
    }

    final mapped = _mapRestaurant(Map<String, dynamic>.from(row));
    if (imageUrl != null && imageUrl.isNotEmpty && (mapped['imageUrl'] == null || mapped['imageUrl']!.isEmpty)) {
      mapped['imageUrl'] = imageUrl;
    }
    return mapped;
  }

  Future<Map<String, String>?> toggleRestaurantAvailability({
    required String id,
    required bool makeAvailable,
  }) async {
    final client = _client;
    if (client == null) return null;

    final updatePayload = {
      'is_queue_available': !makeAvailable,
      'est_wait': makeAvailable ? '0m' : '15m',
    };

    final row = await client
        .from('restaurants')
        .update(updatePayload)
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
