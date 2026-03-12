import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Skeleton Loader Widget
/// 
/// Displays a shimmering placeholder while content is loading
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 2,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
