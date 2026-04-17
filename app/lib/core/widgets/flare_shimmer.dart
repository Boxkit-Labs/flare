import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flare_app/core/theme/app_theme.dart';

class FlareShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const FlareShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.child,
  });

  factory FlareShimmer.round({required double size}) {
    return FlareShimmer(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  factory FlareShimmer.rect({required double width, required double height, double radius = 12}) {
    return FlareShimmer(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surface.withValues(alpha: 0.5),
      highlightColor: AppTheme.surface,
      period: const Duration(milliseconds: 1500),
      child: child ?? Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}
