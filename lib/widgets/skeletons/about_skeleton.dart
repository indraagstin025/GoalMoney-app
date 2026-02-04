import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Tentang Aplikasi.
/// Mensimulasikan tata letak informasi statis untuk memberikan transisi visual yang halus.
class AboutSkeleton extends StatelessWidget {
  const AboutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Logo Placeholder
          Center(
            child: Column(
              children: [
                _buildShimmerItem(
                  width: 100,
                  height: 100,
                  borderRadius: 24,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 16),
                _buildShimmerItem(
                  width: 150,
                  height: 28,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 8),
                _buildShimmerItem(
                  width: 200,
                  height: 14,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Section 1: Description
          _buildRowPlaceholder(baseColor, highlightColor),
          const SizedBox(height: 12),
          _buildTextParagraph(3, baseColor, highlightColor),
          const SizedBox(height: 24),

          // Section 2: Features List
          _buildRowPlaceholder(baseColor, highlightColor),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildShimmerItem(
                width: double.infinity,
                height: 80,
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

  Widget _buildRowPlaceholder(Color baseColor, Color highlightColor) {
    return Row(
      children: [
        _buildShimmerItem(
          width: 36,
          height: 36,
          borderRadius: 10,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(width: 12),
        _buildShimmerItem(
          width: 120,
          height: 20,
          borderRadius: 4,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
      ],
    );
  }

  Widget _buildTextParagraph(int lines, Color baseColor, Color highlightColor) {
    return Column(
      children: List.generate(lines, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildShimmerItem(
            width: double.infinity,
            height: 14,
            borderRadius: 2,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        );
      }),
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
