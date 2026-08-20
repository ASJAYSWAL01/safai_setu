import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_branding.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_icon.dart';
import '../widgets/language_picker.dart';
import '../widgets/or_divider.dart';

/// Single sign-in entry point.
///
/// Citizens sign in with Google; workers and heads sign in with the email +
/// password created for them in Supabase Auth. This screen never decides a
/// role — the database (`public.profiles.role`) decides the dashboard after
/// authentication.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleEmailPasswordLogin() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final error = await AuthService.instance.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (error != null) _showError(error);
    // AuthGate listens to currentUser and routes by profiles.role.
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _errorMessage = null);

    final error = await AuthService.instance.signInWithGoogle(context);
    if (error != null) _showError(error);
    // AuthGate listens to currentUser and routes by profiles.role.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const AppBranding(),
                    const SizedBox(height: 24),
                    // Language picker — top-right of the login card.
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => showLanguagePicker(context),
                        icon: Icon(Icons.language,
                            size: 18, color: AppColors.primaryGreen),
                        label: Text(
                          LanguageService.instance.current.value.nativeLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.paleGreen,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: AuthService.instance.isSigningIn,
                        builder: (context, signingIn, _) {
                          return Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppStrings.of(context).welcomeTitle,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.of(context).loginSubtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomTextField(
                                  controller: _emailController,
                                  label: AppStrings.of(context).email,
                                  hint: AppStrings.of(context).emailHint,
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: AppStrings.of(context).password,
                                  hint: AppStrings.of(context).passwordHint,
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: true,
                                  enablePasswordToggle: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: signingIn
                                      ? null
                                      : (_) => _handleEmailPasswordLogin(),
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 20),
                                CustomButton(
                                  label: AppStrings.of(context).login,
                                  icon: Icons.login,
                                  isLoading: signingIn,
                                  onPressed:
                                      signingIn ? null : _handleEmailPasswordLogin,
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.redAccent.shade200,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                const OrDivider(),
                                const SizedBox(height: 22),
                                OutlinedSocialButton(
                                  label: signingIn
                                      ? AppStrings.of(context).signingIn
                                      : AppStrings.of(context)
                                          .continueWithGoogle,
                                  leading: signingIn
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryGreen,
                                          ),
                                        )
                                      : const GoogleIcon(),
                                  onPressed:
                                      signingIn ? null : _handleGoogleSignIn,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.of(context).loginFooter,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
