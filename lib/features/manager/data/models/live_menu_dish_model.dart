class LiveMenuDish {
  final String id;
  final String name;
  final String restaurant;
  final String category;
  final double price;
  final String description;
  final bool isAvailable;

  const LiveMenuDish({
    required this.id,
    required this.name,
    required this.restaurant,
    required this.category,
    required this.price,
    required this.description,
    this.isAvailable = true,
  });

  LiveMenuDish copyWith({
    String? id,
    String? name,
    String? restaurant,
    String? category,
    double? price,
    String? description,
    bool? isAvailable,
  }) {
    return LiveMenuDish(
      id: id ?? this.id,
      name: name ?? this.name,
      restaurant: restaurant ?? this.restaurant,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  static List<LiveMenuDish> mockList() {
    return const [
      LiveMenuDish(
        id: '1',
        name: 'Grilled Calamari & Aioli',
        restaurant: 'Ocean Bistro',
        category: 'Starters',
        price: 1850,
        description: 'Tender local squid flash-grilled with garlic herb butter',
        isAvailable: true,
      ),
      LiveMenuDish(
        id: '2',
        name: 'Seafood Black Curry',
        restaurant: 'Ocean Bistro',
        category: 'Mains',
        price: 3200,
        description: 'Traditional Sri Lankan roasted spice curry with fresh catch',
        isAvailable: true,
      ),
      LiveMenuDish(
        id: '3',
        name: 'Mango Sticky Rice',
        restaurant: 'The Mango Tree',
        category: 'Desserts',
        price: 1200,
        description: 'Fresh local mango with coconut infused sticky rice',
        isAvailable: false,
      ),
      LiveMenuDish(
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
