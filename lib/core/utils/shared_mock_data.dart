import '../../features/receptionist/data/models/floor_table_model.dart';
import '../../features/receptionist/data/models/queue_entry_model.dart';

class SharedMockData {
  static final SharedMockData _instance = SharedMockData._internal();
  factory SharedMockData() => _instance;

  SharedMockData._internal() {
    tables = List.from(FloorTable.mockList());
    queue = List.from(QueueEntry.mockList());
  }

  late List<FloorTable> tables;
  late List<QueueEntry> queue;
}
