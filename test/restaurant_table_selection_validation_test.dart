import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/screens/customer/booking/restaurant_details_screen.dart';
import 'package:restaurant_queue_app/screens/customer/booking/reserve_table_stepper_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RestaurantDetailsScreen Table Selection & Validation Tests', () {
    testWidgets('Cannot continue when restaurant has no tables configured (like SUGARFISH)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const emptyRestaurant = RestaurantModel(
        id: 'sugarfish_no_tables',
        name: 'SUGARFISH',
        cuisine: 'Sushi',
        tag: 'Japanese • Sushi',
        location: 'No. 25, Galle Road, Colombo 03, Sri Lanka',
        rating: 4.5,
        reviewsCount: 0,
        estWait: '0m',
        waitlistCount: 0,
        imageUrl: 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RestaurantDetailsScreen(
            restaurant: emptyRestaurant,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "No tables configured for this restaurant." is displayed
      expect(find.text('No tables configured for this restaurant.'), findsOneWidget);
      expect(find.text('Reservations cannot be made at this time.'), findsOneWidget);

      // Verify button shows unavailable state
      expect(find.text('Reserve a Table (Unavailable)'), findsOneWidget);

      // Tap the reserve button
      final reserveBtn = find.text('Reserve a Table (Unavailable)');
      await tester.tap(reserveBtn);
      await tester.pump();

      // Verify warning snackbar appears preventing user from continuing
      expect(find.text('Cannot continue: No tables configured for this restaurant.'), findsOneWidget);

      // Verify ReserveTableStepperScreen was NOT opened
      expect(find.byType(ReserveTableStepperScreen), findsNothing);
    });

    testWidgets('Requires table selection before reserving and navigates once selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const restaurantWithTables = RestaurantModel(
        id: 'ocean_bistro',
        name: 'Ocean Bistro',
        cuisine: 'Seafood',
        tag: 'Seafood • Grill',
        location: '42 Marine Drive, Colombo 03',
        rating: 4.8,
        reviewsCount: 120,
        estWait: '0m',
        waitlistCount: 0,
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RestaurantDetailsScreen(
            restaurant: restaurantWithTables,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tables should be present
      expect(find.text('Table Availability'), findsOneWidget);
      expect(find.text('Tap an available table to select'), findsOneWidget);

      // Attempt to tap Reserve button without selecting table first
      final reserveBtn = find.text('Select a Table to Reserve');
      expect(reserveBtn, findsOneWidget);

      await tester.tap(reserveBtn);
      await tester.pump();

      // Validation snackbar should appear
      expect(find.text('Please select an available table first to reserve.'), findsOneWidget);
      expect(find.byType(ReserveTableStepperScreen), findsNothing);

      // Attempt to tap occupied table (Table 01)
      final occupiedTable = find.text('Table 01');
      expect(occupiedTable, findsOneWidget);
      await tester.tap(occupiedTable);
      await tester.pump();
      expect(find.text('Table 01 is currently occupied and cannot be reserved.'), findsOneWidget);

      // Now tap on an available table (Table 04)
      final availableTable = find.text('Table 04');
      expect(availableTable, findsOneWidget);
      await tester.tap(availableTable);
      await tester.pumpAndSettle();

      // Selected tag should appear on the card
      expect(find.text('SELECTED'), findsOneWidget);

      // Dismiss any open SnackBar before tapping the bottom button
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Button should update to show the selected table name
      final activeReserveBtn = find.widgetWithText(ElevatedButton, 'Reserve Table 04 (4 Guests)');
      expect(activeReserveBtn, findsOneWidget);

      // Tap the reserve button with table selected
      await tester.tap(activeReserveBtn);
      await tester.pumpAndSettle();

      // Stepper screen should now be opened
      expect(find.byType(ReserveTableStepperScreen), findsOneWidget);
    });
  });
}
