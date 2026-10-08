import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/services/admin_supabase_service.dart';
import 'package:restaurant_queue_app/screens/admin/add_restaurant_screen.dart';
import 'package:restaurant_queue_app/screens/admin/edit_restaurant_screen.dart';
import 'package:restaurant_queue_app/screens/customer/booking/restaurant_details_screen.dart';
import 'package:restaurant_queue_app/shared/widgets/restaurant_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_queue_app/services/restaurant_image_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const dummyAdminProfile = UserProfile(
    id: 'admin_test_1',
    email: 'admin@dinequeue.com',
    fullName: 'Admin User',
    role: UserRole.admin,
  );

  final dummyAdminService = AdminSupabaseService();

  group('Restaurant Image Upload & Display Tests', () {
    testWidgets('RestaurantImage widget handles network, data uri, and empty states cleanly', (tester) async {
      // 1. Empty image renders placeholder without throwing
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestaurantImage(imageUrl: null, height: 100, width: 100),
          ),
        ),
      );
      expect(find.byType(RestaurantImage), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);

      // 2. Data URI image decoding
      const sampleDataUri =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestaurantImage(imageUrl: sampleDataUri, height: 100, width: 100),
          ),
        ),
      );
      expect(find.byType(RestaurantImage), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('AddRestaurantScreen shows upload image box and triggers picker options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AddRestaurantScreen(
            profile: dummyAdminProfile,
            adminService: dummyAdminService,
            onRestaurantAdded: (_) {},
          ),
        ),
      );

      // Locate upload box by storefront icon
      final uploadBoxIcon = find.byIcon(Icons.storefront_outlined);
      expect(uploadBoxIcon, findsOneWidget);

      // Tap to open image picker modal
      await tester.ensureVisible(uploadBoxIcon);
      await tester.tap(uploadBoxIcon);
      await tester.pumpAndSettle();

      // Options sheet should appear
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
      expect(find.text('Choose Curated Preset'), findsOneWidget);
    });

    testWidgets('EditRestaurantScreen shows Change Photo button and opens modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleRestaurant = {
        'id': 'rest_123',
        'name': 'Bistro Grill',
        'cuisine': 'Italian • Seafood',
        'address': '10 Ocean Way',
        'phone': '+94 11 257 8899',
        'email': 'bistro@food.com',
        'openingHours': '11:00 AM - 11:00 PM',
        'capacity': '40 Guests',
        'waitTime': '15m',
        'description': 'Delicious seafood and pasta.',
        'status': 'Few Tables Left',
        'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditRestaurantScreen(
            profile: dummyAdminProfile,
            adminService: dummyAdminService,
            restaurant: sampleRestaurant,
            onRestaurantSaved: (_) {},
          ),
        ),
      );

      final changePhotoText = find.text('Change Photo');
      expect(changePhotoText, findsOneWidget);

      // Tap Change Photo
      await tester.tap(changePhotoText);
      await tester.pumpAndSettle();

      expect(find.text('Change Restaurant Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('Customer RestaurantDetailsScreen renders RestaurantImage', (tester) async {
      const restaurant = RestaurantModel(
        id: 'rest_99',
        name: 'The Golden Spoon',
        cuisine: 'Seafood',
        tag: 'Seafood • Grill',
        location: 'Colombo 03',
        rating: 4.9,
        reviewsCount: 150,
        estWait: '0m',
        waitlistCount: 0,
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RestaurantDetailsScreen(
            restaurant: restaurant,
          ),
        ),
      );

      expect(find.byType(RestaurantImage), findsOneWidget);
      expect(find.text('The Golden Spoon'), findsOneWidget);
      expect(find.text('Seafood • Grill'), findsOneWidget);
    });

    test('Pizza Hub restaurant image persistence in RestaurantImageStorage', () async {
      final storage = RestaurantImageStorage();
      const pizzaUrl = 'https://images.unsplash.com/photo-1513104890138-7c749659a591';

      // Save for Pizza Hub
      await storage.saveImage(
        id: 'pizza_hub_123',
        name: 'Pizza Hub',
        imageUrl: pizzaUrl,
      );

      // Verify retrieval by ID
      expect(storage.getImage(id: 'pizza_hub_123'), equals(pizzaUrl));

      // Verify retrieval by exact and case-insensitive Name
      expect(storage.getImage(name: 'Pizza Hub'), equals(pizzaUrl));
      expect(storage.getImage(name: 'pizza hub'), equals(pizzaUrl));

      // Verify culinary fallback for any restaurant with 'pizza' in name
      final autoFallback = storage.getImage(name: 'New Pizza Palace');
      expect(autoFallback, isNotNull);
      expect(autoFallback!.contains('unsplash.com'), isTrue);
    });

    test('RestaurantModel.fromJson resolves Pizza Hub image via RestaurantImageStorage when backend image_url is missing', () {
      final storage = RestaurantImageStorage();
      const pizzaUrl = 'https://images.unsplash.com/photo-1513104890138-7c749659a591';
      storage.saveImage(id: 'pizza_hub_001', name: 'Pizza Hub', imageUrl: pizzaUrl);

      // Simulate Supabase row without image_url column
      final rowFromSupabase = {
        'id': 'pizza_hub_001',
        'name': 'Pizza Hub',
        'cuisine': 'Italian • Pizza',
        'location': 'Colombo 05',
        'is_active': true,
        'is_queue_available': true,
        'est_wait': '15m',
      };

      final model = RestaurantModel.fromJson(rowFromSupabase);
      expect(model.name, 'Pizza Hub');
      expect(model.imageUrl, equals(pizzaUrl));
    });

    testWidgets('RestaurantImage displays Pizza Hub image via name resolution', (tester) async {
      final storage = RestaurantImageStorage();
      const pizzaUrl = 'https://images.unsplash.com/photo-1513104890138-7c749659a591';
      await storage.saveImage(id: 'rest_pizza_hub', name: 'Pizza Hub', imageUrl: pizzaUrl);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestaurantImage(
              imageUrl: null, // imageUrl is null from database
              restaurantName: 'Pizza Hub',
              cuisine: 'Italian • Pizza',
              height: 140,
              width: 300,
            ),
          ),
        ),
      );

      expect(find.byType(RestaurantImage), findsOneWidget);
      // Image widget is rendered instead of fallback icon
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('RestaurantImage prioritizes admin-uploaded custom image over generic stock fallback', (tester) async {
      final storage = RestaurantImageStorage();
      const adminUploadedUrl = 'https://custom-admin-upload.test/pizza_hub_real.jpg';
      const genericStockUrl = 'https://images.unsplash.com/photo-stock-fallback';

      // Admin uploaded a photo for Pizza Hub
      await storage.saveImage(
        id: 'pizza_hub_123',
        name: 'Pizza Hub',
        imageUrl: adminUploadedUrl,
      );

      // Customer Dashboard renders with stock URL passed in model
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestaurantImage(
              imageUrl: genericStockUrl,
              restaurantId: 'pizza_hub_123',
              restaurantName: 'Pizza Hub',
              cuisine: 'Pizza',
              height: 140,
              width: 300,
            ),
          ),
        ),
      );

      expect(find.byType(RestaurantImage), findsOneWidget);
      // Verify Image widget rendered using the admin-uploaded URL
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, equals(adminUploadedUrl));
    });
  });
}

