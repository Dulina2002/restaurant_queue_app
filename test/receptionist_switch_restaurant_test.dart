import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/restaurant_model.dart';
import 'package:restaurant_queue_app/services/receptionist_context.dart';

void main() {
  group('Receptionist Restaurant Switching Tests', () {
    const chinaTown = RestaurantModel(
      id: 'china_town_1791447601072',
      name: 'China town',
      cuisine: 'Chinese',
      tag: 'Chinese Cuisine',
      location: 'Malabe',
      rating: 4.5,
      reviewsCount: 10,
      estWait: 'Direct Seating',
      waitlistCount: 0,
    );

    const nihonbashi = RestaurantModel(
      id: 'nihonbashi',
      name: 'Nihonbashi',
      cuisine: 'Japanese',
      tag: 'Japanese',
      location: 'Colombo 03',
      rating: 4.9,
      reviewsCount: 100,
      estWait: '20 min wait',
      waitlistCount: 2,
    );

    const oceanBistro = RestaurantModel(
      id: 'ocean_bistro',
      name: 'Ocean Bistro',
      cuisine: 'Italian',
      tag: 'Italian',
      location: 'Colombo 03',
      rating: 4.8,
      reviewsCount: 50,
      estWait: '10 min wait',
      waitlistCount: 1,
    );

    test('Switching to China town updates active restaurant and does not revert to Nihonbashi', () {
      final context = ReceptionistContext();

      // Initialize with default fallback list
      context.initialize([nihonbashi, oceanBistro], preferredRestaurantId: 'nihonbashi');
      expect(context.activeRestaurantId, equals('nihonbashi'));

      // Receptionist selects China town
      context.setActiveRestaurant(chinaTown);
      expect(context.activeRestaurantId, equals('china_town_1791447601072'));
      expect(context.activeRestaurantName, equals('China town'));

      // If initialize is triggered again with a stream emission that only has fallback items
      context.initialize([nihonbashi, oceanBistro], preferredRestaurantId: 'nihonbashi');

      // It must NOT revert back to nihonbashi!
      expect(context.activeRestaurantId, equals('china_town_1791447601072'));
      expect(context.activeRestaurantName, equals('China town'));
    });
  });
}
