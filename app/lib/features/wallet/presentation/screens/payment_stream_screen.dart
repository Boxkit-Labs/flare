import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_state.dart';

class PaymentStreamScreen extends StatefulWidget {
  const PaymentStreamScreen({super.key});

  @override
  State<PaymentStreamScreen> createState() => _PaymentStreamScreenState();
}

class _PaymentStreamScreenState extends State<PaymentStreamScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<StreamParticle> _particles = [];
  final Random _random = Random();
  Timer? _spawnTimer;
  int _txCount = 0;
  double _totalStreamed = 0.0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _startSpawning();
  }

  void _startSpawning() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _particles.add(StreamParticle(
            id: _txCount++,
            x: 0.1 + _random.nextDouble() * 0.8,
            y: 0.0,
            speed: 0.004 + _random.nextDouble() * 0.004,
            amount: 0.001 + _random.nextDouble() * 0.008,
            color: _random.nextBool() ? Colors.purpleAccent : AppTheme.primary,
          ));
          _totalStreamed += 0.008;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        return BlocBuilder<WatchersBloc, WatchersState>(
          builder: (context, watchersState) {
            int activeAgents = 0;
            int nextCheckSeconds = 42;

            if (watchersState is WatchersLoaded) {
              final active = watchersState.watchers.where((w) => w.status == 'active').toList();
              activeAgents = active.length;
              if (active.isNotEmpty) {
                final now = DateTime.now();
                DateTime? nearest;
                for (var w in active) {
                  if (w.nextCheckAt != null) {
                    try {
                      final parsed = DateTime.parse(w.nextCheckAt!).toLocal();
                      if (nearest == null || parsed.isBefore(nearest)) {
                        nearest = parsed;
                      }
                    } catch (_) {}
                  }
                }
                if (nearest != null) {
                  nextCheckSeconds = nearest.difference(now).inSeconds.clamp(0, 3600);
                }
              }
            }

            if (!_initialized && walletState is WalletLoaded) {
              _totalStreamed = walletState.stats?.totalSpentAllTime ?? 0.0;
              _txCount = walletState.stats?.totalChecksToday ?? 0;
              _initialized = true;
            }

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
        children: [
          // Background Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                _updateParticles();
                return CustomPaint(
                  painter: StreamPainter(particles: _particles),
                );
              },
            ),
          ),

          // Header
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE AGENT STREAM',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'MPP OFF-CHAIN ACTIVE',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),

          // Main Stats
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL VALUE STREAMED',
                  style: TextStyle(color: Colors.white30, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.0),
                ),
                const SizedBox(height: 16),
                Text(
                  '\$${_totalStreamed.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3.0,
                  ),
                ),
                const Text(
                  'USDC',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),

          // Footer Info
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFooterStat('ACTIVE AGENTS', '$activeAgents'),
                  _buildFooterStat('TX CONFIRMED', '$_txCount'),
                  _buildFooterStat('NEXT BATCH', '${nextCheckSeconds}s'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
      },
    );
  }

  Widget _buildFooterStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _updateParticles() {
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].y += _particles[i].speed;
      if (_particles[i].y > 1.2) {
        _particles.removeAt(i);
      }
    }
  }
}

class StreamParticle {
  final int id;
  final double x;
  double y;
  final double speed;
  final double amount;
  final Color color;

  StreamParticle({
    required this.id,
    required this.x,
    required this.y,
    required this.speed,
    required this.amount,
    required this.color,
  });
}

class StreamPainter extends CustomPainter {
  final List<StreamParticle> particles;

  StreamPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var p in particles) {
      final pos = Offset(p.x * size.width, p.y * size.height);
      
      // Draw continuous stream tail
      final tailPaint = Paint()
        ..shader = LinearGradient(
          colors: [p.color.withValues(alpha: 0.0), p.color.withValues(alpha: 0.4), p.color.withValues(alpha: 0.8)],
          stops: const [0.0, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(pos.dx, 0, 4, pos.dy))
        ..strokeWidth = 3.0;
      
      canvas.drawLine(Offset(pos.dx, 0), pos, tailPaint);

      // Draw shiny head core
      paint.color = Colors.white;
      canvas.drawCircle(pos, 3, paint);
      
      // Draw strong Glow
      paint.color = p.color.withValues(alpha: 0.6);
      canvas.drawCircle(pos, 10, paint);
      paint.color = p.color.withValues(alpha: 0.2);
      canvas.drawCircle(pos, 20, paint);

      // Draw Text (TX id)
      if (p.y > 0.2 && p.y < 0.8) {
         TextPainter(
           text: TextSpan(
             text: 'TX-${p.id}',
             style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
           ),
           textDirection: TextDirection.ltr,
         )..layout()..paint(canvas, Offset(pos.dx + 12, pos.dy - 4));
      }
    }

    // Draw Grid Nodes
    final nodePaint = Paint()..color = Colors.white.withValues(alpha: 0.02);
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 20; j++) {
        canvas.drawCircle(Offset(i * size.width / 9, j * size.height / 19), 1, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StreamPainter oldDelegate) => true;
}
