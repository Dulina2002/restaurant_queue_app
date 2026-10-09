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
    final normalized = role
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    switch (normalized) {
      case 'reception':
      case 'reciption':
      case 'receptionist':
      case 'reciptionist':
      case 'receptionists':
      case 'reciptionists':
      case 'reception_staff':
      case 'reciption_staff':
      case 'frontdesk':
      case 'front_desk':
      case 'front_desk_staff':
      case 'desk':
      case 'host':
      case 'hostess':
      case 'staff':
      case 'greeter':
      case 'concierge':
      case 'clerk':
      case 'cashier':
      case 'waiter':
      case 'waitstaff':
        return UserRole.receptionist;
      case 'manager':
      case 'branch_manager':
      case 'restaurant_manager':
      case 'floor_manager':
      case 'general_manager':
      case 'assistant_manager':
      case 'supervisor':
      case 'mgr':
      case 'mgmt':
        return UserRole.manager;
      case 'admin':
      case 'administrator':
      case 'superadmin':
      case 'super_admin':
      case 'owner':
      case 'root':
        return UserRole.admin;
      case 'customer':
      case 'diner':
      case 'guest':
      case 'user':
      case 'client':
        return UserRole.customer;
      default:
        if (normalized.contains('reception') ||
            normalized.contains('reciption') ||
            normalized.contains('recept') ||
            normalized.contains('recipt') ||
            normalized.contains('frontdesk') ||
            normalized.contains('front_desk') ||
            normalized.contains('host') ||
            normalized.contains('greeter') ||
            normalized.contains('cashier') ||
            normalized.contains('clerk') ||
            normalized.contains('desk')) {
          return UserRole.receptionist;
        }
        if (normalized.contains('manager') ||
            normalized.contains('mgmt') ||
            normalized.contains('mgr') ||
            normalized.contains('supervis')) {
          return UserRole.manager;
        }
        if (normalized.contains('admin') ||
            normalized.contains('owner') ||
            normalized.contains('root')) {
          return UserRole.admin;
        }
        return UserRole.customer;
    }
  }
}
