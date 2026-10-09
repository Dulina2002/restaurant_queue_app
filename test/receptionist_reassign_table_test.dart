import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/features/receptionist/presentation/widgets/reassign_table_dialog.dart';
import 'package:restaurant_queue_app/models/reservation_model.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/receptionist/receptionist_dashboard_screen.dart';
import 'package:restaurant_queue_app/services/supabase_service.dart';
import 'package:restaurant_queue_app/shared/widgets/role_header_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const dummyReceptionistProfile = UserProfile(
    id: 'rec_123',
    email: 'receptionist@dinequeue.com',
    fullName: 'Receptionist User',
    role: UserRole.receptionist,
  );

  final testReservation = ReservationModel(
    id: 'rsv_test_999',
    restaurantId: 'ocean_bistro',
    restaurantName: 'Ocean Bistro',
    userId: 'user_dulina',
    guestName: 'Dulina nadith',
    reservationCode: 'RES-999',
    date: '2026-10-08',
    time: '9:30 PM',
    partySize: 4,
    status: 'confirmed',
    assignedTable: 'Table 01',
    specialNotes: 'Table: Table 01 (Main Dining) • Requests: Window seat • Pre-orders: Grilled Calamari',
    createdAt: DateTime.now(),
  );

  group('Receptionist Reassign Table Tests', () {
    testWidgets('ReassignTableDialog renders guest info, current table, and floor tables',
        (tester) async {
      await SupabaseService().createReservation(testReservation);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ReassignTableDialog.show(
                    context,
                    reservation: testReservation,
                    restaurantId: 'ocean_bistro',
                    restaurantName: 'Ocean Bistro',
                  );
                },
                child: const Text('Open Reassign Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reassign Dialog'));
      await tester.pumpAndSettle();

      // Check header and guest details
      expect(find.text('Reassign Table'), findsOneWidget);
      expect(find.text('Dulina nadith • 4 Guests • 9:30 PM'), findsOneWidget);
      expect(find.text('Select Floor Table'), findsOneWidget);
      expect(find.text('Confirm Reassignment'), findsOneWidget);

      // Verify tables are listed
      expect(find.text('Table 01'), findsWidgets);
      expect(find.text('Table 02'), findsWidgets);
      expect(find.text('Table 03'), findsWidgets);

      // Select 'Table 03'
      await tester.tap(find.text('Table 03'));
      await tester.pumpAndSettle();

      // Tap 'Confirm Reassignment'
      await tester.tap(find.text('Confirm Reassignment'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      // Verify the dialog closed and reservation was updated in SupabaseService
      final updatedRsv = SupabaseService()
          .getRestaurantReservationsSync('ocean_bistro')
          .firstWhere((r) => r.id == testReservation.id, orElse: () => testReservation);
      expect(updatedRsv.assignedTable, equals('Table 03'));
      expect(updatedRsv.specialNotes, contains('Table: Table 03'));
    });

    testWidgets('Receptionist Dashboard renders Reassign Table button on arrival card and triggers dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed the test reservation into Supabase fallback list
      await SupabaseService().createReservation(testReservation);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReceptionistDashboardScreen(profile: dummyReceptionistProfile),
        ),
      );

      await tester.pumpAndSettle();

      // Find 'Reassign Table' button
      final reassignButtonFinder = find.widgetWithText(OutlinedButton, 'Reassign Table');
      expect(reassignButtonFinder, findsWidgets);

      await tester.ensureVisible(reassignButtonFinder.first);
      await tester.tap(reassignButtonFinder.first);
      await tester.pumpAndSettle();

      // Verify ReassignTableDialog is displayed
      expect(find.byType(ReassignTableDialog), findsOneWidget);
      expect(find.text('Confirm Reassignment'), findsOneWidget);
    });

    testWidgets('Receptionist header renders in green without logout button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: RoleHeaderWidget(
              roleName: 'RECEPTIONIST',
              roleColor: Color(0xFFFF6B35),
              profile: dummyReceptionistProfile,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECEPTIONIST'), findsOneWidget);
      expect(find.text('DineQueue'), findsOneWidget);
      expect(find.text('Receptionist User'), findsOneWidget);
      // Logout button must be completely removed from header
      expect(find.byIcon(Icons.logout_rounded), findsNothing);
    });
  });
}
