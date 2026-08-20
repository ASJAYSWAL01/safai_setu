import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({
    super.key,
    required this.height,
    this.title,
    this.showLegend = false,
    this.showHotspots = false,
    this.showVehicle = true,
    this.showUserLocation = true,
    this.showCollectionPoints = false,
  });

  final double height;
  final String? title;
  final bool showLegend;
  final bool showHotspots;
  final bool showVehicle;
  final bool showUserLocation;
  final bool showCollectionPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? const Color(0xFF1B231E)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),
          if (title != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardColor.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          if (showUserLocation)
            Positioned(
              left: 48,
              bottom: 52,
              child: const _MapMarker(
                icon: Icons.person_pin_circle,
                color: Color(0xFF2E7D32),
                label: 'You',
              ),
            ),
          if (showVehicle)
            const Positioned(
              right: 56,
              top: 72,
              child: _MapMarker(
                icon: Icons.local_shipping_rounded,
                color: Color(0xFF1565C0),
                label: 'Truck',
              ),
            ),
          if (showCollectionPoints) ...[
            const Positioned(
              left: 120,
              top: 90,
              child: _MapDot(color: Color(0xFF4CAF50)),
            ),
            const Positioned(
              right: 90,
              bottom: 80,
              child: _MapDot(color: Color(0xFF4CAF50)),
            ),
            const Positioned(
              left: 80,
              top: 140,
              child: _MapDot(color: Color(0xFF4CAF50)),
            ),
          ],
          if (showHotspots) ...[
            const Positioned(
              left: 100,
              top: 60,
              child: _HotspotMarker(color: Colors.redAccent, label: 'High'),
            ),
            const Positioned(
              right: 70,
              bottom: 100,
              child: _HotspotMarker(color: Colors.orange, label: 'Med'),
            ),
            const Positioned(
              left: 60,
              bottom: 70,
              child: _HotspotMarker(color: Color(0xFF4CAF50), label: 'Low'),
            ),
          ],
          if (showLegend)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Map preview — demo data',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.08)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.15)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.85, size.height * 0.7),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardColor, width: 2),
      ),
    );
  }
}

class _HotspotMarker extends StatelessWidget {
  const _HotspotMarker({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.whatshot, size: 14, color: color),
        ),
        Text(
          label,
          style:
              TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
