import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';

/// Head-only screen: compose a push notification and broadcast it to every
/// signed-in citizen (delivered via the `send-notification` Supabase Edge
/// Function, which must be deployed with the FIREBASE_SERVICE_ACCOUNT secret).
class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationService.instance.sendToRole(
        role: 'citizen',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Notification sent to all citizens (${_titleController.text.trim()}).'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _titleController.clear();
      _bodyController.clear();
    } on Object catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Send Notification',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Broadcast to all citizens',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This notification is delivered to every citizen who is '
                        'signed in and has notifications enabled.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Notification title',
                    hintText: 'e.g. Garbage collection on Sunday',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a title.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Write the message for all citizens...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a message.'
                      : null,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: _sending ? 'Sending...' : 'Send to All Citizens',
                  icon: Icons.campaign_outlined,
                  isLoading: _sending,
                  onPressed: _sending ? null : _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
