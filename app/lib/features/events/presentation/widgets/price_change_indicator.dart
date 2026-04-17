import 'package:flutter/material.dart';

enum PriceDirection { up, down, stable }

class PriceChangeIndicator extends StatelessWidget {
  final double change;
  final PriceDirection direction;

  const PriceChangeIndicator({
    super.key,
    required this.change,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final isDown = direction == PriceDirection.down;
    final isUp = direction == PriceDirection.up;
    final color = isDown ? const Color(0xFF10B981) : (isUp ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8));
    final icon = isDown ? Icons.arrow_downward : (isUp ? Icons.arrow_upward : Icons.remove);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('${direction.name}_$change'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
