import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Badge.
/// Memberikan efek loading pada kartu statistik dan grid badge.
class BadgeSkeleton extends StatelessWidget {
  const BadgeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Stats Card Skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildShimmerItem(
              width: double.infinity,
              height: 160,
              borderRadius: 16,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),

          // Badge Grid Skeleton
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6, // Show 6 skeleton items
            itemBuilder: (context, index) {
              return _buildShimmerItem(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 16,
                baseColor: baseColor,
                highlightColor: highlightColor,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem({
    required double width,
    required double height,
    required double borderRadius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
