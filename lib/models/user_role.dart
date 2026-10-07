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
    if (role == null || role.trim().isEmpty) return UserRole.customer;
    final normalized = role.trim().toLowerCase();
    switch (normalized) {
      case 'reception':
      case 'receptionist':
      case 'receptionists':
      case 'reception_staff':
      case 'frontdesk':
      case 'front_desk':
      case 'front_desk_staff':
      case 'desk':
      case 'host':
      case 'hostess':
      case 'staff':
      case 'greeter':
        return UserRole.receptionist;
      case 'manager':
      case 'branch_manager':
      case 'restaurant_manager':
      case 'floor_manager':
      case 'mgr':
        return UserRole.manager;
      case 'admin':
      case 'administrator':
      case 'superadmin':
      case 'super_admin':
      case 'owner':
        return UserRole.admin;
      case 'customer':
      case 'diner':
      case 'guest':
      case 'user':
        return UserRole.customer;
      default:
        if (normalized.contains('reception') ||
            normalized.contains('frontdesk') ||
            normalized.contains('host') ||
            normalized.contains('greeter')) {
          return UserRole.receptionist;
        }
        if (normalized.contains('manager') || normalized.contains('mgmt')) {
          return UserRole.manager;
        }
        if (normalized.contains('admin')) {
          return UserRole.admin;
        }
        return UserRole.customer;
    }
  }
}
