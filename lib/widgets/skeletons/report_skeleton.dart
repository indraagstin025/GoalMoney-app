import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Laporan (Reports).
/// Memberikan umpan balik visual yang mendalam saat data statistik sedang diolah oleh sistem.
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search Section Skeleton
          _buildShimmerItem(
            width: double.infinity,
            height: 56,
            borderRadius: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 12),
          // Filter Chips Row Skeleton
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildShimmerItem(
                    width: 90,
                    height: 38,
                    borderRadius: 20,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Header Card Skeleton (Summary Large)
          _buildShimmerItem(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 16),

          // Detailed Summary Card Skeleton
          _buildShimmerItem(
            width: double.infinity,
            height: 120,
            borderRadius: 16,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 24),

          // Section Title Skeleton (Detail Goal)
          _buildShimmerItem(
            width: 150,
            height: 20,
            borderRadius: 4,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 12),

          // Goal Detail Cards Skeletons
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildShimmerItem(
                width: double.infinity,
                height: 100,
                borderRadius: 16,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            );
          }),
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
