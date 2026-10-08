import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant_queue_app/services/auth_service.dart';
import 'package:restaurant_queue_app/models/user_role.dart';

const uid = '11111111-1111-4111-8111-111111111111';

class FakeAuth {
  String role;
  bool fail = false;
  bool missing = false;
  int logins = 0;
  final requests = <http.Request>[];
  late final SupabaseClient client;
  FakeAuth(this.role) {
    client = SupabaseClient('http://local.test', 'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/token')) {
        logins++;
        if (fail)
          return http.Response(
              jsonEncode({
                'msg': 'Invalid login credentials',
                'code': 'invalid_credentials'
              }),
              400,
              request: request,
              headers: {'content-type': 'application/json'});
        final claims = base64Url
            .encode(utf8.encode(jsonEncode({
              'sub': uid,
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600
            })))
            .replaceAll('=', '');
        return http.Response(
            jsonEncode({
              'access_token': 'e30.$claims.test',
              'refresh_token': 'refresh-test',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': uid,
                'aud': 'authenticated',
                'email': 'admin123@gmail.com',
                'created_at': '2026-01-01T00:00:00Z',
                'app_metadata': {},
                'user_metadata': {'role': 'admin', 'full_name': 'Metadata Name'}
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      if (request.url.path.contains('/rest/v1/profiles')) {
        return http.Response(
            jsonEncode(missing
                ? []
                : [
                    {'id': uid, 'role': role, 'full_name': 'Database Name'}
                  ]),
            200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('/logout')) return http.Response('{}', 200);
      throw StateError('Unexpected endpoint ${request.url.path}');
    }));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final role in ['admin', 'manager', 'receptionist', 'customer']) {
    test('Supabase password login is used for $role and returns DB role',
        () async {
      final fake = FakeAuth(role);
      addTearDown(fake.client.dispose);
      final auth = AuthService.forTesting(fake.client);
      final profile =
          await auth.signIn(email: 'admin123@gmail.com', password: 'admin@123');
      expect(fake.logins, 1);
      expect(auth.currentUser?.id, uid);
      expect(profile.id, uid);
      expect(profile.role.value, role);
      expect(profile.fullName, 'Database Name');
      expect(profile.email, 'admin123@gmail.com');
      final query = fake.requests
          .firstWhere((r) => r.url.path.contains('/rest/v1/profiles'));
      expect(query.url.queryParameters['id'], 'eq.$uid');
      expect(query.url.queryParameters['select'], 'id,full_name,role');
      expect(query.headers['Authorization'], startsWith('Bearer '));
    });
  }
  for (final email in [
    'admin123@gmail.com',
    'manager123@gmail.com',
    'receptionist123@gmail.com'
  ]) {
    test('Failed Supabase login never returns fixed staff for $email',
        () async {
      final fake = FakeAuth('admin')..fail = true;
      addTearDown(fake.client.dispose);
      final auth = AuthService.forTesting(fake.client);
      await expectLater(
          auth.signIn(
              email: email,
              password: email.startsWith('admin')
                  ? 'admin@123'
                  : email.startsWith('manager')
                      ? 'manager@123'
                      : 'reception@123'),
          throwsA(isA<AuthException>()));
      expect(fake.logins, 1);
      expect(auth.isAuthenticated, false);
      expect(await auth.getCurrentUserProfile(), isNull);
    });
  }
  test('Current profile reloads real role rather than stale privileged cache',
      () async {
    final fake = FakeAuth('admin');
    addTearDown(fake.client.dispose);
    final auth = AuthService.forTesting(fake.client);
    await auth.signIn(email: 'admin123@gmail.com', password: 'admin@123');
    fake.role = 'customer';
    expect((await auth.getCurrentUserProfile())?.role, UserRole.customer);
    await auth.signOut();
    expect(auth.isAuthenticated, false);
    expect(await auth.getCurrentUserProfile(), isNull);
  });
  test('Missing DB profile fails closed and clears Supabase session', () async {
    final fake = FakeAuth('admin')..missing = true;
    addTearDown(fake.client.dispose);
    final auth = AuthService.forTesting(fake.client);
    await expectLater(
        auth.signIn(email: 'admin123@gmail.com', password: 'admin@123'),
        throwsA(isA<AuthException>()));
    expect(auth.currentUser, isNull);
  });
  test('Privileged local cache cannot restore a staff session', () async {
    SharedPreferences.setMockInitialValues({
      'dinequeue_active_user_id': 'local-id',
      'dinequeue_user_profile_local-id': jsonEncode({
        'id': 'local-id',
        'email': 'admin@local.test',
        'full_name': 'Cached Admin',
        'role': 'admin'
      }),
      'dinequeue_reg_user_admin@local.test': jsonEncode({
        'password': 'local-password',
        'profile': {
          'id': 'local-id',
          'email': 'admin@local.test',
          'full_name': 'Cached Admin',
          'role': 'admin'
        }
      }),
    });
    final auth = AuthService.forTesting(null);
    expect(await auth.getCurrentUserProfile(), isNull);
    await expectLater(
        auth.signIn(email: 'admin@local.test', password: 'local-password'),
        throwsA(isA<AuthException>()));
    expect(auth.isAuthenticated, false);
    final profile = await auth.getProfile('local-id',
        defaultEmail: 'admin@local.test', userMetadata: {'role': 'admin'});
    expect(profile.role, UserRole.customer);
  });
  test('Local registered customer with staff-like email remains customer',
      () async {
    final auth = AuthService.forTesting(null);
    await auth.signUp(
        email: 'admin.preview@local.test',
        password: 'local-password',
        fullName: 'Preview',
        role: UserRole.admin);
    await auth.signOut();
    final profile = await auth.signIn(
        email: 'admin.preview@local.test', password: 'local-password');
    expect(profile.role, UserRole.customer);
    expect(auth.currentUser, isNull);
    await auth.signOut();
    expect(await auth.getCurrentUserProfile(), isNull);
  });
}
