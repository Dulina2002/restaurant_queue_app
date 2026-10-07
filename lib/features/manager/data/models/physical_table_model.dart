enum TableStatus {
  occupied,
  reserved,
  available;

  String get value {
    switch (this) {
      case TableStatus.occupied:
        return 'occupied';
      case TableStatus.reserved:
        return 'reserved';
      case TableStatus.available:
        return 'available';
    }
  }

  static TableStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'available':
      default:
        return TableStatus.available;
    }
  }
}

class PhysicalTable {
  final String id;
  final String restaurantId;
  final String name;
  final int seats;
  final String guestName;
  final TableStatus status;

  const PhysicalTable({
    required this.id,
    this.restaurantId = 'ocean_bistro',
    required this.name,
    required this.seats,
    required this.guestName,
    required this.status,
  });

  factory PhysicalTable.fromJson(Map<String, dynamic> json) {
    return PhysicalTable(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurant_id'] as String? ?? 'ocean_bistro',
      name: json['name'] as String? ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 2,
      guestName: json['guest_name'] as String? ?? 'No Guest',
      status: TableStatus.fromString(json['status'] as String?),
    );
  }

  factory PhysicalTable.fromMap(Map<String, dynamic> map) => PhysicalTable.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'seats': seats,
      'guest_name': guestName,
      'status': status.value,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  PhysicalTable copyWith({
    String? id,
    String? restaurantId,
    String? name,
    int? seats,
    String? guestName,
    TableStatus? status,
  }) {
    return PhysicalTable(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      guestName: guestName ?? this.guestName,
      status: status ?? this.status,
    );
  }

  static List<PhysicalTable> mockList() {
    return [
      const PhysicalTable(
        id: '1',
        restaurantId: 'ocean_bistro',
        name: 'Table 01',
        seats: 2,
        guestName: 'No Guest',
        status: TableStatus.occupied,
      ),
      const PhysicalTable(
        id: '2',
        restaurantId: 'ocean_bistro',
        name: 'Table 02',
        seats: 4,
        guestName: 'Dilani Fernando',
        status: TableStatus.occupied,
      ),
      const PhysicalTable(
        id: '3',
        restaurantId: 'ocean_bistro',
        name: 'Table 03',
        seats: 4,
        guestName: 'Dr. Senanayake',
        status: TableStatus.reserved,
      ),
      const PhysicalTable(
        id: '4',
        restaurantId: 'ocean_bistro',
        name: 'Table 04',
        seats: 4,
        guestName: 'No Guest',
        status: TableStatus.available,
      ),
      const PhysicalTable(
        id: '5',
        restaurantId: 'mango_tree',
        name: 'Garden Table A1',
        seats: 6,
        guestName: 'Perera Family',
        status: TableStatus.occupied,
      ),
      const PhysicalTable(
        id: '6',
        restaurantId: 'mango_tree',
        name: 'Garden Table A2',
        seats: 4,
        guestName: 'No Guest',
        status: TableStatus.available,
      ),
      const PhysicalTable(
        id: '7',
        restaurantId: 'nihonbashi',
        name: 'Sushi Bar 01',
        seats: 2,
        guestName: 'Kenji Sato',
        status: TableStatus.reserved,
      ),
      const PhysicalTable(
        id: '8',
        restaurantId: 'nihonbashi',
        name: 'Tatami Room 1',
        seats: 8,
        guestName: 'VIP Group',
        status: TableStatus.occupied,
      ),
    ];
  }
}
