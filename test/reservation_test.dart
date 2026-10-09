import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/models/reservation_model.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/customer/booking/reservation_details_screen.dart';
import 'package:restaurant_queue_app/services/restaurant_database_service.dart';
import 'package:restaurant_queue_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Reservation Lifecycle & User Isolation', () {
    final firestoreService = RestaurantDatabaseService();
    final authService = AuthService();

    test('AuthService generates consistent deterministic IDs for email logins', () async {
      await authService.signUp(
        email: 'dulina@gmail.com',
        password: 'password123',
        fullName: 'Dulina Test',
        role: UserRole.customer,
      );
      final profile1 = await authService.signIn(email: 'dulina@gmail.com', password: 'password123');
      final id1 = profile1.id;

      await authService.signOut();

      final profile2 = await authService.signIn(email: 'dulina@gmail.com', password: 'password123');
      final id2 = profile2.id;

      expect(id1, equals(id2));
      expect(id1, contains('dulina_gmail_com'));
    });

    test('New user starts with empty reservations list and no hardcoded bookings', () async {
      final stream = firestoreService.streamUserReservations('user_new_test_diner');
      final list = await stream.first;
      expect(list, isEmpty);
    });

    test('Created reservation is confirmed and can be cancelled without reappearing as upcoming', () async {
      const testUserId = 'user_test_cancel_flow';
      
      final created = await firestoreService.createReservation(
        ReservationModel(
          id: 'test_rsv_101',
          restaurantId: 'ocean_bistro',
          restaurantName: 'Ocean Bistro',
          userId: testUserId,
          guestName: 'Dulina Test',
          reservationCode: '#RSV999',
          date: 'Saturday, 12 Oct',
          time: '7:30 PM',
          partySize: 4,
          status: 'confirmed',
          createdAt: DateTime.now(),
        ),
      );

      expect(created.status, equals('confirmed'));

      // Verify it appears in user's upcoming stream
      final activeList = await firestoreService.streamUserReservations(testUserId).first;
      final upcoming = activeList.where((r) => r.status.toLowerCase() != 'cancelled' && r.status.toLowerCase() != 'completed').toList();
      expect(upcoming.length, equals(1));
      expect(upcoming.first.id, equals('test_rsv_101'));

      // Cancel reservation
      await firestoreService.cancelReservation('test_rsv_101');

      // Verify it is no longer in upcoming
      final updatedList = await firestoreService.streamUserReservations(testUserId).first;
      final remainingUpcoming = updatedList.where((r) => r.status.toLowerCase() != 'cancelled' && r.status.toLowerCase() != 'completed').toList();
      final history = updatedList.where((r) => r.status.toLowerCase() == 'cancelled' || r.status.toLowerCase() == 'completed').toList();

      expect(remainingUpcoming, isEmpty);
      expect(history.length, equals(1));
      expect(history.first.status, equals('cancelled'));
    });

    test('Cancelled reservation remains in History tab across simulated logout and relogin', () async {
      await authService.signUp(
        email: 'diner_history@example.com',
        password: 'password123',
        fullName: 'History Diner',
        role: UserRole.customer,
      );
      final user = await authService.signIn(email: 'diner_history@example.com', password: 'password123');
      final userId = user.id;

      final res = await firestoreService.createReservation(
        ReservationModel(
          id: 'persisted_rsv_777',
          restaurantId: 'ocean_bistro',
          restaurantName: 'Ocean Bistro',
          userId: userId,
          guestName: user.fullName,
          reservationCode: '#RSV777',
          date: 'Sunday, 13 Oct',
          time: '8:00 PM',
          partySize: 2,
          status: 'confirmed',
          createdAt: DateTime.now(),
        ),
      );

      expect(res.status, 'confirmed');

      // Cancel it
      await firestoreService.cancelReservation('persisted_rsv_777');

      // Simulate sign out
      await authService.signOut();

      // Simulate sign in again
      final reloggedUser = await authService.signIn(email: 'diner_history@example.com', password: 'password123');
      expect(reloggedUser.id, equals(userId));

      // Fetch reservations after relogin
      final postLoginReservations = await firestoreService.streamUserReservations(reloggedUser.id).first;
      final upcoming = postLoginReservations.where((r) => r.status.toLowerCase() != 'cancelled' && r.status.toLowerCase() != 'completed').toList();
      final history = postLoginReservations.where((r) => r.status.toLowerCase() == 'cancelled' || r.status.toLowerCase() == 'completed').toList();

      expect(upcoming, isEmpty);
      expect(history.any((r) => r.id == 'persisted_rsv_777' && r.status == 'cancelled'), isTrue);
    });

    testWidgets('ReservationDetailsScreen renders long Special Notes without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const restaurant = RestaurantModel(
        id: 'sugarfish',
        name: 'SUGARFISH',
        cuisine: 'Sushi',
        tag: 'Japanese • Sushi',
        location: 'No. 25, Galle Road, Colombo 03, Sri Lanka',
        rating: 4.5,
        reviewsCount: 10,
        estWait: '0m',
        waitlistCount: 0,
        imageUrl: 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b',
      );

      final reservationWithLongNotes = ReservationModel(
        id: 'rsv_overflow_test',
        restaurantId: 'sugarfish',
        restaurantName: 'SUGARFISH',
        userId: 'user_test',
        guestName: 'Dulina nadit',
        reservationCode: '#RSV802224',
        date: 'Tuesday, 13 October',
        time: '6:00 PM',
        partySize: 6,
        status: 'confirmed',
        assignedTable: 'Table 04 (Indoor Window)',
        specialNotes: 'Table: Table 01 (Main Dining) • Request: Window table near flowers please and high chair needed for infant',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailsScreen(
            reservation: reservationWithLongNotes,
            restaurant: restaurant,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reservation Details'), findsOneWidget);
      expect(find.text('Special Notes'), findsOneWidget);
      expect(find.text('Table: Table 01 (Main Dining) • Request: Window table near flowers please and high chair needed for infant'), findsOneWidget);
      final err = tester.takeException();
      if (err is FlutterError) {
        // ignore: avoid_print
        print('DEBUG OVERFLOW ERROR DEEP: ${err.toStringDeep()}');
      }
      expect(err, isNull);
    });

    testWidgets('ReservationDetailsScreen displays correct tag and image when restaurant is null', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reservation = ReservationModel(
        id: 'rsv_null_resto_test',
        restaurantId: 'sugarfish',
        restaurantName: 'SUGARFISH',
        userId: 'user_test',
        guestName: 'Dulina nadit',
        reservationCode: '#RSV802224',
        date: 'Tuesday, 13 October',
        time: '6:00 PM',
        partySize: 6,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailsScreen(
            reservation: reservation,
            restaurant: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tag must be correctly resolved to Sushi, NOT the hardcoded Italian fallback
      expect(find.text('Sushi'), findsOneWidget);
      expect(find.text('Italian • Seafood'), findsNothing);
      expect(find.text('SUGARFISH'), findsOneWidget);
    });
  });
}
