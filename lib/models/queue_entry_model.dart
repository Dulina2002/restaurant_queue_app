enum QueueStatus {
  waiting,
  called,
  seated,
  cancelled;

  String get value {
    switch (this) {
      case QueueStatus.waiting:
        return 'waiting';
      case QueueStatus.called:
        return 'called';
      case QueueStatus.seated:
        return 'seated';
      case QueueStatus.cancelled:
        return 'cancelled';
    }
  }

  static QueueStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'called':
        return QueueStatus.called;
      case 'seated':
        return QueueStatus.seated;
      case 'cancelled':
        return QueueStatus.cancelled;
      case 'waiting':
      default:
        return QueueStatus.waiting;
    }
  }
}

class QueueEntryModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? userId;
  final String guestName;
  final int partySize;
  final String phoneNumber;
  final QueueStatus status;
  final String queueNumber;
  final int position;
  final int estimatedWaitMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QueueEntryModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.userId,
    required this.guestName,
    required this.partySize,
    required this.phoneNumber,
    required this.status,
    required this.queueNumber,
    this.position = 1,
    this.estimatedWaitMinutes = 15,
    this.createdAt,
    this.updatedAt,
  });

  factory QueueEntryModel.fromFirestore(dynamic doc) {
    final Map<String, dynamic> data = doc is Map<String, dynamic>
        ? doc
        : (doc is Map ? Map<String, dynamic>.from(doc) : {});
    return QueueEntryModel(
      id: data['id'] as String? ?? '',
      restaurantId: data['restaurant_id'] as String? ?? '',
      restaurantName: data['restaurant_name'] as String? ?? 'Restaurant',
      userId: data['user_id'] as String?,
      guestName: data['guest_name'] as String? ?? 'Guest',
      partySize: (data['party_size'] as num?)?.toInt() ?? 2,
      phoneNumber: data['phone_number'] as String? ?? '',
      status: QueueStatus.fromString(data['status'] as String?),
      queueNumber: data['queue_number'] as String? ?? 'Q-101',
      position: (data['position'] as num?)?.toInt() ?? 1,
      estimatedWaitMinutes: (data['estimated_wait_minutes'] as num?)?.toInt() ?? 15,
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
      updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      if (userId != null) 'user_id': userId,
      'guest_name': guestName,
      'party_size': partySize,
      'phone_number': phoneNumber,
      'status': status.value,
      'queue_number': queueNumber,
      'position': position,
      'estimated_wait_minutes': estimatedWaitMinutes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  QueueEntryModel copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? userId,
    String? guestName,
    int? partySize,
    String? phoneNumber,
    QueueStatus? status,
    String? queueNumber,
    int? position,
    int? estimatedWaitMinutes,
  }) {
    return QueueEntryModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      userId: userId ?? this.userId,
      guestName: guestName ?? this.guestName,
      partySize: partySize ?? this.partySize,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      queueNumber: queueNumber ?? this.queueNumber,
      position: position ?? this.position,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
