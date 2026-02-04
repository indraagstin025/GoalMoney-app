import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada daftar goal.
/// Memberikan umpan balik visual yang haus saat data goal sedang dimuat.
class GoalListSkeleton extends StatelessWidget {
  const GoalListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4, // Tampilkan 4 item skeleton
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Header: Image + Title/Subtitle
            Row(
              children: [
                // Image Placeholder
                _buildShimmerItem(
                  width: 64,
                  height: 64,
                  borderRadius: 16,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(width: 16),
                // Title & Subtitle Placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerItem(
                        width: 150,
                        height: 20,
                        borderRadius: 4,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      const SizedBox(height: 8),
                      _buildShimmerItem(
                        width: 100,
                        height: 14,
                        borderRadius: 4,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info Nominal Box Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerItem(
                        width: 60,
                        height: 12,
                        borderRadius: 2,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      const SizedBox(height: 6),
                      _buildShimmerItem(
                        width: 100,
                        height: 16,
                        borderRadius: 4,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildShimmerItem(
                        width: 60,
                        height: 12,
                        borderRadius: 2,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      const SizedBox(height: 6),
                      _buildShimmerItem(
                        width: 100,
                        height: 16,
                        borderRadius: 4,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress Bar Placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerItem(
                      width: 60,
                      height: 12,
                      borderRadius: 2,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    _buildShimmerItem(
                      width: 40,
                      height: 12,
                      borderRadius: 2,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildShimmerItem(
                  width: double.infinity,
                  height: 10,
                  borderRadius: 10,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ),
          ],
        ),
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
