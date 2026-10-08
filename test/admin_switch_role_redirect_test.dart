import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/screens/admin/admin_dialogs.dart';
import 'package:restaurant_queue_app/screens/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const dummyAdminProfile = UserProfile(
    id: 'admin_123',
    email: 'admin@dinequeue.com',
    fullName: 'Admin User',
    role: UserRole.admin,
  );

  group('Admin Role Selection to Sign In Redirection Tests', () {
    testWidgets('SwitchRoleDialog renders 4 roles and clicking Customer redirects to SignInScreen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const SwitchRoleDialog(
                      profile: dummyAdminProfile,
                      currentRole: UserRole.admin,
                    ),
                  );
                },
                child: const Text('Open Switch Role'),
              ),
            ),
          ),
        ),
      );

      // Open the Switch Role Dialog
      await tester.tap(find.text('Open Switch Role'));
      await tester.pumpAndSettle();

      // Verify Dialog Title and 4 roles
      expect(find.text('Switch User Role'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Receptionist'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);

      // Tap on 'Customer' role
      await tester.tap(find.text('Customer'));
      await tester.pumpAndSettle();

      // Verify that it redirects to SignInScreen with empty email and password fields
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Selected Role: Customer'), findsOneWidget);
      // Ensure fields are EMPTY and NOT pre-filled
      expect(find.text('customer123@gmail.com'), findsNothing);
      expect(find.text('customer@123'), findsNothing);

      // Verify TextFormField inputs have empty text
      final textFormFieldWidgets = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(textFormFieldWidgets.length, equals(2));
      expect(textFormFieldWidgets[0].controller?.text, isEmpty);
      expect(textFormFieldWidgets[1].controller?.text, isEmpty);
    });

    testWidgets('Clicking Manager in SwitchRoleDialog redirects to SignInScreen with empty fields',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const SwitchRoleDialog(
                      profile: dummyAdminProfile,
                      currentRole: UserRole.admin,
                    ),
                  );
                },
                child: const Text('Open Switch Role'),
              ),
            ),
          ),
        ),
      );

      // Open the Switch Role Dialog
      await tester.tap(find.text('Open Switch Role'));
      await tester.pumpAndSettle();

      // Tap on 'Manager' role
      await tester.tap(find.text('Manager'));
      await tester.pumpAndSettle();

      // Verify that it redirects to SignInScreen with empty fields
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Selected Role: Manager'), findsOneWidget);
      // Ensure fields are EMPTY and NOT pre-filled
      expect(find.text('manager123@gmail.com'), findsNothing);
      expect(find.text('manager@123'), findsNothing);

      final textFormFieldWidgets = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(textFormFieldWidgets.length, equals(2));
      expect(textFormFieldWidgets[0].controller?.text, isEmpty);
      expect(textFormFieldWidgets[1].controller?.text, isEmpty);
    });

    testWidgets('Clicking Continue to Sign In button redirects to SignInScreen with selected role',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const SwitchRoleDialog(
                      profile: dummyAdminProfile,
                      currentRole: UserRole.admin,
                    ),
                  );
                },
                child: const Text('Open Switch Role'),
              ),
            ),
          ),
        ),
      );

      // Open the Switch Role Dialog
      await tester.tap(find.text('Open Switch Role'));
      await tester.pumpAndSettle();

      // Tap 'Continue to Sign In' button
      await tester.tap(find.text('Continue to Sign In'));
      await tester.pumpAndSettle();

      // Verify redirection to SignInScreen
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Selected Role: Administrator'), findsOneWidget);

      final textFormFieldWidgets = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(textFormFieldWidgets.length, equals(2));
      expect(textFormFieldWidgets[0].controller?.text, isEmpty);
      expect(textFormFieldWidgets[1].controller?.text, isEmpty);
    });

    testWidgets('Clicking Receptionist in SwitchRoleDialog redirects to SignInScreen with empty fields',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const SwitchRoleDialog(
                      profile: dummyAdminProfile,
                      currentRole: UserRole.admin,
                    ),
                  );
                },
                child: const Text('Open Switch Role'),
              ),
            ),
          ),
        ),
      );

      // Open the Switch Role Dialog
      await tester.tap(find.text('Open Switch Role'));
      await tester.pumpAndSettle();

      // Tap on 'Receptionist' role
      await tester.tap(find.text('Receptionist'));
      await tester.pumpAndSettle();

      // Verify that it redirects to SignInScreen with empty fields
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Selected Role: Receptionist'), findsOneWidget);

      final textFormFieldWidgets = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(textFormFieldWidgets.length, equals(2));
      expect(textFormFieldWidgets[0].controller?.text, isEmpty);
      expect(textFormFieldWidgets[1].controller?.text, isEmpty);
    });
  });
}

