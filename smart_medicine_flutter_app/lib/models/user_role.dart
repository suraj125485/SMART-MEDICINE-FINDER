enum UserRole {
  customer,
  pharmacy,
  admin,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.pharmacy:
        return 'Pharmacy Owner';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get id {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.pharmacy:
        return 'pharmacy';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.customer:
        return 'Search medicines, locate nearest stock & reserve prescriptions';
      case UserRole.pharmacy:
        return 'Manage store stock, update unit prices & approve customer holds';
      case UserRole.admin:
        return 'Verify drug licenses, manage listings & inspect audit logs';
    }
  }
}
