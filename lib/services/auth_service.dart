import 'package:flutter/foundation.dart';

import '../data/app_repository.dart';
import '../models/user.dart';

/// A simulated Google account offered in the demo sign-in picker.
class GoogleDemoAccount {
  const GoogleDemoAccount({required this.name, required this.email});

  final String name;
  final String email;
}

/// In-memory authentication service.
///
/// This is a demo backend so the app is fully usable without any server.
/// To use real authentication, replace the internals with Firebase Auth /
/// your backend while keeping the same method signatures.
class AuthService {
  AuthService._() {
    _seedAccounts();
  }

  static final AuthService instance = AuthService._();

  /// Notifies the UI whenever the signed-in user changes.
  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  final List<AppUser> _accounts = [];

  AppUser? get user => currentUser.value;

  void _seedAccounts() {
    _accounts.addAll([
      const AppUser(
        id: 'H-001',
        name: 'Municipal Head Officer',
        email: 'head@safaisetu.in',
        phone: '9876500001',
        role: UserRole.head,
        password: 'head123',
      ),
      const AppUser(
        id: 'W-1001',
        name: 'Ramesh Kumar',
        email: 'ramesh.worker@safaisetu.in',
        phone: '9876500002',
        role: UserRole.worker,
        workerId: 'WK-1001',
        vehicleNumber: 'GJ-18-WM-1024',
        password: 'worker123',
      ),
      const AppUser(
        id: 'W-1002',
        name: 'Suresh Patil',
        email: 'suresh.worker@safaisetu.in',
        phone: '9876500003',
        role: UserRole.worker,
        workerId: 'WK-1002',
        vehicleNumber: 'GJ-18-WM-1025',
        password: 'worker123',
      ),
      const AppUser(
        id: 'C-1001',
        name: 'Ashish Kumar',
        email: 'citizen@safaisetu.in',
        phone: '9876543210',
        role: UserRole.citizen,
        password: 'citizen123',
      ),
    ]);
  }

  List<AppUser> get workers =>
      _accounts.where((u) => u.role == UserRole.worker).toList();

  AppUser? getWorkerByWorkerId(String workerId) {
    for (final account in _accounts) {
      if (account.role == UserRole.worker && account.workerId == workerId) {
        return account;
      }
    }
    return null;
  }

  AppUser? findAccountByEmail(String email) {
    for (final account in _accounts) {
      if (account.email.toLowerCase() == email.trim().toLowerCase()) {
        return account;
      }
    }
    return null;
  }

  /// Demo Google accounts shown in the simulated Google sign-in sheet.
  static const List<GoogleDemoAccount> googleAccounts = [
    GoogleDemoAccount(name: 'Ashish Kumar', email: 'ashish.demo@gmail.com'),
    GoogleDemoAccount(name: 'Priya Sharma', email: 'priya.demo@gmail.com'),
  ];

  /// Demo-only simulated Google sign-in. Creates a citizen account on first
  /// use and signs it in. Replace with the real `google_sign_in` / Firebase
  /// flow once your backend credentials are configured.
  AppUser signInWithGoogle(GoogleDemoAccount account) {
    var user = findAccountByEmail(account.email);
    if (user == null) {
      user = AppUser(
        id: 'C-${1000 + _accounts.length}',
        name: account.name,
        email: account.email,
        role: UserRole.citizen,
        password: null,
      );
      _accounts.add(user);
    }
    currentUser.value = user;
    return user;
  }

  /// Citizen login with email OR mobile number. Rejects worker/head accounts.
  String? loginCitizen(
      {required String emailOrMobile, required String password}) {
    final identifier = emailOrMobile.trim().toLowerCase();
    for (final account in _accounts) {
      final emailMatch = account.email.toLowerCase() == identifier;
      final mobileMatch = account.phone != null &&
          account.phone == identifier.replaceAll(RegExp(r'\s+'), '');
      if (emailMatch || mobileMatch) {
        if (account.role != UserRole.citizen) {
          return 'This account is not registered as a Citizen.';
        }
        if (account.password != password) {
          return 'Incorrect password. Please try again.';
        }
        currentUser.value = account;
        return null;
      }
    }
    return 'No account found with this email or mobile number.';
  }

