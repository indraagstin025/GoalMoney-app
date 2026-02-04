import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget skeleton loading untuk Goal Detail Screen.
/// Menampilkan shimmer effect saat data detail goal sedang dimuat.
class GoalDetailSkeleton extends StatelessWidget {
  const GoalDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 1. Goal Photo Skeleton (Circle)
          Center(
            child: _buildShimmerItem(
              width: 120,
              height: 120,
              borderRadius: 20,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
          const SizedBox(height: 24),

          // 2. Balance Card Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildShimmerItem(
              width: double.infinity,
              height: 260,
              borderRadius: 20,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Forecast Section Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildShimmerItem(
              width: double.infinity,
              height: 140,
              borderRadius: 20,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
          const SizedBox(height: 32),

          // 4. Transaction History Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildShimmerItem(
                  width: 24,
                  height: 24,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(width: 8),
                _buildShimmerItem(
                  width: 150,
                  height: 24,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Transaction List Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTransactionCardSkeleton(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Skeleton untuk kartu transaksi.
  Widget _buildTransactionCardSkeleton({
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          _buildShimmerItem(
            width: 48,
            height: 48,
            borderRadius: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerItem(
                  width: 100,
                  height: 16,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 8),
                _buildShimmerItem(
                  width: 140,
                  height: 12,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ),
          ),

          // Amount
          _buildShimmerItem(
            width: 80,
            height: 16,
            borderRadius: 4,
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
