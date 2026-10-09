import 'package:flutter_test/flutter_test.dart';

import 'admin_dashboard_test.dart' as admin_dashboard;
import 'admin_users_test.dart' as admin_users;
import 'admin_broadcasts_system_test.dart' as admin_broadcasts;
import 'admin_switch_role_redirect_test.dart' as admin_switch_role;

void main() {
  group('Admin Dashboard & System Tests', () {
    admin_dashboard.main();
  });

  group('Admin User Management Tests', () {
    admin_users.main();
  });

  group('Admin Broadcasts & Emergency Controls Tests', () {
    admin_broadcasts.main();
  });

  group('Admin Switch Role Redirection Tests', () {
    admin_switch_role.main();
  });
}
