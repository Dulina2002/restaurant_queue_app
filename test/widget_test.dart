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
}
