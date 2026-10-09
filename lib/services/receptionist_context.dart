import 'package:flutter/foundation.dart';
import '../models/restaurant_model.dart';

/// Holds the active restaurant context for the Receptionist role.
/// Enables seamless multi-restaurant switching and state distribution
/// across all receptionist screens (Dashboard, Queue, Tables, Reservations).
class ReceptionistContext {
  static final ReceptionistContext _instance = ReceptionistContext._internal();
  factory ReceptionistContext() => _instance;
  ReceptionistContext._internal();

  /// ValueNotifier allowing widgets to reactively re-render on restaurant change.
  final ValueNotifier<RestaurantModel?> activeRestaurantNotifier =
      ValueNotifier<RestaurantModel?>(null);

  /// Currently selected restaurant.
  RestaurantModel? get activeRestaurant => activeRestaurantNotifier.value;

  /// Active restaurant identifier (fallback to 'ocean_bistro' if not set).
  String get activeRestaurantId =>
      activeRestaurantNotifier.value?.id ?? 'ocean_bistro';

  /// Active restaurant display name (fallback to 'Ocean Bistro' if not set).
  String get activeRestaurantName =>
      activeRestaurantNotifier.value?.name ?? 'Ocean Bistro';

  /// Update the active restaurant.
  void setActiveRestaurant(RestaurantModel restaurant) {
    if (activeRestaurantNotifier.value?.id != restaurant.id) {
      activeRestaurantNotifier.value = restaurant;
    }
  }

  /// Initialize selection from available restaurants list.
  /// Prioritizes existing selection -> preferred assigned restaurant -> first item in list.
  void initialize(List<RestaurantModel> restaurants, {String? preferredRestaurantId}) {
    if (restaurants.isEmpty) return;

    if (activeRestaurantNotifier.value != null) {
      final existing = restaurants.where((r) => r.id == activeRestaurantNotifier.value!.id);
      if (existing.isNotEmpty) {
        activeRestaurantNotifier.value = existing.first;
      }
      return;
    }

    if (preferredRestaurantId != null && preferredRestaurantId.isNotEmpty) {
      final preferred = restaurants.where((r) => r.id == preferredRestaurantId);
      if (preferred.isNotEmpty) {
        activeRestaurantNotifier.value = preferred.first;
        return;
      }
    }

    activeRestaurantNotifier.value = restaurants.first;
  }
}
