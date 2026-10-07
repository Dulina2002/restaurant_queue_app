import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/services/auth_service.dart';
import 'package:restaurant_queue_app/screens/auth_gate.dart';
import 'package:restaurant_queue_app/screens/receptionist/receptionist_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/customer/customer_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/manager/manager_dashboard_screen.dart';
import 'package:restaurant_queue_app/screens/admin/admin_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AuthService Input Validation', () {
    test('Email validation returns error for empty or invalid emails', () {
      expect(AuthService.validateEmail(''), isNotNull);
      expect(AuthService.validateEmail('   '), isNotNull);
      expect(AuthService.validateEmail('notanemail'), isNotNull);
      expect(AuthService.validateEmail('user@'), isNotNull);
      expect(AuthService.validateEmail('user@domain'), isNotNull);
    });

    test('Email validation passes for valid emails', () {
      expect(AuthService.validateEmail('user@example.com'), isNull);
      expect(AuthService.validateEmail('customer.smart@dinequeue.lk'), isNull);
    });

    test('Password validation returns error for short or empty passwords', () {
      expect(AuthService.validatePassword(''), isNotNull);
      expect(AuthService.validatePassword('12345'), isNotNull);
    });

    test('Password validation passes for 6+ characters', () {
      expect(AuthService.validatePassword('123456'), isNull);
      expect(AuthService.validatePassword('securePass123!'), isNull);
    });

    test('Name validation enforces at least 2 characters', () {
      expect(AuthService.validateName(''), isNotNull);
      expect(AuthService.validateName('A'), isNotNull);
      expect(AuthService.validateName('Alex Morgan'), isNull);
    });
  });

  group('UserRole & UserProfile Serialization', () {
    test('UserRole string conversion and defaults', () {
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('receptionist'), UserRole.receptionist);
      expect(UserRole.fromString('reciption'), UserRole.receptionist);
      expect(UserRole.fromString('reciptionist'), UserRole.receptionist);
      expect(UserRole.fromString('reception'), UserRole.receptionist);
      expect(UserRole.fromString('Reception'), UserRole.receptionist);
      expect(UserRole.fromString('reception_staff'), UserRole.receptionist);
      expect(UserRole.fromString('frontdesk'), UserRole.receptionist);
      expect(UserRole.fromString('host'), UserRole.receptionist);
      expect(UserRole.fromString('manager'), UserRole.manager);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('administrator'), UserRole.admin);
      expect(UserRole.fromString(null), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.customer);
    });

    test('UserProfile JSON serialization roundtrip', () {
      final json = {
        'id': 'usr_123',
        'full_name': 'John Doe',
        'role': 'reception',
        'phone_number': '+94771234567',
      };

      final profile = UserProfile.fromJson(json, defaultEmail: 'reception@example.com');
      expect(profile.id, 'usr_123');
      expect(profile.fullName, 'John Doe');
      expect(profile.role, UserRole.receptionist);
      expect(profile.email, 'reception@example.com');
      expect(profile.phoneNumber, '+94771234567');

      final serialized = profile.toJson();
      expect(serialized['role'], 'receptionist');
      expect(serialized['full_name'], 'John Doe');
    });

    test('Fixed staff logins resolve to specific roles and dashboards', () async {
      final auth = AuthService();

      // 1. Receptionist
      final recProfile = await auth.signIn(
        email: 'reciptionist123@gmail.com',
        password: 'reciption@123',
      );
      expect(recProfile.role, UserRole.receptionist);
      expect(recProfile.fullName, 'Front Desk Receptionist');
      expect(AuthGate.getScreenForRole(recProfile), isA<ReceptionistDashboardScreen>());

      // 2. Manager
      final mgrProfile = await auth.signIn(
        email: 'manager123@gmail.com',
        password: 'manager@123',
      );
      expect(mgrProfile.role, UserRole.manager);
      expect(mgrProfile.fullName, 'Restaurant Manager');
      expect(AuthGate.getScreenForRole(mgrProfile), isA<ManagerDashboardScreen>());

      // 3. Admin
      final admProfile = await auth.signIn(
        email: 'admin123@gmail.com',
        password: 'admin@123',
      );
      expect(admProfile.role, UserRole.admin);
      expect(admProfile.fullName, 'System Administrator');
      expect(AuthGate.getScreenForRole(admProfile), isA<AdminDashboardScreen>());
    });

    test('Invalid credentials throw error and do not authenticate', () async {
      final auth = AuthService();

      // Wrong password for receptionist
      expect(
        () => auth.signIn(
          email: 'reciptionist123@gmail.com',
          password: 'wrong_password',
        ),
        throwsA(isA<Exception>()),
      );

      // Wrong password for manager
      expect(
        () => auth.signIn(
          email: 'manager123@gmail.com',
          password: 'wrong_password',
        ),
        throwsA(isA<Exception>()),
      );

      // Wrong password for admin
      expect(
        () => auth.signIn(
          email: 'admin123@gmail.com',
          password: 'wrong_password',
        ),
        throwsA(isA<Exception>()),
      );

      // Non-existent user
      expect(
        () => auth.signIn(
          email: 'unknown_user_999@example.com',
          password: 'password123',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Customer can sign up and sign in to CustomerDashboardScreen', () async {
      final auth = AuthService();
      final customer = await auth.signUp(
        email: 'diner_alex@example.com',
        password: 'alexPassword123!',
        fullName: 'Alex Morgan',
      );
      expect(customer.role, UserRole.customer);
      expect(customer.fullName, 'Alex Morgan');
      expect(AuthGate.getScreenForRole(customer), isA<CustomerDashboardScreen>());

      final loggedIn = await auth.signIn(
        email: 'diner_alex@example.com',
        password: 'alexPassword123!',
      );
      expect(loggedIn.role, UserRole.customer);
      expect(loggedIn.email, 'diner_alex@example.com');
      expect(AuthGate.getScreenForRole(loggedIn), isA<CustomerDashboardScreen>());
    });

    test('AuthGate maps roles to their respective dashboard widgets', () {
      const recProfile = UserProfile(
        id: 'rec_1',
        email: 'reception@dinequeue.com',
        fullName: 'Reception Host',
        role: UserRole.receptionist,
      );
      final recWidget = AuthGate.getScreenForRole(recProfile);
      expect(recWidget, isA<ReceptionistDashboardScreen>());

      const custProfile = UserProfile(
        id: 'cust_1',
        email: 'customer@dinequeue.com',
        fullName: 'Customer One',
        role: UserRole.customer,
      );
      final custWidget = AuthGate.getScreenForRole(custProfile);
      expect(custWidget, isA<CustomerDashboardScreen>());

      const mgrProfile = UserProfile(
        id: 'mgr_1',
        email: 'manager@dinequeue.com',
        fullName: 'Manager One',
        role: UserRole.manager,
      );
      final mgrWidget = AuthGate.getScreenForRole(mgrProfile);
      expect(mgrWidget, isA<ManagerDashboardScreen>());

      const admProfile = UserProfile(
        id: 'adm_1',
        email: 'admin@dinequeue.com',
        fullName: 'Admin One',
        role: UserRole.admin,
      );
      final admWidget = AuthGate.getScreenForRole(admProfile);
      expect(admWidget, isA<AdminDashboardScreen>());
    });

    test('Sign out clears active profile and leaves user unauthenticated', () async {
      final auth = AuthService();
      await auth.signIn(email: 'manager123@gmail.com', password: 'manager@123');
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      final profile = await auth.getCurrentUserProfile();
      expect(profile, isNull);
    });
  });
}
