import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/admin/admin_dashboard_screen.dart';
import 'package:restaurant_queue_app/services/admin_supabase_service.dart';

Map<String, dynamic> record(
        {String role = 'Customer', bool suspended = false}) =>
    {
      'id': 'backend-id',
      'name': 'Backend Person',
      'email': 'real@example.com',
      'role': role,
      'suspended': suspended,
    };

class FakeUsers extends AdminSupabaseService {
  @override
  Future<List<Map<String, dynamic>>> loadBroadcasts() async => [];
  @override
  Future<bool> loadPlatformFreeze() async => false;
  var pending = Completer<Map<String, dynamic>>();
  final deletion = Completer<void>();
  bool fail = false;
  int calls = 0;
  @override
  Future<List<Map<String, String>>?> loadRestaurants() async => [];
  @override
  Future<List<Map<String, dynamic>>?> loadUsers() async => [record()];
  Future<Map<String, dynamic>> result() {
    calls++;
    if (fail) return Future.error(StateError('Backend rejected operation'));
    return pending.future;
  }

  @override
  Future<Map<String, dynamic>> inviteUser(
          {required String email,
          required String fullName,
          required String role}) =>
      result();
  @override
  Future<Map<String, dynamic>> changeUserRole(
          {required String id, required String role}) =>
      result();
  @override
  Future<Map<String, dynamic>> setUserSuspended(
          {required String id, required bool suspended}) =>
      result();
  @override
  Future<void> deleteUser(String id) {
    calls++;
    if (fail) return Future.error(StateError('Backend rejected operation'));
    return deletion.future;
  }
}

Future<void> open(WidgetTester t, FakeUsers service) async {
  t.view.physicalSize = const Size(1400, 1100);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(MaterialApp(
      home: AdminDashboardScreen(
          profile: const UserProfile(
              id: 'admin', email: '', fullName: 'Admin', role: UserRole.admin),
          adminService: service)));
  await t.pumpAndSettle();
  await t.tap(find.text('Users'));
  await t.pumpAndSettle();
}

Future<void> invite(WidgetTester t) async {
  await t.tap(find.text('New User'));
  await t.pumpAndSettle();
  await t.enterText(find.byType(TextField).at(0), 'Invited Person');
  await t.enterText(find.byType(TextField).at(1), 'invited@example.com');
  await t.tap(find.text('Invite User'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Backend email and profile are rendered', (t) async {
    await open(t, FakeUsers());
    expect(find.text('Backend Person'), findsOneWidget);
    expect(find.text('real@example.com'), findsOneWidget);
  });
  testWidgets('Invite waits for server success', (t) async {
    final s = FakeUsers();
    await open(t, s);
    await invite(t);
    expect(s.calls, 1);
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'Invited Person'),
        findsNothing);
    expect(find.text('Add New User'), findsOneWidget);
    s.pending.complete({...record(), 'id': 'new', 'name': 'Invited Person'});
    await t.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'Invited Person'),
        findsOneWidget);
    expect(find.text('Add New User'), findsNothing);
  });
  testWidgets('Failed invite keeps dialog and list unchanged', (t) async {
    final s = FakeUsers()..fail = true;
    await open(t, s);
    await invite(t);
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'Invited Person'),
        findsNothing);
    expect(find.text('Add New User'), findsOneWidget);
    expect(find.textContaining('Backend rejected'), findsOneWidget);
  });
  for (final fail in [false, true]) {
    testWidgets('Change role only changes after success, failure=$fail',
        (t) async {
      final s = FakeUsers()..fail = fail;
      await open(t, s);
      await t.tap(find.text('Change Role'));
      await t.pumpAndSettle();
      await t.tap(find.byType(DropdownButtonFormField<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Manager').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Update Role'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(Chip, 'Customer'), findsOneWidget);
      if (!fail) {
        s.pending.complete(record(role: 'Manager'));
        await t.pumpAndSettle();
      }
      expect(find.widgetWithText(Chip, fail ? 'Customer' : 'Manager'),
          findsOneWidget);
      expect(
          find.text('Change User Role'), fail ? findsOneWidget : findsNothing);
    });
    testWidgets('Suspend only changes after success, failure=$fail', (t) async {
      final s = FakeUsers()..fail = fail;
      await open(t, s);
      await t.tap(find.text('Suspend'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ElevatedButton, 'Suspend'));
      await t.pumpAndSettle();
      expect(find.text('Activate'), findsNothing);
      if (!fail) {
        s.pending.complete(record(suspended: true));
        await t.pumpAndSettle();
      }
      expect(find.text('Activate'), fail ? findsNothing : findsOneWidget);
      expect(find.text('Suspend User?'), fail ? findsOneWidget : findsNothing);
    });
    testWidgets('Delete only removes after success, failure=$fail', (t) async {
      final s = FakeUsers()..fail = fail;
      await open(t, s);
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await t.pumpAndSettle();
      expect(find.text('Backend Person'), findsOneWidget);
      if (!fail) {
        s.deletion.complete();
        await t.pumpAndSettle();
      }
      expect(find.text('Backend Person'), fail ? findsOneWidget : findsNothing);
      expect(find.text('Delete User?'), fail ? findsOneWidget : findsNothing);
    });
  }
  testWidgets('Activate waits for backend and renders returned state',
      (t) async {
    final s = FakeUsers();
    await open(t, s);
    await t.tap(find.text('Suspend'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ElevatedButton, 'Suspend'));
    await t.pumpAndSettle();
    s.pending.complete(record(suspended: true));
    await t.pumpAndSettle();
    s.pending = Completer<Map<String, dynamic>>();
    await t.tap(find.text('Activate'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ElevatedButton, 'Activate'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Activate'), findsOneWidget);
    s.pending.complete(record(suspended: false));
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Suspend'), findsOneWidget);
  });
}
