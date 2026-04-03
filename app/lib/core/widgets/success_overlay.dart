import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ghost_app/core/theme/app_theme.dart';

class SuccessOverlay extends StatefulWidget {
  final String message;
  final String subMessage;

  const SuccessOverlay({
    super.key,
    required this.message,
    this.subMessage = 'Agent has been deployed.',
  });

  static void show(BuildContext context, {String message = 'Launched!', String subMessage = 'Your Ghost agent is now hunting.'}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => SuccessOverlay(message: message, subMessage: subMessage),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2500), () {
      entry.remove();
    });
  }

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final List<_ConfettiParticle> _particles = List.generate(30, (i) => _ConfettiParticle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 80),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.8),
        child: Stack(
          children: [
            // Confetti particles
            ..._particles.map((p) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final y = p.startY + (p.speed * progress * 800) - (0.5 * 9.8 * math.pow(progress * 2, 2) * -100);
                final x = p.startX + math.sin(progress * 10 + p.randomPhase) * 50;
                return Positioned(
                  left: x,
                  top: y,
                  child: Transform.rotate(
                    angle: progress * p.rotationSpeed,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: p.isCircle ? BoxShape.circle : BoxShape.rectangle,
                      ),
                    ),
                  ),
                );
              },
            )),
            
            // Central Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.subMessage,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  late double startX;
  late double startY;
  late double speed;
  late double size;
  late Color color;
  late bool isCircle;
  late double rotationSpeed;
  late double randomPhase;

  _ConfettiParticle() {
    final random = math.Random();
    // Start roughly in the middle, then explode outward
    startX = 200.0 + random.nextDouble() * 100 - 50; 
    startY = 400.0 + random.nextDouble() * 100 - 50;
    speed = random.nextDouble() * 2 + 1;
    size = random.nextDouble() * 8 + 4;
    color = [
      AppTheme.primary,
      AppTheme.secondary,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.yellow,
    ][random.nextInt(6)];
    isCircle = random.nextBool();
    rotationSpeed = random.nextDouble() * 10;
    randomPhase = random.nextDouble() * 2 * math.pi;
    
    // Better start position based on typical screen size (rough estimation)
    // In a real app we might use MediaQuery but here we can just center it relatively
    startX = 180; // Placeholder, will fix in build if possible or just use a wide range
  }
}
