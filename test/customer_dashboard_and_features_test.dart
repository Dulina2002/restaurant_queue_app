import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/models/reservation_model.dart';
import 'package:restaurant_queue_app/models/queue_entry_model.dart';
import 'package:restaurant_queue_app/screens/customer/customer_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/customer/booking/restaurant_details_screen.dart';
import 'package:restaurant_queue_app/screens/customer/booking/reservation_details_screen.dart';
import 'package:restaurant_queue_app/screens/customer/booking/booking_confirmation_screen.dart';
import 'package:restaurant_queue_app/screens/customer/widgets/customer_bookings_view.dart';
import 'package:restaurant_queue_app/screens/customer/widgets/customer_queue_view.dart';
import 'package:restaurant_queue_app/screens/customer/widgets/customer_profile_view.dart';
import 'package:restaurant_queue_app/services/restaurant_database_service.dart';

void _setupTestScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const testProfile = UserProfile(
    id: 'customer_test_101',
    fullName: 'Dulina Customer',
    email: 'customer@test.com',
    phoneNumber: '+94 77 123 4567',
    role: UserRole.customer,
  );

  const sampleRestaurant = RestaurantModel(
    id: 'sugarfish',
    name: 'SUGARFISH',
    cuisine: 'Japanese',
    tag: 'Sushi • Japanese',
    location: 'No. 25, Galle Road, Colombo 03, Sri Lanka',
    rating: 4.8,
    reviewsCount: 120,
    estWait: '15m',
    waitlistCount: 3,
    imageUrl: '',
  );

  group('Customer Dashboard & Navigation Tests', () {
    testWidgets('1. Customer Dashboard renders Customer badge and user greeting', (tester) async {
      _setupTestScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDashboardScreen(profile: testProfile),
        ),
      );
      await tester.pump();

      // Verify Header Badge & Branding
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('DineQueue'), findsWidgets);
      expect(find.textContaining('Dulina'), findsWidgets);

      // Verify Bottom Navigation Items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('2. Switching tabs through Explore, Bookings, Queue, and Profile works', (tester) async {
      _setupTestScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDashboardScreen(profile: testProfile),
        ),
      );
      await tester.pump();

      // Switch to Explore Tab (Index 1)
      await tester.tap(find.text('Explore'));
      await tester.pump();
      expect(find.text('Explore Restaurants'), findsOneWidget);
      expect(find.text('Discover top dining spots and reserve instantly'), findsOneWidget);

      // Switch to Bookings Tab (Index 2)
      await tester.tap(find.text('Bookings'));
      await tester.pump();
      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);

      // Switch to Queue Tab (Index 3)
      await tester.tap(find.text('Queue'));
      await tester.pump();
      expect(find.text('No Active Queue'), findsOneWidget);

      // Switch to Profile Tab (Index 4)
      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(find.text('Dulina Customer'), findsWidgets);
      expect(find.text('customer@test.com'), findsWidgets);
    });
  });

  group('Customer Views & Booking Flow Tests', () {
    testWidgets('3. CustomerBookingsView displays upcoming, past and cancelled tabs properly', (tester) async {
      _setupTestScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerBookingsView(
              profile: testProfile,
              onBrowseRestaurants: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Tap on Past tab
      await tester.tap(find.text('Past'));
      await tester.pump();
      expect(find.text('Past'), findsOneWidget);
    });

    testWidgets('4. CustomerQueueView renders cleanly with queue action items', (tester) async {
      _setupTestScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerQueueView(
              profile: testProfile,
              onBrowseRestaurants: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No Active Queue'), findsOneWidget);
      expect(find.text('Browse Restaurants'), findsOneWidget);
    });

    testWidgets('5. CustomerProfileView displays user account and action items', (tester) async {
      _setupTestScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerProfileView(
              profile: testProfile,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dulina Customer'), findsWidgets);
      expect(find.text('customer@test.com'), findsWidgets);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('6. RestaurantDetailsScreen renders restaurant info and reservation actions', (tester) async {
      _setupTestScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: RestaurantDetailsScreen(
            restaurant: sampleRestaurant,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SUGARFISH'), findsWidgets);
      expect(find.text('Table Availability'), findsOneWidget);
    });

    testWidgets('7. BookingConfirmationScreen displays confirmed reservation pass', (tester) async {
      _setupTestScreen(tester);

      final confirmedReservation = ReservationModel(
        id: 'rsv_cust_pass_1',
        restaurantId: 'sugarfish',
        restaurantName: 'SUGARFISH',
        userId: testProfile.id,
        guestName: testProfile.fullName,
        reservationCode: '#RSV-123456',
        date: 'Saturday, 12 Oct',
        time: '7:30 PM',
        partySize: 2,
        status: 'confirmed',
        assignedTable: 'Table 02',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookingConfirmationScreen(
            reservation: confirmedReservation,
            restaurant: sampleRestaurant,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reservation Confirmed!'), findsOneWidget);
      expect(find.text('SUGARFISH'), findsWidgets);
      expect(find.text('#RSV-123456'), findsOneWidget);
      expect(find.text('View Reservation'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('8. ReservationDetailsScreen renders options to view, modify and cancel', (tester) async {
      _setupTestScreen(tester);

      final reservation = ReservationModel(
        id: 'rsv_details_test',
        restaurantId: 'sugarfish',
        restaurantName: 'SUGARFISH',
        userId: testProfile.id,
        guestName: testProfile.fullName,
        reservationCode: '#RSV-998877',
        date: 'Sunday, 13 Oct',
        time: '8:00 PM',
        partySize: 4,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailsScreen(
            reservation: reservation,
            restaurant: sampleRestaurant,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reservation Details'), findsOneWidget);
      expect(find.text('SUGARFISH'), findsWidgets);
      expect(find.textContaining('#RSV-998877'), findsOneWidget);
      expect(find.text('Cancel Reservation'), findsOneWidget);
    });
  });

  group('Customer Database & Virtual Queue Lifecycle Tests', () {
    final dbService = RestaurantDatabaseService();

    test('9. Virtual Queue join creates entry and tracks position', () async {
      final queueEntry = await dbService.joinQueue(
        restaurantId: 'sugarfish',
        restaurantName: 'SUGARFISH',
        userId: 'cust_queue_user_1',
        guestName: 'Dulina Nadith',
        partySize: 2,
        phoneNumber: '+94 77 123 4567',
      );

      expect(queueEntry.restaurantName, equals('SUGARFISH'));
      expect(queueEntry.partySize, equals(2));
      expect(queueEntry.status == QueueStatus.waiting || queueEntry.status == QueueStatus.called, isTrue);
    });

    test('10. Customer reservation creation and cancellation updates status', () async {
      const reservationId = 'cust_test_res_lifecycle';

      final created = await dbService.createReservation(
        ReservationModel(
          id: reservationId,
          restaurantId: 'sugarfish',
          restaurantName: 'SUGARFISH',
          userId: 'cust_lifecycle_user',
          guestName: 'Dulina Tester',
          reservationCode: '#RSV-LIFECYCLE',
          date: 'Monday, 14 Oct',
          time: '6:30 PM',
          partySize: 3,
          status: 'confirmed',
          createdAt: DateTime.now(),
        ),
      );

      expect(created.status, equals('confirmed'));
      expect(created.partySize, equals(3));

      // Cancel reservation
      await dbService.cancelReservation(reservationId);

      // Verify cancellation
      final userReservations = await dbService.streamUserReservations('cust_lifecycle_user').first;
      final cancelled = userReservations.firstWhere((r) => r.id == reservationId);
      expect(cancelled.status, equals('cancelled'));
    });
  });
}
