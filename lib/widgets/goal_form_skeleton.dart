import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada form Goal (Add/Edit).
/// Memberikan umpan balik visual yang halus saat halaman form sedang diinisialisasi.
class GoalFormSkeleton extends StatelessWidget {
  const GoalFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Title Skeleton
          _buildShimmerItem(
            width: 200,
            height: 32,
            borderRadius: 8,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 12),
          // Subtitle Skeleton
          _buildShimmerItem(
            width: 250,
            height: 16,
            borderRadius: 4,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 40),

          // Photo Picker Circle Placeholder
          Center(
            child: _buildShimmerItem(
              width: 160,
              height: 160,
              borderRadius: 20,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
          const SizedBox(height: 48),

          // Form Fields Skeletons
          ...List.generate(5, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                _buildShimmerItem(
                  width: 80,
                  height: 14,
                  borderRadius: 2,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 10),
                // Input Field Box
                _buildShimmerItem(
                  width: double.infinity,
                  height: 56,
                  borderRadius: 12,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 24),
              ],
            );
          }),

          const SizedBox(height: 16),
          // Submit Button Placeholder
          _buildShimmerItem(
            width: double.infinity,
            height: 56,
            borderRadius: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
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
