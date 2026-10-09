import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/admin/admin_dashboard_screen.dart';
import 'package:restaurant_queue_app/services/admin_supabase_service.dart';

class _EmptyAdminService extends AdminSupabaseService {
  @override
  Future<List<Map<String, String>>?> loadRestaurants() async => [];

  @override
  Future<List<Map<String, dynamic>>?> loadUsers() async => [];
  @override
  Future<List<Map<String, dynamic>>> loadBroadcasts() async => [];
  @override
  Future<bool> loadPlatformFreeze() async => false;
  @override
  Future<bool> setPlatformFreeze(bool frozen) async => frozen;
  @override
  Future<int> flushWaitlists() async => 0;
  @override
  Future<Map<String, dynamic>> createBroadcast(
          {required String title,
          required String message,
          required String priority}) async =>
      {
        'id': 'saved',
        'title': title,
        'message': message,
        'priority': priority,
        'isActive': true,
        'createdAt': '2026-10-08T00:00:00Z',
      };
}

class _FailedAdminService extends _EmptyAdminService {
  @override
  Future<List<Map<String, String>>?> loadRestaurants() async =>
      throw StateError('Read failed');
}

const _profile = UserProfile(
  id: 'test-admin',
  fullName: 'Test Admin',
  email: 'admin@example.com',
  role: UserRole.admin,
);

Future<void> _open(WidgetTester tester, {AdminSupabaseService? service}) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: AdminDashboardScreen(profile: _profile, adminService: service),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Empty Supabase snapshots do not become sample records',
      (tester) async {
    await _open(tester, service: _EmptyAdminService());
    expect(find.textContaining('Test Admin'), findsOneWidget);
    expect(find.byTooltip('Sign Out'), findsOneWidget);
    expect(find.text('No partner restaurants available.'), findsOneWidget);
    expect(find.text('Ocean Bistro'), findsNothing);
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    expect(find.text('No users available.'), findsOneWidget);
  });

  testWidgets('Failed reads explicitly identify fallback examples',
      (tester) async {
    await _open(tester, service: _FailedAdminService());
    expect(find.textContaining('Supabase read failed'), findsOneWidget);
    expect(find.text('Ocean Bistro'), findsOneWidget);
  });

  testWidgets('Alert validates and saves through backend without examples',
      (tester) async {
    await _open(tester, service: _EmptyAdminService());
    await tester.tap(find.text('Broadcasts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Alert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter an alert title.'), findsOneWidget);
    expect(find.text('Please enter a message.'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).at(0), '  Service notice  ');
    await tester.enterText(
        find.byType(TextFormField).at(1), '  Test message  ');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgent').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Service notice'), findsOneWidget);
    expect(find.text('Test message'), findsOneWidget);
    expect(find.text('URGENT'), findsOneWidget);
    expect(find.text('Platform Operational'), findsNothing);
    expect(find.text('Scheduled Maintenance'), findsNothing);
    expect(
        find.textContaining('Announcement saved to Supabase.'), findsOneWidget);
  });

  testWidgets('Freeze cancel preserves state and confirm toggles it',
      (tester) async {
    await _open(tester, service: _EmptyAdminService());
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('Flush cancellation has no success, confirm reports zero count',
      (tester) async {
    await _open(tester, service: _EmptyAdminService());
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flush'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('completed successfully'), findsNothing);
    await tester.tap(find.text('Flush'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no active entries required cancellation'),
        findsOneWidget);
  });
}
