import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class ConfidenceGauge extends StatefulWidget {
  final int score;
  final String tier;
  final Map<String, double> breakdown;

  const ConfidenceGauge({
    super.key,
    required this.score,
    required this.tier,
    required this.breakdown,
  });

  @override
  State<ConfidenceGauge> createState() => _ConfidenceGaugeState();
}

class _ConfidenceGaugeState extends State<ConfidenceGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return Colors.greenAccent.shade700;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getTierLabel(int score) {
    if (score >= 90) return 'Very High Confidence';
    if (score >= 75) return 'High Confidence';
    if (score >= 50) return 'Moderate';
    return 'Low Confidence';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(widget.score);

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(180, 180),
                            painter: _GaugePainter(
                              progress: _animation.value,
                              color: color,
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.score}%',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: -2.0,
                            ),
                          ),
                          Text(
                            _getTierLabel(widget.score).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: color.withValues(alpha: 0.7),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded ? 'Hide Analysis' : 'Tap to see Breakdown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 24),
                  ...widget.breakdown.entries.map((e) => _buildBreakdownRow(e.key, e.value, color)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textSecondary),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.6)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 16.0;

    // Background track
    final paintBase = Paint()
      ..color = AppTheme.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi * 0.8,
      pi * 1.4,
      false,
      paintBase,
    );

    // Progress arc
    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi * 0.8,
      pi * 1.4 * progress,
      false,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}
