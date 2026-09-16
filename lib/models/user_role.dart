enum UserRole {
  customer,
  receptionist,
  manager,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.receptionist:
        return 'Receptionist';
      case UserRole.manager:
        return 'Manager';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.receptionist:
        return 'receptionist';
      case UserRole.manager:
        return 'manager';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.customer;
    final normalized = role.trim().toLowerCase();
    switch (normalized) {
      case 'receptionist':
      case 'staff':
      case 'host':
        return UserRole.receptionist;
      case 'manager':
        return UserRole.manager;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}
