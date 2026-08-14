import 'package:flutter/material.dart';

import '../../data/mock_data_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/map_placeholder.dart';

class LocationMapPlaceholderPage extends StatelessWidget {
  const LocationMapPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tap on the map to select a location (demo)',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: const MapPlaceholder(
                    height: double.infinity,
                    title: 'Map Placeholder',
                    showLegend: true,
                    showUserLocation: true,
                    showVehicle: false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Confirm Location',
                icon: Icons.check,
                onPressed: () {
                  Navigator.of(context).pop(MockDataRepository.mockLocation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
