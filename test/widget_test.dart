import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/screens/auth_gate.dart';
import 'package:restaurant_queue_app/screens/customer/customer_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/receptionist/receptionist_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/manager/manager_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/admin/admin_dashboard_screen.dart';

void main() {
  test('AuthGate resolves proper screen for each user role', () {
    const baseProfile = UserProfile(
      id: 'test-id',
      email: 'test@example.com',
      fullName: 'Test User',
      role: UserRole.customer,
    );

    final customerScreen = AuthGate.getScreenForRole(
      baseProfile.copyWith(role: UserRole.customer),
    );
    expect(customerScreen, isA<CustomerDashboardScreen>());

    final receptionistScreen = AuthGate.getScreenForRole(
      baseProfile.copyWith(role: UserRole.receptionist),
    );
    expect(receptionistScreen, isA<ReceptionistDashboardScreen>());

    final managerScreen = AuthGate.getScreenForRole(
      baseProfile.copyWith(role: UserRole.manager),
    );
    expect(managerScreen, isA<ManagerDashboardScreen>());

    final adminScreen = AuthGate.getScreenForRole(
      baseProfile.copyWith(role: UserRole.admin),
    );
    expect(adminScreen, isA<AdminDashboardScreen>());
  });

  testWidgets('ManagerDashboardScreen renders and navigates to EditProfileScreen', (tester) async {
    const managerProfile = UserProfile(
      id: 'mgr-1',
      email: 'manager@dinequeue.com',
      fullName: 'Ayesha Perera',
      role: UserRole.manager,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ManagerDashboardScreen(profile: managerProfile),
      ),
    );

    expect(find.text('Manager Dashboard'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Current Role: Manager'), findsOneWidget);
    expect(find.text('My Reviews'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Tap Edit Profile item
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('CustomerDashboardScreen renders CustomerQueueView in Queue tab', (tester) async {
    const customerProfile = UserProfile(
      id: 'cust-1',
      email: 'customer@dinequeue.com',
      fullName: 'Ayesha Perera',
      role: UserRole.customer,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerDashboardScreen(
          profile: customerProfile,
          initialTabIndex: 3,
        ),
      ),
    );

    expect(find.text('Ocean Bistro'), findsOneWidget);
    expect(find.text('Virtual Waitlist'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Your Queue Position'), findsOneWidget);
    expect(find.text('Estimated Wait'), findsOneWidget);
    expect(find.text('22 min'), findsOneWidget);
    expect(find.text('Your table is being prepared.'), findsOneWidget);
    expect(find.text('Queue Progress'), findsOneWidget);
    expect(find.text('Joined Queue'), findsOneWidget);
    expect(find.text('Position #5'), findsOneWidget);
    expect(find.text('Position #3 (Current)'), findsOneWidget);
    expect(find.text('Table Ready'), findsOneWidget);
  });
}
