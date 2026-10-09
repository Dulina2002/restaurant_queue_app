import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/services/restaurant_database_service.dart';

void main() {
  test('RestaurantDatabaseService can add a restaurant and it appears in stream', () async {
    final service = RestaurantDatabaseService();
    const testName = 'Test Cafe Emerald';

    final created = await service.addRestaurant(testName);
    expect(created.name, testName);
    expect(created.id, isNotEmpty);

    final list = await service.streamManagedRestaurants().first;
    expect(list.any((r) => r.id == created.id), isTrue);
    expect(list.any((r) => r.name == testName), isTrue);
  });
}
