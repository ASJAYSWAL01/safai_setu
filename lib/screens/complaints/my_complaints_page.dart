import 'package:flutter/material.dart';

import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/complaint_card.dart';
import 'complaint_details_page.dart';

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = ComplaintService.instance.fetchMyComplaints();
  }

  Future<void> _refresh() async {
    setState(() {
      _complaintsFuture = ComplaintService.instance.fetchMyComplaints();
    });
    await _complaintsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'My Complaints',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Complaint>>(
          future: _complaintsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load complaints.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final complaints = snapshot.data ?? [];

            if (complaints.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primaryGreen,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Text(
                          'No complaints yet.\nReport waste to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryGreen,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: complaints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return ComplaintCard(
                    complaint: complaint,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ComplaintDetailsPage(
                            complaintId: complaint.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
