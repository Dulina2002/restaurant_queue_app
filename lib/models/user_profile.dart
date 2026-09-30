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
          ? DateTime.tryParse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role.value,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  UserProfile copyWith({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
    String? phoneNumber,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
    );
  }
}