  /// Worker login using the Worker ID issued by the Head.
  String? loginWorker({required String workerId, required String password}) {
    final worker = getWorkerByWorkerId(workerId.trim().toUpperCase());
    if (worker == null) {
      return 'Worker ID not found. It is issued by your department Head.';
    }
    if (worker.password != password) {
      return 'Incorrect password. Please try again.';
    }
    currentUser.value = worker;
    return null;
  }

  /// Head login — only Head accounts are accepted here. Citizens and workers
  /// are explicitly rejected so they cannot access the Head dashboard.
  String? loginHead({required String identifier, required String password}) {
    final value = identifier.trim().toLowerCase();
    for (final account in _accounts) {
      final emailMatch = account.email.toLowerCase() == value;
      final mobileMatch = account.phone != null &&
          account.phone == value.replaceAll(RegExp(r'\s+'), '');
      if (emailMatch || mobileMatch) {
        if (account.role != UserRole.head) {
          return 'This account is not authorized as Head. Citizen/Worker accounts cannot access the Head portal.';
        }
        if (account.password != password) {
          return 'Incorrect password. Please try again.';
        }
        currentUser.value = account;
        return null;
      }
    }
    return 'No Head account found with this email or mobile number.';
  }

  /// Citizen self sign-up.
  String? signUpCitizen({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) {
    if (findAccountByEmail(email) != null) {
      return 'An account with this email already exists. Please login.';
    }
    for (final account in _accounts) {
      if (account.phone == mobile) {
        return 'An account with this mobile number already exists.';
      }
    }
    _accounts.add(AppUser(
      id: 'C-${1000 + _accounts.length}',
      name: name,
      email: email,
      phone: mobile,
      role: UserRole.citizen,
      password: password,
    ));
    return null;
  }

  /// Creates a new worker account. Only the Head can do this — the Worker ID
  /// is generated here and shared with the worker. Returns the new worker.
  AppUser? registerWorker({
    required String name,
    required String phone,
    required String vehicleNumber,
  }) {
    if (user == null || !user!.isHead) return null;
    final workerId = 'WK-${1000 + workers.length + 1}';
    final worker = AppUser(
      id: 'W-$workerId',
      name: name,
      email: '${workerId.toLowerCase()}@safaisetu.in',
      phone: phone,
      role: UserRole.worker,
      workerId: workerId,
      vehicleNumber: vehicleNumber,
      password: 'worker123',
    );
    _accounts.add(worker);
    return worker;
  }

  /// Updates a worker's profile (name, mobile, vehicle). Only the Head can do
  /// this. The Worker ID never changes. Returns an error message or null.
  String? updateWorker({
    required String id,
    required String name,
    required String phone,
    required String vehicleNumber,
  }) {
    final index =
        _accounts.indexWhere((a) => a.id == id && a.role == UserRole.worker);
    if (index == -1) return 'Worker not found.';
    for (final account in _accounts) {
      if (account.id != id && account.phone == phone) {
        return 'Another account already uses this mobile number.';
      }
    }
    final old = _accounts[index];
    _accounts[index] = AppUser(
      id: old.id,
      name: name,
      email: old.email,
      phone: phone,
      role: UserRole.worker,
      workerId: old.workerId,
      vehicleNumber: vehicleNumber,
      password: old.password,
    );
    // Keep the current session in sync if this worker is logged in somewhere.
    if (currentUser.value?.id == id) {
      currentUser.value = _accounts[index];
    }
    return null;
  }

  /// Removes a worker account. Only the Head can do this. Their open tasks
  /// are unassigned and their cached live location is cleared so it stops
  /// showing on the Head's map/dashboard. Returns an error message or null.
  String? deleteWorker(String id) {
    final index =
        _accounts.indexWhere((a) => a.id == id && a.role == UserRole.worker);
    if (index == -1) return 'Worker not found.';
    final worker = _accounts[index];
    if (worker.workerId != null) {
      AppRepository.instance.unassignTasksForWorker(worker.workerId!);
      AppRepository.instance.clearWorkerLocation(worker.workerId!);
    }
    _accounts.removeAt(index);
    return null;
  }

  void logout() {
    currentUser.value = null;
  }
}
