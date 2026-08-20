import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class HeadEditWorkerPage extends StatefulWidget {
  const HeadEditWorkerPage({super.key, required this.workerId});

  final String workerId;

  @override
  State<HeadEditWorkerPage> createState() => _HeadEditWorkerPageState();
}

class _HeadEditWorkerPageState extends State<HeadEditWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  bool _isSaving = false;
  AppUser? _worker;
  bool _loadingWorker = true;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    List<AppUser> workers;
    try {
      workers = await AuthService.instance.workers;
    } on Object {
      workers = [];
    }
    if (!mounted) return;
    AppUser? found;
    for (final account in workers) {
      if (account.id == widget.workerId) {
        found = account;
        break;
      }
    }
    setState(() {
      _worker = found;
      _loadingWorker = false;
      _nameController.text = found?.name ?? '';
      _phoneController.text = found?.phone ?? '';
      _vehicleController.text = found?.vehicleNumber ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final error = await AuthService.instance.updateWorker(
      id: widget.workerId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleNumber: _vehicleController.text.trim().toUpperCase(),
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error), backgroundColor: Colors.redAccent.shade200),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Worker profile updated.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingWorker) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Worker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final worker = _worker;
    if (worker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Worker')),
        body: const Center(child: Text('Worker not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Edit Worker Profile',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge, color: Color(0xFF6A1B9A)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Worker ID: ${worker.workerId} — this cannot be changed.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Worker Full Name',
                        hint: 'e.g. Mahesh Chauhan',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Worker name is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Mobile Number',
                        hint: '10-digit mobile number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().length != 10) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _vehicleController,
                        label: 'Pickup Truck Vehicle Number',
                        hint: 'e.g. GJ-18-WM-1024',
                        prefixIcon: Icons.local_shipping_outlined,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vehicle number is required'
                                : null,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        label: 'Save Changes',
                        icon: Icons.save_outlined,
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
