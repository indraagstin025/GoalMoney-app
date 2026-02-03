import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Login dan Register.
class AuthSkeleton extends StatelessWidget {
  final bool isRegister;

  const AuthSkeleton({super.key, this.isRegister = false});

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
          const SizedBox(height: 20),
          // Welcome Text Shimmer
          _buildShimmerItem(
            width: 200,
            height: 32,
            borderRadius: 4,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 12),
          _buildShimmerItem(
            width: 250,
            height: 16,
            borderRadius: 4,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 48),

          // Form Fields Shimmer
          ...List.generate(isRegister ? 4 : 2, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerItem(
                  width: 80,
                  height: 14,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 12),
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

          const SizedBox(height: 12),
          // Main Button Shimmer
          _buildShimmerItem(
            width: double.infinity,
            height: 56,
            borderRadius: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 32),

          // Footnote Shimmer
          Center(
            child: _buildShimmerItem(
              width: 180,
              height: 14,
              borderRadius: 4,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
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
