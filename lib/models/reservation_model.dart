class ReservationModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String userId;
  final String guestName;
  final String reservationCode;
  final String date;
  final String time;
  final int partySize;
  final String status;
  final DateTime? createdAt;

  const ReservationModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.userId,
    required this.guestName,
    required this.reservationCode,
    required this.date,
    required this.time,
    required this.partySize,
    this.status = 'confirmed',
    this.createdAt,
  });

  factory ReservationModel.fromFirestore(dynamic doc) {
    final Map<String, dynamic> data = doc is Map<String, dynamic>
        ? doc
        : (doc is Map ? Map<String, dynamic>.from(doc) : {});
    return ReservationModel(
      id: data['id'] as String? ?? '',
      restaurantId: data['restaurant_id'] as String? ?? '',
      restaurantName: data['restaurant_name'] as String? ?? 'Restaurant',
      userId: data['user_id'] as String? ?? '',
      guestName: data['guest_name'] as String? ?? 'Guest',
      reservationCode: data['reservation_code'] as String? ?? '#RSV1000',
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      partySize: (data['party_size'] as num?)?.toInt() ?? 2,
      status: data['status'] as String? ?? 'confirmed',
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'user_id': userId,
      'guest_name': guestName,
      'reservation_code': reservationCode,
      'date': date,
      'time': time,
      'party_size': partySize,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
