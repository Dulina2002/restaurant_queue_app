enum FloorTableStatus {
  available,
  reserved,
  occupied,
  disabled;

  String get value => name;

  static FloorTableStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'occupied':
        return FloorTableStatus.occupied;
      case 'reserved':
        return FloorTableStatus.reserved;
      case 'disabled':
        return FloorTableStatus.disabled;
      case 'available':
      default:
        return FloorTableStatus.available;
    }
  }
}

class FloorTable {
  final String id;
  final String restaurantId;
  final String name;
  final int seats;
  final String guestName;
  final FloorTableStatus status;

  const FloorTable({
    required this.id,
    this.restaurantId = 'ocean_bistro',
    required this.name,
    required this.seats,
    required this.guestName,
    required this.status,
  });

  factory FloorTable.fromJson(Map<String, dynamic> json) {
    return FloorTable(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? 'ocean_bistro',
      name: json['name']?.toString() ?? '',
      seats: (json['seats'] is num) ? (json['seats'] as num).toInt() : 2,
      guestName: json['guest_name']?.toString() ?? '',
      status: FloorTableStatus.fromString(json['status']?.toString()),
    );
  }

  factory FloorTable.fromMap(Map<String, dynamic> map) => FloorTable.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'seats': seats,
      'guest_name': guestName,
      'status': status.name,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  FloorTable copyWith({
    String? id,
    String? restaurantId,
    String? name,
    int? seats,
    String? guestName,
    FloorTableStatus? status,
  }) {
    return FloorTable(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      guestName: guestName ?? this.guestName,
      status: status ?? this.status,
    );
  }

  static List<FloorTable> mockList() => mockListForRestaurant('ocean_bistro');

  static List<FloorTable> mockListForRestaurant(String restaurantId) {
    if (restaurantId == 'ocean_bistro') {
      return [
        FloorTable(id: '${restaurantId}_1', restaurantId: restaurantId, name: 'Table 01', seats: 2, guestName: '', status: FloorTableStatus.available),
        FloorTable(id: '${restaurantId}_2', restaurantId: restaurantId, name: 'Table 02', seats: 4, guestName: 'David Fernando', status: FloorTableStatus.occupied),
        FloorTable(id: '${restaurantId}_3', restaurantId: restaurantId, name: 'Table 03', seats: 4, guestName: 'Dr. Senanayake', status: FloorTableStatus.reserved),
        FloorTable(id: '${restaurantId}_4', restaurantId: restaurantId, name: 'Table 04', seats: 6, guestName: 'Ayesha Perera', status: FloorTableStatus.occupied),
        FloorTable(id: '${restaurantId}_5', restaurantId: restaurantId, name: 'Table 05', seats: 2, guestName: 'Priya & Raj', status: FloorTableStatus.occupied),
        FloorTable(id: '${restaurantId}_6', restaurantId: restaurantId, name: 'Table 06', seats: 4, guestName: 'Team lunch', status: FloorTableStatus.occupied),
        FloorTable(id: '${restaurantId}_7', restaurantId: restaurantId, name: 'Table 07', seats: 2, guestName: 'Malik', status: FloorTableStatus.reserved),
        FloorTable(id: '${restaurantId}_8', restaurantId: restaurantId, name: 'Table 08', seats: 4, guestName: '', status: FloorTableStatus.available),
        FloorTable(id: '${restaurantId}_9', restaurantId: restaurantId, name: 'Table 09', seats: 8, guestName: '', status: FloorTableStatus.disabled),
        FloorTable(id: '${restaurantId}_10', restaurantId: restaurantId, name: 'Table 10', seats: 4, guestName: 'Gihan', status: FloorTableStatus.occupied),
        FloorTable(id: '${restaurantId}_11', restaurantId: restaurantId, name: 'Table 11', seats: 2, guestName: '', status: FloorTableStatus.available),
        FloorTable(id: '${restaurantId}_12', restaurantId: restaurantId, name: 'Table 12', seats: 6, guestName: '', status: FloorTableStatus.available),
      ];
    }

    // Default floor layout for any other restaurant
    return [
      FloorTable(id: '${restaurantId}_1', restaurantId: restaurantId, name: 'Table 01', seats: 2, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_2', restaurantId: restaurantId, name: 'Table 02', seats: 2, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_3', restaurantId: restaurantId, name: 'Table 03', seats: 4, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_4', restaurantId: restaurantId, name: 'Table 04', seats: 4, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_5', restaurantId: restaurantId, name: 'Table 05', seats: 4, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_6', restaurantId: restaurantId, name: 'Table 06', seats: 6, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_7', restaurantId: restaurantId, name: 'Table 07', seats: 6, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '${restaurantId}_8', restaurantId: restaurantId, name: 'Table 08', seats: 8, guestName: '', status: FloorTableStatus.available),
    ];
  }
}
