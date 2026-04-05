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
    Key? key,
    required this.message,
    required this.isError,
    required this.onDismissed,
  }) : super(key: key);

  @override
  _SnackbarWidgetState createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onTap: () async {
            await _controller.reverse();
            widget.onDismissed();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
