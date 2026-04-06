import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flare_app/core/utils/error_formatter.dart';

class TopSnackbar {
  static void showError(BuildContext context, dynamic error) {
    _showOverlay(context, ErrorFormatter.format(error), isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    _showOverlay(context, message, isError: false);
  }

  static void _showOverlay(BuildContext context, String message, {required bool isError}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    bool isRemoved = false;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _SnackbarWidget(
              message: message,
              isError: isError,
              onDismissed: () {
                if (!isRemoved) {
                  isRemoved = true;
                  overlayEntry.remove();
                }
              },
            ),
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayState.insert(overlayEntry);
    });
  }
}

class _SnackbarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  const _SnackbarWidget({
    required this.message,
    required this.isError,
    required this.onDismissed,
  });

  @override
  _SnackbarWidgetState createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: () async {
              await _controller.reverse();
              widget.onDismissed();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          widget.isError ? Icons.warning_amber_rounded : Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: -0.2,
                            height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

