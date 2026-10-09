import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/models/reservation_model.dart';
import 'package:restaurant_queue_app/screens/receptionist/receptionist_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/receptionist/reservation_summary_screen.dart';
import 'package:restaurant_queue_app/screens/receptionist/floor_overview_screen.dart';
import 'package:restaurant_queue_app/screens/receptionist/live_queue_screen.dart';
import 'package:restaurant_queue_app/screens/receptionist/receptionist_profile_screen.dart';
import 'package:restaurant_queue_app/features/receptionist/presentation/widgets/reassign_table_dialog.dart';
import 'package:restaurant_queue_app/features/receptionist/presentation/widgets/add_walk_in_dialog.dart';
import 'package:restaurant_queue_app/services/receptionist_context.dart';
import 'package:restaurant_queue_app/services/supabase_service.dart';

void _setupScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const receptionistProfile = UserProfile(
    id: 'rec_test_user',
    fullName: 'Sara Receptionist',
    email: 'receptionist@dinequeue.com',
    role: UserRole.receptionist,
  );

  const sampleRestaurant = RestaurantModel(
    id: 'ocean_bistro',
    name: 'Ocean Bistro',
    cuisine: 'Italian',
    tag: 'Italian Cuisine',
    location: 'Colombo 03',
    rating: 4.8,
    reviewsCount: 50,
    estWait: '10 min wait',
    waitlistCount: 2,
  );

  group('Receptionist Dashboard & Navigation Tests', () {
    testWidgets('1. Receptionist Dashboard renders RECEPTIONIST role badge and metrics', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReceptionistDashboardScreen(profile: receptionistProfile),
        ),
      );
      await tester.pump();

      expect(find.text('RECEPTIONIST'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
    });

    testWidgets('2. Reservation Summary screen renders filter tabs and reservations list', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReservationSummaryScreen(profile: receptionistProfile),
        ),
      );
      await tester.pump();

      expect(find.text('RECEPTIONIST'), findsOneWidget);
      expect(find.text('Reservations Management'), findsOneWidget);
    });

    testWidgets('3. Floor Overview screen renders floor layout and table management', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: FloorOverviewScreen(profile: receptionistProfile),
        ),
      );
      await tester.pump();

      expect(find.text('RECEPTIONIST'), findsOneWidget);
      expect(find.text('Live Floor Overview'), findsOneWidget);
    });

    testWidgets('4. Live Queue screen renders active queue management and party calls', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: LiveQueueScreen(profile: receptionistProfile),
        ),
      );
      await tester.pump();

      expect(find.text('RECEPTIONIST'), findsOneWidget);
      expect(find.text('Queue'), findsWidgets);
    });

    testWidgets('5. Receptionist Profile screen renders staff details and logout options', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ReceptionistProfileScreen(profile: receptionistProfile),
        ),
      );
      await tester.pump();

      expect(find.text('RECEPTIONIST'), findsOneWidget);
      expect(find.text('Sara Receptionist'), findsWidgets);
      expect(find.text('receptionist@dinequeue.com'), findsWidgets);
    });
  });

  group('Receptionist Operations & Dialog Tests', () {
    testWidgets('6. Reassign Table dialog allows selecting new floor table', (tester) async {
      _setupScreen(tester);

      final testReservation = ReservationModel(
        id: 'rsv_rec_op_1',
        restaurantId: 'ocean_bistro',
        restaurantName: 'Ocean Bistro',
        userId: 'user_guest_1',
        guestName: 'Dulina Guest',
        reservationCode: 'RES-101',
        date: '2026-10-09',
        time: '8:00 PM',
        partySize: 2,
        status: 'confirmed',
        assignedTable: 'Table 01',
        createdAt: DateTime.now(),
      );

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
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Reassign Table'), findsOneWidget);
      expect(find.text('Select Floor Table'), findsOneWidget);
      expect(find.text('Confirm Reassignment'), findsOneWidget);
    });

    testWidgets('7. Add Walk-In dialog renders input fields and guest counter', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddWalkInDialog(restaurantId: 'ocean_bistro'),
                  );
                },
                child: const Text('Open WalkIn'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open WalkIn'));
      await tester.pumpAndSettle();

      expect(find.text('Add Walk-In to Waitlist'), findsOneWidget);
      expect(find.text('Party Size'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
    });

    test('8. Receptionist context persists selected restaurant and prevents revert', () {
      final context = ReceptionistContext();
      context.initialize([sampleRestaurant], preferredRestaurantId: 'ocean_bistro');
      expect(context.activeRestaurantId, equals('ocean_bistro'));

      const newResto = RestaurantModel(
        id: 'nihonbashi',
        name: 'Nihonbashi',
        cuisine: 'Japanese',
        tag: 'Japanese Cuisine',
        location: 'Colombo 03',
        rating: 4.9,
        reviewsCount: 100,
        estWait: '15 min wait',
        waitlistCount: 3,
      );

      context.setActiveRestaurant(newResto);
      expect(context.activeRestaurantId, equals('nihonbashi'));
      expect(context.activeRestaurantName, equals('Nihonbashi'));
    });
  });
}
