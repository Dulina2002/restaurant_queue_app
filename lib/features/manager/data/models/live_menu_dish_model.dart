import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMenuDish {
  final String id;
  final String restaurantId;
  final String name;
  final String restaurant;
  final String category;
  final double price;
  final String description;
  final bool isAvailable;

  const LiveMenuDish({
    required this.id,
    this.restaurantId = 'ocean_bistro',
    required this.name,
    required this.restaurant,
    required this.category,
    required this.price,
    required this.description,
    this.isAvailable = true,
  });

  factory LiveMenuDish.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LiveMenuDish(
      id: doc.id,
      restaurantId: data['restaurant_id'] as String? ?? 'ocean_bistro',
      name: data['name'] as String? ?? '',
      restaurant: data['restaurant'] as String? ?? 'Ocean Bistro',
      category: data['category'] as String? ?? 'Mains',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      isAvailable: data['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'restaurant': restaurant,
      'category': category,
      'price': price,
      'description': description,
      'is_available': isAvailable,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  LiveMenuDish copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? restaurant,
    String? category,
    double? price,
    String? description,
    bool? isAvailable,
  }) {
    return LiveMenuDish(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      restaurant: restaurant ?? this.restaurant,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  static List<LiveMenuDish> mockList() {
    return [
      const LiveMenuDish(
        id: '1',
        name: 'Grilled Calamari & Aioli',
        restaurant: 'Ocean Bistro',
        category: 'Starters',
        price: 1850,
        description: 'Tender local squid flash-grilled with garlic herb butter',
        isAvailable: true,
      ),
      const LiveMenuDish(
        id: '2',
        name: 'Seafood Black Curry',
        restaurant: 'Ocean Bistro',
        category: 'Mains',
        price: 3200,
        description: 'Traditional Sri Lankan roasted spice curry with fresh catch',
        isAvailable: true,
      ),
      const LiveMenuDish(
        id: '3',
        name: 'Mango Sticky Rice',
        restaurant: 'The Mango Tree',
        category: 'Desserts',
        price: 1200,
        description: 'Fresh local mango with coconut infused sticky rice',
        isAvailable: false,
      ),
      const LiveMenuDish(
        id: '4',
        name: 'Wagyu Beef Teppanyaki',
        restaurant: 'Nihonbashi',
        category: 'Mains',
        price: 5400,
        description: 'Premium A5 wagyu slice grilled with garlic soy glaze',
        isAvailable: true,
      ),
    ];
  }
}
