import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory PhysicalTable.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PhysicalTable(
      id: doc.id,
      restaurantId: data['restaurant_id'] as String? ?? 'ocean_bistro',
      name: data['name'] as String? ?? '',
      seats: (data['seats'] as num?)?.toInt() ?? 2,
      guestName: data['guest_name'] as String? ?? 'No Guest',
      status: TableStatus.fromString(data['status'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'seats': seats,
      'guest_name': guestName,
      'status': status.value,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

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
    ];
  }
}
