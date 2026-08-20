import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches the dialer for [phone]. Handles empty/missing numbers and shows
/// a SnackBar when the call cannot be started.
Future<void> callPhoneNumber(
  BuildContext context, {
  required String phone,
}) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
  if (digits.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user has no phone number on their profile yet.'),
        ),
      );
    }
    return;
  }

  final uri = Uri(scheme: 'tel', path: digits);
  try {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the dialer on this device.'),
        ),
      );
    }
  } on Object catch (e) {
    debugPrint('callPhoneNumber error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start the call: $e')),
      );
    }
  }
}

/// Opens Google Maps turn-by-turn navigation to a GPS coordinate.
Future<void> openDirections(
  BuildContext context, {
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
  );
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ),
      );
    }
  } on Object catch (e) {
    debugPrint('openDirections error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open directions: $e')),
      );
    }
  }
}
