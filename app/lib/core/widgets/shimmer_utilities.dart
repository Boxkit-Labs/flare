import 'package:flutter/material.dart';
export 'shimmer_placeholder.dart';
import 'package:ghost_app/core/widgets/shimmer_placeholder.dart';

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double borderRadius;
  final EdgeInsets padding;
  final double spacing;

  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (_, __) => ShimmerPlaceholder(
        width: double.infinity,
        height: itemHeight,
        borderRadius: borderRadius,
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;
  final double borderRadius;
  final EdgeInsets padding;
  final double spacing;
  final Axis scrollDirection;

  const ShimmerGrid({
    super.key,
    this.itemCount = 3,
    this.itemWidth = 180,
    this.itemHeight = 180,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.spacing = 16,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: scrollDirection,
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (_, __) => ShimmerPlaceholder(
          width: itemWidth,
          height: itemHeight,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class ShimmerHeader extends StatelessWidget {
  final double height;
  final double padding;

  const ShimmerHeader({
    super.key,
    this.height = 24,
    this.padding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerPlaceholder(width: 120, height: height),
          ShimmerPlaceholder(width: 60, height: height),
        ],
      ),
    );
  }
}
