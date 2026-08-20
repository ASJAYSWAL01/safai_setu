import '../models/user.dart';

/// Database-backed user profile (`public.profiles`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.workerId,
    this.vehicleNumber,
    this.passwordSet = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final String? workerId;
  final String? vehicleNumber;

  /// True once the citizen has set an app login password via Supabase Auth,
  /// so they can sign in with email + password instead of Google.
  final bool passwordSet;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true
          ? json['full_name'] as String
          : (json['email'] as String?) ?? 'User',
      email: (json['email'] as String?) ?? '',
      role: _roleFromString(json['role'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      workerId: json['worker_id'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      passwordSet: (json['password_set'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'avatar_url': avatarUrl,
        'role': role.name,
        'phone': phone,
        'worker_id': workerId,
        'vehicle_number': vehicleNumber,
        'password_set': passwordSet,
      };

  AppUser toAppUser() => AppUser(
        id: id,
        name: fullName,
        email: email,
        role: role,
        phone: phone,
        workerId: workerId,
        vehicleNumber: vehicleNumber,
        photoUrl: avatarUrl,
      );

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'worker':
        return UserRole.worker;
      case 'head':
        return UserRole.head;
      default:
        return UserRole.citizen;
    }
  }
}
