import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/services/auth_service.dart';
import 'package:restaurant_queue_app/screens/auth_gate.dart';
import 'package:restaurant_queue_app/screens/sign_up_screen.dart';
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

    test('Confirm password validation requires non-empty and matching password', () {
      expect(AuthService.validateConfirmPassword('', 'secret123'),
          'Please confirm your password');
      expect(AuthService.validateConfirmPassword(null, 'secret123'),
          'Please confirm your password');
      expect(AuthService.validateConfirmPassword('wrong', 'secret123'),
          'Passwords do not match');
      expect(AuthService.validateConfirmPassword('secret123', 'secret123'), isNull);
    });

    test('Verification code validation supports 6 to 8 characters', () {
      expect(AuthService.validateVerificationCode(''), isNotNull);
      expect(AuthService.validateVerificationCode('12345'), isNotNull);
      expect(AuthService.validateVerificationCode('123456789'), isNotNull);
      expect(AuthService.validateVerificationCode('123456'), isNull);
      expect(AuthService.validateVerificationCode('12345678'), isNull);
      expect(AuthService.validateVerificationCode('1234-5678'), isNull);
      expect(AuthService.validateVerificationCode('AB12CD'), isNull);
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

      final profile =
          UserProfile.fromJson(json, defaultEmail: 'reception@example.com');
      expect(profile.id, 'usr_123');
      expect(profile.fullName, 'John Doe');
      expect(profile.role, UserRole.receptionist);
      expect(profile.email, 'reception@example.com');
      expect(profile.phoneNumber, '+94771234567');

      final serialized = profile.toJson();
      expect(serialized['role'], 'receptionist');
      expect(serialized['full_name'], 'John Doe');
    });

    test('Fixed staff passwords cannot authenticate without Supabase',
        () async {
      final auth = AuthService();
      for (final pair in [
        ['reciptionist123@gmail.com', 'reciption@123'],
        ['manager123@gmail.com', 'manager@123'],
        ['admin123@gmail.com', 'admin@123'],
      ]) {
        await expectLater(auth.signIn(email: pair[0], password: pair[1]),
            throwsA(isA<Exception>()));
      }
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

    test('Customer can sign up and sign in to CustomerDashboardScreen',
        () async {
      final auth = AuthService();
      final customer = await auth.signUp(
        email: 'diner_alex@example.com',
        password: 'alexPassword123!',
        fullName: 'Alex Morgan',
      );
      expect(customer.role, UserRole.customer);
      expect(customer.fullName, 'Alex Morgan');
      expect(
          AuthGate.getScreenForRole(customer), isA<CustomerDashboardScreen>());

      final loggedIn = await auth.signIn(
        email: 'diner_alex@example.com',
        password: 'alexPassword123!',
      );
      expect(loggedIn.role, UserRole.customer);
      expect(loggedIn.email, 'diner_alex@example.com');
      expect(
          AuthGate.getScreenForRole(loggedIn), isA<CustomerDashboardScreen>());
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

    test('Sign out clears active profile and leaves user unauthenticated',
        () async {
      final auth = AuthService();
      await auth.signUp(
          email: 'logout_customer@example.com',
          password: 'customer-password',
          fullName: 'Local Customer');
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      final profile = await auth.getCurrentUserProfile();
      expect(profile, isNull);
    });
  });

  group('SignUpScreen Form Validation & Confirm Password', () {
    testWidgets('renders Confirm Password field and flags password mismatch',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Diner Account'), findsWidgets);

      // Enter mismatched passwords
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(4)); // Name, Email, Password, Confirm Password

      // Enter name, email, password, and different confirm password
      await tester.enterText(textFields.at(0), 'Jane Doe');
      await tester.enterText(textFields.at(1), 'jane@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'mismatched123');
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Correct confirm password
      await tester.enterText(textFields.at(3), 'password123');
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('submitting valid registration transitions to Verify Your Email screen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Alice Cooper');
      await tester.enterText(textFields.at(1), 'alice.test@dinequeue.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password123');
      await tester.pumpAndSettle();

      // Tap Create Diner Account button
      final createBtn = find.widgetWithText(ElevatedButton, 'Create Diner Account');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Verification screen should appear
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('alice.test@dinequeue.com'), findsOneWidget);
      expect(find.text('Verify & Complete Registration'), findsOneWidget);
      expect(find.text('Back to Account Form'), findsOneWidget);

      // Tap edit icon on the email badge to return to registration form
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Create Diner Account'), findsWidgets);
    });
  });

  group('Customer Email Verification Workflow', () {
    test('sendCustomerVerificationCode generates 6-digit code for new customer',
        () async {
      final auth = AuthService();
      final code = await auth.sendCustomerVerificationCode(
        email: 'newcustomer@dinequeue.com',
        fullName: 'New Customer',
        password: 'password123',
      );

      expect(code, isNotNull);
      expect(code.length, 6);
      expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
      expect(auth.getPendingCustomerVerificationCode('newcustomer@dinequeue.com'),
          code);
    });

    test('Staff email cannot initiate customer verification code', () async {
      final auth = AuthService();
      expect(
        () => auth.sendCustomerVerificationCode(
          email: 'admin123@gmail.com',
          fullName: 'Fake Admin',
          password: 'password123',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyCustomerRegistration rejects invalid code and accepts valid code',
        () async {
      final auth = AuthService();
      const testEmail = 'verify_flow@dinequeue.com';
      final validCode = await auth.sendCustomerVerificationCode(
        email: testEmail,
        fullName: 'Verify Tester',
        password: 'password123',
      );

      // Wrong code throws exception
      expect(
        () => auth.verifyCustomerRegistration(
          email: testEmail,
          code: '000000',
        ),
        throwsA(isA<Exception>()),
      );

      // Valid code creates customer profile
      final profile = await auth.verifyCustomerRegistration(
        email: testEmail,
        code: validCode,
      );

      expect(profile.email, testEmail);
      expect(profile.role, UserRole.customer);
      expect(profile.fullName, 'Verify Tester');
      expect(auth.getPendingCustomerVerificationCode(testEmail), isNull);
    });
  });
}
