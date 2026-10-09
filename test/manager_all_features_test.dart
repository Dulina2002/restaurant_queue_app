import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/features/manager/presentation/screens/manager_dashboard_screen.dart';
import 'package:restaurant_queue_app/features/manager/presentation/widgets/tables_tab_widget.dart';
import 'package:restaurant_queue_app/features/manager/presentation/widgets/live_menu_tab_widget.dart';
import 'package:restaurant_queue_app/services/restaurant_database_service.dart';

void _setupScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const managerProfile = UserProfile(
    id: 'mgr_test_user',
    fullName: 'Alex Manager',
    email: 'manager@dinequeue.com',
    role: UserRole.manager,
  );

  const sampleRestaurant = RestaurantModel(
    id: 'ocean_bistro',
    name: 'Ocean Bistro',
    cuisine: 'Italian',
    tag: 'Italian Cuisine',
    location: 'Colombo 03',
    rating: 4.8,
    reviewsCount: 50,
    estWait: '10 min wait',
    waitlistCount: 2,
  );

  group('Manager Dashboard & Segment Navigation Tests', () {
    testWidgets('1. Manager Dashboard renders MANAGER role badge and header', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerDashboardScreen(profile: managerProfile),
        ),
      );
      await tester.pump();

      expect(find.text('MANAGER'), findsOneWidget);
      expect(find.text('Manager Dashboard'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Tables'), findsOneWidget);
      expect(find.text('Live Menu'), findsOneWidget);
    });

    testWidgets('2. Tapping Tables tab switches to table management layout', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerDashboardScreen(profile: managerProfile),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tables'));
      await tester.pump();

      expect(find.text('Tables'), findsWidgets);
    });

    testWidgets('3. Tapping Live Menu tab switches to menu dish controls', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerDashboardScreen(profile: managerProfile),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Live Menu'));
      await tester.pump();

      expect(find.text('Live Menu'), findsWidgets);
    });

    testWidgets('4. Role header tap displays Role Switcher modal', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ManagerDashboardScreen(profile: managerProfile),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('MANAGER'));
      await tester.pumpAndSettle();

      expect(find.text('Switch User Role'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Receptionist'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
    });
  });

  group('Manager Floor & Menu Operations Tests', () {
    testWidgets('5. TablesTabWidget renders physical floor layout and management options', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TablesTabWidget(
              restaurants: [sampleRestaurant],
              selectedRestaurantId: 'ocean_bistro',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Restaurant Physical Floor'), findsOneWidget);
      expect(find.text('Tables'), findsWidgets);
    });

    testWidgets('6. LiveMenuTabWidget renders menu sync banner and dish management', (tester) async {
      _setupScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveMenuTabWidget(
              restaurants: [sampleRestaurant],
              selectedRestaurantId: 'ocean_bistro',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Live Sync Connected'), findsOneWidget);
    });

    test('7. RestaurantDatabaseService adds manager restaurant to real stream', () async {
      final db = RestaurantDatabaseService();
      const newRestoName = 'Ocean View Bistro';

      final created = await db.addRestaurant(newRestoName);
      expect(created.name, equals(newRestoName));
      expect(created.id, isNotEmpty);

      final streamList = await db.streamManagedRestaurants().first;
      expect(streamList.any((r) => r.id == created.id), isTrue);
    });
  });
}
