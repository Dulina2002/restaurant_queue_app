enum TableStatus {
  occupied,
  reserved,
  available,
}

class PhysicalTable {
  final String id;
  final String name;
  final int seats;
  final String guestName;
  final TableStatus status;

  const PhysicalTable({
    required this.id,
    required this.name,
    required this.seats,
    required this.guestName,
    required this.status,
  });

  PhysicalTable copyWith({
    String? id,
    String? name,
    int? seats,
    String? guestName,
    TableStatus? status,
  }) {
    return PhysicalTable(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      guestName: guestName ?? this.guestName,
      status: status ?? this.status,
    );
  }

  static List<PhysicalTable> mockList() {
    return const [
      PhysicalTable(
        id: '1',
        name: 'Table 01',
        seats: 2,
        guestName: 'No Guest',
        status: TableStatus.occupied,
      ),
      PhysicalTable(
        id: '2',
        name: 'Table 02',
        seats: 4,
        guestName: 'Dilani Fernando',
        status: TableStatus.occupied,
      ),
      PhysicalTable(
        id: '3',
        name: 'Table 03',
        seats: 4,
        guestName: 'Dr. Senanayake',
        status: TableStatus.reserved,
      ),
      PhysicalTable(
        id: '4',
        name: 'Table 04',
        seats: 4,
        guestName: 'No Guest',
        status: TableStatus.available,
      ),
    ];
  }
}
