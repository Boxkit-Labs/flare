import 'package:flutter/material.dart';

class AvailabilityDot extends StatelessWidget {
  final bool isAvailable;
  final int? remaining;

  const AvailabilityDot({
    super.key,
    required this.isAvailable,
    this.remaining,
  });

  Color _getColor() {
    if (!isAvailable) return const Color(0xFFEF4444); // Red
    if (remaining != null && remaining! <= 10) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
