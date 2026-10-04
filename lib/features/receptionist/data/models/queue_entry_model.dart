class QueueEntry {
  final String id;
  final String queueNumber;
  final String guestName;
  final int partySize;
  final int waitingMinutes;
  final int position;

  const QueueEntry({
    required this.id,
    required this.queueNumber,
    required this.guestName,
    required this.partySize,
    required this.waitingMinutes,
    required this.position,
  });

  QueueEntry copyWith({
    String? id,
    String? queueNumber,
    String? guestName,
    int? partySize,
    int? waitingMinutes,
    int? position,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      queueNumber: queueNumber ?? this.queueNumber,
      guestName: guestName ?? this.guestName,
      partySize: partySize ?? this.partySize,
      waitingMinutes: waitingMinutes ?? this.waitingMinutes,
      position: position ?? this.position,
    );
  }

  static List<QueueEntry> mockList() {
    return const [
      QueueEntry(
        id: '1',
        queueNumber: 'Q10',
        guestName: 'Kavindi Fernando',
        partySize: 3,
        waitingMinutes: 22,
        position: 1,
      ),
      QueueEntry(
        id: '2',
        queueNumber: 'Q11',
        guestName: 'Kasun Silva',
        partySize: 2,
        waitingMinutes: 17,
        position: 2,
      ),
      QueueEntry(
        id: '3',
        queueNumber: 'Q12',
        guestName: 'Ayesha Perera',
        partySize: 4,
        waitingMinutes: 12,
        position: 3,
      ),
      QueueEntry(
        id: '4',
        queueNumber: 'Q13',
        guestName: 'Nuwan Jayasuriya',
        partySize: 2,
        waitingMinutes: 28,
        position: 4,
      ),
    ];
  }
}
