import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(        title: Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                      label: 'support@safaisetu.in'),
                  const _ContactRow(
                      icon: Icons.phone_outlined, label: '+91 98765 00000'),
                  const _ContactRow(
                      icon: Icons.access_time_outlined,
                      label: 'Mon–Sat, 9:00 AM – 6:00 PM'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Report-a-problem form is coming soon. Please email us meanwhile.')),
                        );
                      },
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
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
        border: Border.all(color: AppColors.borderColor.withOpacity(0.7)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
        ],
      ),
    );
  }
}
