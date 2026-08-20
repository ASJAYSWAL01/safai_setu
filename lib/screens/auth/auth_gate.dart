import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../head/head_shell.dart';
import '../login_page.dart';
import '../main_shell.dart';
import '../splash/splash_screen.dart';
import '../worker/worker_shell.dart';

/// True once the new splash has been shown for its minimum duration on the
/// very first app launch. Later AuthGate mounts (e.g. after logout) skip it.
bool _coldStartSplashDone = false;

/// Restores Supabase session on startup and routes by `profiles.role`.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _minSplashDone = false;

  @override
  void initState() {
    super.initState();
    if (!_coldStartSplashDone) {
      _coldStartSplashDone = true;
      // Keep the splash on screen for a short moment so it is seen.
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _minSplashDone = true);
      });
    } else {
      _minSplashDone = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.isInitializing,
      builder: (context, initializing, _) {
        if (initializing || !_minSplashDone) {
          return const SplashScreen();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: AuthService.instance.isAccountNotConfigured,
          builder: (context, notConfigured, _) {
            if (notConfigured) {
              // Authenticated but the profile row is missing/malformed —
              // refuse access instead of granting a citizen dashboard.
              return const _AccountNotConfiguredScreen();
            }

            return ValueListenableBuilder(
              valueListenable: AuthService.instance.currentUser,
              builder: (context, user, _) {
                if (user == null) {
                  return const LoginPage();
                }

                switch (user.role) {
                  case UserRole.worker:
                    return const WorkerShell();
                  case UserRole.head:
                    return const HeadShell();
                  case UserRole.citizen:
                    return const MainShell();
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Shown when a valid session exists but `public.profiles` has no usable row
/// for the account (e.g. an email/password account an admin never configured).
class _AccountNotConfiguredScreen extends StatelessWidget {
  const _AccountNotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenGradient,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Account not configured',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account is not configured correctly. '
                    'Please contact the administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    label: 'Logout',
                    icon: Icons.logout,
                    onPressed: () => performLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared logout helper — clears Supabase/Google session and resets nav stack.
Future<void> performLogout(BuildContext context) async {
  await AuthService.instance.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthGate()),
    (route) => false,
  );
}
