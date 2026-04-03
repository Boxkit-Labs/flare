import 'package:flutter/material.dart';

class StatusIndicator extends StatefulWidget {
  final String status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 8.0,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  bool _hasShaken = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Shake animation for error status
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: -3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.linear),
    ));

    _updateAnimation();
  }

  void _updateAnimation() {
    _controller.stop();
    if (widget.status == 'active') {
      _controller.repeat(reverse: true);
    } else if (widget.status == 'error' && !_hasShaken) {
      _controller.forward(from: 0.0).then((_) {
        setState(() => _hasShaken = true);
      });
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (widget.status != 'error') {
        _hasShaken = false;
      }
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.yellow;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double offset = 0.0;
        double opacity = 1.0;

        if (widget.status == 'active') {
          opacity = _pulseAnimation.value;
        } else if (widget.status == 'error' && !(_hasShaken)) {
          offset = _shakeAnimation.value;
        }

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: widget.status == 'active' 
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
