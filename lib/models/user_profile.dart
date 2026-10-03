import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phoneNumber,
    this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {String? defaultEmail}) {
    final data = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      email: data['email'] as String? ?? defaultEmail ?? '',
      fullName: data['full_name'] as String? ?? 'User',
      role: UserRole.fromString(data['role'] as String?),
      avatarUrl: data['avatar_url'] as String?,
      phoneNumber: data['phone_number'] as String?,
      createdAt: data['created_at'] != null
          ? (data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(data['created_at'].toString()))
          : null,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? defaultEmail}) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: (json['email'] as String?) ?? defaultEmail ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      role: UserRole.fromString(json['role'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      createdAt: json['created_at'] != null
          ? (json['created_at'] is Timestamp
              ? (json['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(json['created_at'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
