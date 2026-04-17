import 'package:flutter/material.dart';

class PlatformBadge extends StatelessWidget {
  final String platform;

  const PlatformBadge({super.key, required this.platform});

  Color _getPlatformColor() {
    switch (platform.toLowerCase()) {
      case 'ticketmaster':
        return const Color(0xFF026CDF);
      case 'eventbrite':
        return const Color(0xFFD21111);
      case 'skiddle':
        return const Color(0xFFFED103);
      case 'dice':
        return const Color(0xFF00FF00);
      case 'seatgeek':
        return const Color(0xFF162444);
      default:
        return const Color(0xFF6366F1); // Default primary
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPlatformColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        platform.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
