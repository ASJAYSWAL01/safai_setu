import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/mock_data_repository.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/network_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/complete_profile_dialog.dart';
import '../../widgets/complaint_map_picker.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'complaint_details_page.dart';

class ReportComplaintPage extends StatefulWidget {
  const ReportComplaintPage({super.key});

  @override
  State<ReportComplaintPage> createState() => _ReportComplaintPageState();
}

class _ReportComplaintPageState extends State<ReportComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String? _photoPath;
  LatLng? _selectedPosition;
  String _locationStatus = 'Location not selected';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a waste category')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = AuthService.instance.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit.')),
      );
      return;
    }

    // The citizen must complete their profile (phone number + app login
    // password) before reporting, so the department and the assigned worker
    // can contact them about the complaint.
    if (user.isCitizen) {
      bool complete;
      try {
        complete = await ProfileService.instance.hasCompletedProfile(user.id);
      } on Object {
        complete = false;
      }
      if (!complete) {
        final saved = await showCompleteProfileDialog(
          context,
          initialPhone: user.phone,
        );
        if (saved) {
          await AuthService.instance.refreshCurrentUser();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please complete your profile (phone number) before reporting a complaint.',
              ),
            ),
          );
          return;
        }
      }
    }

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a complaint location using GPS or the map.',
          ),
        ),
      );
      return;
    }

    if (!await NetworkService.instance.hasInternetAccess()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(NetworkService.instance.offlineMessage())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final complaint = await ComplaintService.instance.submitComplaint(
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        locationText:
            'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, Long: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
        localPhotoPath: _photoPath,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Expanded(child: Text('Complaint Submitted Successfully!')),
            ],
          ),
          content: Text('Complaint ID: ${complaint.displayId}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ComplaintDetailsPage(complaintId: complaint.id),
        ),
      );
    } on AuthException catch (e) {
      _showSubmitError(e.message);
    } on StorageException catch (e) {
      _showSubmitError('Photo upload failed: ${e.message}');
    } on PostgrestException catch (e) {
      _showSubmitError('Could not save complaint: ${e.message}');
    } on SocketException {
      _showSubmitError(NetworkService.instance.offlineMessage());
    } on Object catch (e) {
      _showSubmitError('Submission failed: $e');
    }
  }

  void _showSubmitError(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _submitComplaint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Report Waste',
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
                const Text(
                  'Waste Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    hintText: 'Select waste category',
                    prefixIcon: Icon(Icons.category_outlined,
                        color: AppColors.primaryGreen),
                  ),
                  items: MockDataRepository.wasteCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) =>
                      value == null ? 'Please select a waste category' : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Complaint Description',
                  hint: 'Describe the waste problem...',
                  prefixIcon: Icons.description_outlined,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Description'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Upload Photo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _photoPath == null ? _takePhoto : null,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _photoPath != null
                            ? AppColors.primaryGreen
                            : AppColors.borderColor,
                        width: _photoPath != null ? 1.5 : 1,
                      ),
                    ),
                    child: _photoPath != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(_photoPath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _photoPath = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 36, color: AppColors.primaryGreen),
                              const SizedBox(height: 8),
                              Text(
                                'Add Waste Photo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                ComplaintMapPicker(
                  initialPosition: _selectedPosition,
                  onPositionChanged: (position) {
                    setState(() {
                      _selectedPosition = position;
                      _locationStatus = 'Location selected';
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _locationStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedPosition != null
                        ? AppColors.primaryGreen
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                CustomButton(
                  label: 'Submit Complaint',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitComplaint,
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
