/// The three types of accounts in Safai Setu.
enum UserRole { citizen, worker, head }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.worker:
        return 'Worker';
      case UserRole.head:
        return 'Head';
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.workerId,
    this.vehicleNumber,
    this.password,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// 10-digit mobile number (citizens and workers).
  final String? phone;

  /// Department worker ID — generated only by the Head.
  final String? workerId;

  /// Vehicle number for pickup truck workers.
  final String? vehicleNumber;

  /// Demo-only plain-text password. In a real backend this never exists.
  final String? password;

  /// Avatar URL (e.g. Google profile picture).
  final String? photoUrl;

  bool get isCitizen => role == UserRole.citizen;
  bool get isWorker => role == UserRole.worker;
  bool get isHead => role == UserRole.head;
}
