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
  final String? specialNotes;
  final String? assignedTable;
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
    this.specialNotes,
    this.assignedTable,
    this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurant_id'] as String? ?? '',
      restaurantName: json['restaurant_name'] as String? ?? 'Restaurant',
      userId: json['user_id'] as String? ?? '',
      guestName: json['guest_name'] as String? ?? 'Guest',
      reservationCode: json['reservation_code'] as String? ?? '#RSV1000',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      partySize: (json['party_size'] as num?)?.toInt() ?? 2,
      status: json['status'] as String? ?? 'confirmed',
      specialNotes: json['special_notes'] as String?,
      assignedTable: json['assigned_table'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map) => ReservationModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
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
      if (specialNotes != null) 'special_notes': specialNotes,
      if (assignedTable != null) 'assigned_table': assignedTable,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ReservationModel copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? userId,
    String? guestName,
    String? reservationCode,
    String? date,
    String? time,
    int? partySize,
    String? status,
    String? specialNotes,
    String? assignedTable,
    DateTime? createdAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      userId: userId ?? this.userId,
      guestName: guestName ?? this.guestName,
      reservationCode: reservationCode ?? this.reservationCode,
      date: date ?? this.date,
      time: time ?? this.time,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      specialNotes: specialNotes ?? this.specialNotes,
      assignedTable: assignedTable ?? this.assignedTable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
