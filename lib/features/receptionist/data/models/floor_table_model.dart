enum FloorTableStatus {
  available,
  reserved,
  occupied,
  disabled,
}

class FloorTable {
  final String id;
  final String name;
  final int seats;
  final String guestName;
  final FloorTableStatus status;

  const FloorTable({
    required this.id,
    required this.name,
    required this.seats,
    required this.guestName,
    required this.status,
  });

  FloorTable copyWith({
    String? id,
    String? name,
    int? seats,
    String? guestName,
    FloorTableStatus? status,
  }) {
    return FloorTable(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      guestName: guestName ?? this.guestName,
      status: status ?? this.status,
    );
  }

  static List<FloorTable> mockList() {
    return const [
      FloorTable(id: '1', name: 'Table 01', seats: 2, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '2', name: 'Table 02', seats: 4, guestName: 'David Fernando', status: FloorTableStatus.occupied),
      FloorTable(id: '3', name: 'Table 03', seats: 4, guestName: 'Dr. Senanayake', status: FloorTableStatus.reserved),
      FloorTable(id: '4', name: 'Table 04', seats: 6, guestName: 'Ayesha Perera', status: FloorTableStatus.occupied),
      FloorTable(id: '5', name: 'Table 05', seats: 2, guestName: 'Priya & Raj', status: FloorTableStatus.occupied),
      FloorTable(id: '6', name: 'Table 06', seats: 4, guestName: 'Team lunch', status: FloorTableStatus.occupied),
      FloorTable(id: '7', name: 'Table 07', seats: 2, guestName: 'Malik', status: FloorTableStatus.reserved),
      FloorTable(id: '8', name: 'Table 08', seats: 4, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '9', name: 'Table 09', seats: 8, guestName: '', status: FloorTableStatus.disabled),
      FloorTable(id: '10', name: 'Table 10', seats: 4, guestName: 'Gihan', status: FloorTableStatus.occupied),
      FloorTable(id: '11', name: 'Table 11', seats: 2, guestName: '', status: FloorTableStatus.available),
      FloorTable(id: '12', name: 'Table 12', seats: 6, guestName: '', status: FloorTableStatus.available),
    ];
  }
}
