class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final bool profileCompleted;
  final bool mustChangePassword;
  final BrotherStatus brotherStatus;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.profileCompleted,
    this.mustChangePassword = false,
    this.brotherStatus = BrotherStatus.active,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String),
      profileCompleted: json['profile_completed'] as bool? ?? false,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      brotherStatus: BrotherStatus.fromString(json['brother_status'] as String? ?? 'active'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.value,
      'profile_completed': profileCompleted,
      'must_change_password': mustChangePassword,
      'brother_status': brotherStatus.value,
    };
  }
}

enum UserRole {
  brother('brother'),
  vpFinance('vp_finance');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.brother,
    );
  }
}

enum BrotherStatus {
  active('active'),
  inactive('inactive');

  final String value;
  const BrotherStatus(this.value);

  static BrotherStatus fromString(String value) {
    switch (value) {
      case 'active':
        return BrotherStatus.active;
      default:
        return BrotherStatus.inactive;
    }
  }

  String get displayName {
    switch (this) {
      case BrotherStatus.active:
        return 'Active';
      case BrotherStatus.inactive:
        return 'Inactive';
    }
  }
}
