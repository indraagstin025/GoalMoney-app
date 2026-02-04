import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Tambah Tabungan (Deposit).
/// Memberikan umpan balik visual yang halus saat halaman deposit sedang diinisialisasi.
class DepositFormSkeleton extends StatelessWidget {
  const DepositFormSkeleton({super.key});

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
            width: 250,
            height: 32,
            borderRadius: 8,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 12),
          // Subtitle Skeleton (Goal Name)
          _buildShimmerItem(
            width: 180,
            height: 18,
            borderRadius: 4,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 40),

          // Nominal Field Skeleton
          _buildFieldSkeleton(baseColor, highlightColor, labelWidth: 120),
          const SizedBox(height: 20),

          // Source Dropdown Skeleton
          _buildFieldSkeleton(baseColor, highlightColor, labelWidth: 100),
          const SizedBox(height: 20),

          // Notes Field Skeleton (Larger)
          _buildFieldSkeleton(
            baseColor,
            highlightColor,
            labelWidth: 110,
            fieldHeight: 120,
          ),
          const SizedBox(height: 40),

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

  Widget _buildFieldSkeleton(
    Color baseColor,
    Color highlightColor, {
    required double labelWidth,
    double fieldHeight = 56,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        _buildShimmerItem(
          width: labelWidth,
          height: 14,
          borderRadius: 2,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 10),
        // Input Field Box
        _buildShimmerItem(
          width: double.infinity,
          height: fieldHeight,
          borderRadius: 12,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
      ],
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
