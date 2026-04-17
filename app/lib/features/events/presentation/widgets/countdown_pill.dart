import 'package:flutter/material.dart';

class CountdownPill extends StatefulWidget {
  final int daysUntil;

  const CountdownPill({super.key, required this.daysUntil});

  @override
  State<CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<CountdownPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (widget.daysUntil == 0) return const Color(0xFFF43F5E); // Urgent Red
    if (widget.daysUntil <= 3) return const Color(0xFFF59E0B); // Warning Amber
    if (widget.daysUntil <= 7) return const Color(0xFF10B981); // Emerald Green
    return const Color(0xFF6366F1); // Info Blue
  }

  String _getText() {
    if (widget.daysUntil == 0) return 'TODAY';
    if (widget.daysUntil == 1) return 'TOMORROW';
    return '${widget.daysUntil} DAYS LEFT';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final text = _getText();
    final isUrgent = widget.daysUntil == 0;

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (isUrgent) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: pill,
      );
    }

    return pill;
  }
}
