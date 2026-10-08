import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/customer/customer_dashboard_screen.dart';

void main() {
  test('RestaurantModel hasWaitTime behaves correctly for 0m vs >0m', () {
    const zeroWaitRestaurant = RestaurantModel(
      id: 'r1',
      name: 'Zero Wait Bistro',
      cuisine: 'Italian',
      tag: 'Italian',
      location: 'Colombo',
      rating: 4.5,
      reviewsCount: 10,
      estWait: '0m',
      waitlistCount: 0,
    );
    expect(zeroWaitRestaurant.hasWaitTime, isFalse);

    const directSeatingRestaurant = RestaurantModel(
      id: 'r2',
      name: 'Direct Seating Bistro',
      cuisine: 'Italian',
      tag: 'Italian',
      location: 'Colombo',
      rating: 4.5,
      reviewsCount: 10,
      estWait: 'Direct Seating',
      waitlistCount: 0,
    );
    expect(directSeatingRestaurant.hasWaitTime, isFalse);

    const queuedRestaurant = RestaurantModel(
      id: 'r3',
      name: 'Queued Bistro',
      cuisine: 'Italian',
      tag: 'Italian',
      location: 'Colombo',
      rating: 4.5,
      reviewsCount: 10,
      estWait: '15m',
      waitlistCount: 4,
    );
    expect(queuedRestaurant.hasWaitTime, isTrue);
  });

  testWidgets('Customer sees Direct Booking on 0m wait and Join Queue when wait time > 0', (tester) async {
    const profile = UserProfile(
      id: 'cust-1',
      email: 'customer@example.com',
      fullName: 'Customer Test',
      role: UserRole.customer,
    );

    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerDashboardScreen(profile: profile),
      ),
    );
    await tester.pumpAndSettle();

    // The fallback restaurants have:
    // - Ocean Bistro: '12 min wait' -> hasWaitTime: true -> 'Join Queue'
    // - The Mango Tree: 'Direct Seating' (0m) -> hasWaitTime: false -> 'Direct Booking'
    // - Nihonbashi: '20 min wait' -> hasWaitTime: true -> 'Join Queue'
    expect(find.widgetWithText(ElevatedButton, 'Direct Booking'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Join Queue'), findsWidgets);
  });
}
