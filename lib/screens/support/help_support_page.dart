import 'package:flutter/material.dart';

import '../../services/problem_report_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/call_utils.dart';
import '../../widgets/app_card.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  /// Lives in the State (not the dialog) so it is never disposed while the
  /// dialog's exit animation is still running — disposing it early crashes
  /// the overlay unmount with "_dependents.isEmpty" assertions.
  final TextEditingController _reportController = TextEditingController();

  bool _loadingReport = true;
  bool _hasReported = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReportStatus();
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _loadReportStatus() async {
    bool reported;
    try {
      reported = await ProblemReportService.instance.hasReported();
    } on Object {
      reported = false;
    }
    if (!mounted) return;
    setState(() {
      _hasReported = reported;
      _loadingReport = false;
    });
  }

  Future<void> _openReportDialog() async {
    _reportController.clear();
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ───────────────────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.report_problem_outlined,
                              color: Color(0xFFE65100), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Report a Problem',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Subtitle ──────────────────────────────────
                      Text(
                        'Describe the problem you are facing. Our team will reach out to you.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      // ── Text field ────────────────────────────────
                      TextField(
                        controller: _reportController,
                        maxLines: 5,
                        maxLength: 500,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Write your problem here…',
                          hintStyle:
                              TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.primaryGreen, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Action buttons ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(
                              'Cancel',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final text =
                                        _reportController.text.trim();
                                    if (text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            duration:
                                                Duration(seconds: 2),
                                            content: Text(
                                                'Please write something first.')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => _submitting = true);
                                    try {
                                      await ProblemReportService.instance
                                          .submit(text);
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    } on Object catch (e) {
                                      setDialogState(
                                          () => _submitting = false);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          duration:
                                              const Duration(seconds: 3),
                                          content: Text(
                                              'Submit failed: $e'),
                                          backgroundColor:
                                              Colors.redAccent.shade200,
                                        ),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (submitted != true || !mounted) return;

    // Let the dialog's exit animation finish before rebuilding.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    setState(() {
      _hasReported = true;
      _loadingReport = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Your report has been submitted. '
            'Our team will reach out to you soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a question to expand the answer.',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _FaqTile(
              icon: Icons.person_outline,
              question: 'How do I report waste as a citizen?',
              answer:
                  'Login as Citizen → tap "Report Waste" → select the waste category, describe the problem, '
                  'take or upload a photo and fetch your GPS location → Submit. You will get a complaint ID to track it.',
            ),
            const _FaqTile(
              icon: Icons.person_outline,
              question: 'How do I track my complaint?',
              answer:
                  'Go to "My Complaints" from the home screen. Open any complaint to see its status, '
                  'the assigned worker, and the proof photo once the work is completed.',
            ),
            const _FaqTile(
              icon: Icons.local_shipping_outlined,
              question: 'I am a worker. How do I get a Worker ID?',
              answer:
                  'Worker IDs are generated only by your department Head. Ask your Head to create your account '
                  'from the Head portal → Workers → Generate Worker ID. Use the issued ID (e.g. WK-1001) to login.',
            ),
            const _FaqTile(
              icon: Icons.local_shipping_outlined,
              question: 'How do I submit proof of my work?',
              answer:
                  'Open your assigned task, move it through "En Route → Collecting", then take a proof photo '
                  'of the collected area and tap "Complete Task with Proof". The photo goes to the citizen and the Head.',
            ),
            const _FaqTile(
              icon: Icons.admin_panel_settings_outlined,
              question: 'I am the Head. How do I create workers?',
              answer:
                  'From the Head dashboard tap "Generate Worker ID", fill in the name, mobile and vehicle number. '
                  'A unique Worker ID is created and shown — share it with the worker.',
            ),
            const _FaqTile(
              icon: Icons.admin_panel_settings_outlined,
              question: 'How do I review proof photos as the Head?',
              answer:
                  'Open the Proofs tab (or "Review Proof Photos" on the dashboard). Compare the citizen\u2019s reported '
                  'photo with the worker\u2019s proof, then tap Approve or Reject. Rejected work is sent back to the worker.',
            ),
            const _FaqTile(
              icon: Icons.dark_mode_outlined,
              question: 'How do I switch between dark and light theme?',
              answer:
                  'Open Profile (citizen, worker or head) and toggle "Dark Theme". The whole app switches instantly '
                  'and remembers your choice for the session.',
            ),
            const _FaqTile(
              icon: Icons.verified_outlined,
              question: 'Why can\u2019t I login on a different portal?',
              answer:
                  'Each role has a separate login. Citizen accounts are rejected on the Worker and Head portals, '
                  'workers login only with their Worker ID, and only Head accounts can access the Head portal.',
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Still stuck? Contact us',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const _ContactRow(
                      icon: Icons.email_outlined,
                      label: 'tech.safaisetu@gmail.com'),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    label: '+91-7283881430',
                    onTap: () => callPhoneNumber(context, phone: '+917283881430'),
                  ),
                  const _ContactRow(
                    icon: Icons.access_time_outlined,
                    label: 'Mon–Sat, 9:00 AM – 6:00 PM'),
                  const SizedBox(height: 12),
                  if (_loadingReport)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_hasReported)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You have already reported a problem. '
                              'Our team will reach out to you soon.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openReportDialog,
                        icon: const Icon(Icons.report_problem_outlined,
                            size: 18),
                        label: const Text('Report a Problem'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: BorderSide(color: AppColors.primaryGreen),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.icon,
    required this.question,
    required this.answer,
  });

  final IconData icon;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.7)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            if (onTap != null)
              Icon(Icons.call_outlined,
                  size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
