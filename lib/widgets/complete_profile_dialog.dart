import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

/// Shows the "Complete Your Profile" dialog (first-run for citizens after
/// Google sign-in) or the "Edit Profile" dialog (from the Profile page).
///
/// Collects the phone number (required) and the app login password with
/// confirmation (also required). The password lets the citizen sign in later
/// with email + password instead of Google. Returns true if the profile was
/// saved.
Future<bool> showCompleteProfileDialog(
  BuildContext context, {
  String? initialPhone,
  bool isEditing = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CompleteProfileDialog(
      initialPhone: initialPhone,
      isEditing: isEditing,
    ),
  );
  return result ?? false;
}

class _CompleteProfileDialog extends StatefulWidget {
  const _CompleteProfileDialog({
    this.initialPhone,
    required this.isEditing,
  });

  final String? initialPhone;
  final bool isEditing;

  @override
  State<_CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends State<_CompleteProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController =
        TextEditingController(text: widget.initialPhone?.trim() ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final password = _passwordController.text;
    final error = await AuthService.instance.completeCitizenProfile(
      phone: _phoneController.text,
      password: password.isEmpty ? null : password,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _errorMessage = error;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_pin_circle_outlined,
                size: 44,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEditing ? 'Edit Profile' : 'Complete Your Profile',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEditing
                    ? 'Update your phone number or app login password.'
                    : 'Add your phone number and set a password so you can sign in later with your email and password instead of Google.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '10-digit mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.mobile,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'App Login Password',
                hint: 'Min 6 characters',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                enablePasswordToggle: true,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                enablePasswordToggle: true,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordController.text),
                onFieldSubmitted: _saving ? null : (_) => _save(),
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
              const SizedBox(height: 20),
              CustomButton(
                label: widget.isEditing ? 'Save Changes' : 'Save & Continue',
                icon: Icons.check,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Skip for now'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
