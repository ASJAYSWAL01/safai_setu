import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_branding.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_icon.dart';
import '../widgets/or_divider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions and Privacy Policy.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account creation UI ready — backend integration coming soon.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showGoogleSignUpMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Google sign-up will be available soon.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenGradient,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    tooltip: 'Back',
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AppBranding(compact: true),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Join Safai Setu and help build a cleaner city.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  CustomTextField(
                                    controller: _fullNameController,
                                    label: 'Full Name',
                                    hint: 'Enter your full name',
                                    prefixIcon: Icons.person_outline_rounded,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) =>
                                        Validators.required(value, fieldName: 'Full name'),
                                  ),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hint: 'Enter your email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    validator: Validators.email,
                                  ),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                    controller: _mobileController,
                                    label: 'Mobile Number',
                                    hint: 'Enter 10-digit mobile number',
                                    prefixIcon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: Validators.mobile,
                                  ),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Create a password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: true,
                                    enablePasswordToggle: true,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.password,
                                  ),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: true,
                                    enablePasswordToggle: true,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) => Validators.confirmPassword(
                                      value,
                                      _passwordController.text,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _agreedToTerms,
                                        onChanged: (value) {
                                          setState(() => _agreedToTerms = value ?? false);
                                        },
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => _agreedToTerms = !_agreedToTerms);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: RichText(
                                              text: const TextSpan(
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                  height: 1.4,
                                                ),
                                                children: [
                                                  TextSpan(text: 'I agree to the '),
                                                  TextSpan(
                                                    text: 'Terms & Conditions',
                                                    style: TextStyle(
                                                      color: AppColors.primaryGreen,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  TextSpan(text: ' and '),
                                                  TextSpan(
                                                    text: 'Privacy Policy',
                                                    style: TextStyle(
                                                      color: AppColors.primaryGreen,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  CustomButton(
                                    label: 'Create Account',
                                    isLoading: _isLoading,
                                    icon: Icons.eco_rounded,
                                    onPressed: _handleSignUp,
                                  ),
                                  const SizedBox(height: 24),
                                  const OrDivider(),
                                  const SizedBox(height: 24),
                                  OutlinedSocialButton(
                                    label: 'Sign Up with Google',
                                    leading: const GoogleIcon(),
                                    onPressed: _showGoogleSignUpMessage,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
