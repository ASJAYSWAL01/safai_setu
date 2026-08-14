import 'package:flutter/material.dart';

import '../../data/mock_data_repository.dart';
import '../../models/complaint.dart';
import '../../theme/app_theme.dart';
import '../../widgets/complaint_card.dart';
import 'complaint_details_page.dart';

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final complaints = MockDataRepository.instance.complaints;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: const Text(
          'My Complaints',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: complaints.isEmpty
            ? const Center(
                child: Text(
                  'No complaints yet.\nReport waste to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: complaints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return ComplaintCard(
                    complaint: complaint,
                    onTap: () => _openDetails(context, complaint),
                  );
                },
              ),
      ),
    );
  }

  void _openDetails(BuildContext context, Complaint complaint) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ComplaintDetailsPage(complaintId: complaint.id),
      ),
    );
  }
}
