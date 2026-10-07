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

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? defaultEmail}) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: (json['email'] as String?) ?? defaultEmail ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      role: UserRole.fromString(json['role'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory UserProfile.fromMap(Map<String, dynamic> map, {String? defaultEmail}) =>
      UserProfile.fromJson(map, defaultEmail: defaultEmail);

  UserProfile copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? createdAt,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
