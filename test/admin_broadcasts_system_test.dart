import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/admin/admin_dashboard_screen.dart';
import 'package:restaurant_queue_app/services/admin_supabase_service.dart';

Map<String, dynamic> announcement(String priority) => {
      'id': 'saved',
      'title': 'Saved notice',
      'message': 'Backend announcement',
      'priority': priority,
      'isActive': true,
      'createdAt': '2026-10-08T10:00:00Z',
    };

class FakeControls extends AdminSupabaseService {
  List<Map<String, dynamic>> rows = [];
  bool frozen = false;
  bool fail = false;
  bool failLoad = false;
  String? requestedPriority;
  final broadcast = Completer<Map<String, dynamic>>();
  var freeze = Completer<bool>();
  final flush = Completer<int>();
  @override
  Future<List<Map<String, String>>?> loadRestaurants() async => [];
  @override
  Future<List<Map<String, dynamic>>?> loadUsers() async => [];
  @override
  Future<List<Map<String, dynamic>>> loadBroadcasts() async {
    if (failLoad) throw StateError('Backend unavailable');
    return rows;
  }

  @override
  Future<bool> loadPlatformFreeze() async {
    if (failLoad) throw StateError('Settings unavailable');
    return frozen;
  }

  @override
  Future<Map<String, dynamic>> createBroadcast(
      {required String title,
      required String message,
      required String priority}) {
    requestedPriority = priority;
    return fail
        ? Future.error(StateError('Backend rejected'))
        : broadcast.future;
  }

  @override
  Future<bool> setPlatformFreeze(bool frozen) =>
      fail ? Future.error(StateError('Backend rejected')) : freeze.future;
  @override
  Future<int> flushWaitlists() =>
      fail ? Future.error(StateError('Backend rejected')) : flush.future;
}

Future<void> open(WidgetTester t, FakeControls s, String tab) async {
  t.view.physicalSize = const Size(1400, 1100);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(MaterialApp(
      home: AdminDashboardScreen(
          profile: const UserProfile(
              id: 'admin', email: '', fullName: 'Admin', role: UserRole.admin),
          adminService: s)));
  await t.pumpAndSettle();
  await t.tap(find.text(tab));
  await t.pumpAndSettle();
}

Future<void> send(WidgetTester t, String priority) async {
  await t.tap(find.text('Send Alert'));
  await t.pumpAndSettle();
  await t.enterText(find.byType(TextFormField).at(0), 'New notice');
  await t.enterText(find.byType(TextFormField).at(1), 'New message');
  if (priority != 'NORMAL') {
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text(priority == 'WARNING' ? 'Warning' : 'Urgent').last);
    await t.pumpAndSettle();
  }
  await t.tap(find.text('Send'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
      'Persisted announcements render with creation time and priorities',
      (t) async {
    final s = FakeControls()
      ..rows = ['NORMAL', 'WARNING', 'URGENT'].map(announcement).toList();
    await open(t, s, 'Broadcasts');
    expect(find.text('Saved notice'), findsNWidgets(3));
    for (final p in ['NORMAL', 'WARNING', 'URGENT']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.textContaining('Created:'), findsNWidgets(3));
  });
  testWidgets('Empty database is a real empty announcement list', (t) async {
    await open(t, FakeControls(), 'Broadcasts');
    expect(find.text('No broadcast announcements yet.'), findsOneWidget);
    expect(find.text('Platform Operational'), findsNothing);
  });
  for (final p in ['NORMAL', 'WARNING', 'URGENT']) {
    testWidgets('Send waits for server and preserves $p', (t) async {
      final s = FakeControls();
      await open(t, s, 'Broadcasts');
      await send(t, p);
      expect(s.requestedPriority, p);
      expect(find.text('Saved notice'), findsNothing);
      expect(find.text('Send'), findsOneWidget);
      s.broadcast.complete(announcement(p));
      await t.pumpAndSettle();
      expect(find.text('Saved notice'), findsOneWidget);
      expect(find.text('Send'), findsNothing);
      expect(find.text(p), findsOneWidget);
    });
  }
  testWidgets('Failed send keeps dialog open and does not fabricate a record',
      (t) async {
    final s = FakeControls()..fail = true;
    await open(t, s, 'Broadcasts');
    await send(t, 'NORMAL');
    expect(find.text('Saved notice'), findsNothing);
    expect(find.text('Send'), findsOneWidget);
    expect(find.textContaining('Unable to save announcement'), findsOneWidget);
  });
  testWidgets('Freeze loads real state and unfreezes after RPC success',
      (t) async {
    final s = FakeControls()..frozen = true;
    await open(t, s, 'System');
    expect(t.widget<Switch>(find.byType(Switch)).value, true);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).value, true);
    s.freeze.complete(false);
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).value, false);
  });
  testWidgets('Freeze waits for server confirmation', (t) async {
    final s = FakeControls();
    await open(t, s, 'System');
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).value, false);
    s.freeze.complete(true);
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).value, true);
  });
  testWidgets('Failed freeze preserves previous value', (t) async {
    final s = FakeControls()..fail = true;
    await open(t, s, 'System');
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).value, false);
    expect(find.textContaining('Unable to change platform freeze'),
        findsOneWidget);
  });
  for (final count in [0, 4]) {
    testWidgets('Flush reports confirmed count $count', (t) async {
      final s = FakeControls();
      await open(t, s, 'System');
      await t.tap(find.text('Flush'));
      await t.pumpAndSettle();
      expect(find.textContaining('Records and history are preserved'),
          findsOneWidget);
      await t.tap(find.text('Confirm'));
      await t.pumpAndSettle();
      expect(find.textContaining('Global waitlist flush completed:'),
          findsNothing);
      s.flush.complete(count);
      await t.pumpAndSettle();
      expect(
          find.textContaining(count == 0
              ? 'no active entries required cancellation'
              : '4 entries cancelled'),
          findsOneWidget);
    });
  }
  testWidgets('Flush error does not report success', (t) async {
    final s = FakeControls()..fail = true;
    await open(t, s, 'System');
    await t.tap(find.text('Flush'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(find.textContaining('Unable to flush waitlists'), findsOneWidget);
    expect(
        find.textContaining('Global waitlist flush completed:'), findsNothing);
  });
  testWidgets('Failed reads are explicit and unknown freeze is disabled',
      (t) async {
    await open(t, FakeControls()..failLoad = true, 'Broadcasts');
    expect(find.textContaining('Unable to load announcements'), findsOneWidget);
    expect(find.text('No broadcast announcements yet.'), findsNothing);
    await t.tap(find.text('System'));
    await t.pumpAndSettle();
    expect(t.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
        find.textContaining('Unable to load platform freeze'), findsOneWidget);
  });
}
