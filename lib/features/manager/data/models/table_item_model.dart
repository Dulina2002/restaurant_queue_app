enum TableStatus { available, reserved, disabled }

class TableItemModel {
  final int id;
  final String tableNumber;
  final int capacity;
  final TableStatus status;
  final String? currentCustomerName;
  final String? reservationTime;

  const TableItemModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.currentCustomerName,
    this.reservationTime,
  });

  static List<TableItemModel> getMockTables() {
    return const [
      TableItemModel(id: 1, tableNumber: 'Table 01', capacity: 2, status: TableStatus.available),
      TableItemModel(id: 2, tableNumber: 'Table 02', capacity: 4, status: TableStatus.available),
      TableItemModel(
        id: 3,
        tableNumber: 'Table 03',
        capacity: 4,
        status: TableStatus.reserved,
        currentCustomerName: 'Dr. Senanayake',
        reservationTime: '7:30 PM',
      ),
      TableItemModel(id: 4, tableNumber: 'Table 04', capacity: 6, status: TableStatus.available),
      TableItemModel(id: 5, tableNumber: 'Table 05', capacity: 2, status: TableStatus.available),
      TableItemModel(id: 6, tableNumber: 'Table 06', capacity: 4, status: TableStatus.available),
      TableItemModel(
        id: 7,
        tableNumber: 'Table 07',
        capacity: 2,
        status: TableStatus.reserved,
        currentCustomerName: 'Mallik',
        reservationTime: '8:00 PM',
      ),
      TableItemModel(id: 8, tableNumber: 'Table 08', capacity: 4, status: TableStatus.available),
      TableItemModel(id: 9, tableNumber: 'Table 09', capacity: 8, status: TableStatus.disabled),
      TableItemModel(id: 10, tableNumber: 'Table 10', capacity: 2, status: TableStatus.available),
    ];
  }
}
