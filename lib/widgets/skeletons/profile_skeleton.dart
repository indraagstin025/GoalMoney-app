import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Profil.
/// Memberikan umpan balik visual yang halus saat data user dan pengaturan sedang dimuat.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Profile Photo Area Skeleton
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _buildShimmerItem(
                width: 120,
                height: 120,
                borderRadius: 60,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              _buildShimmerItem(
                width: 32,
                height: 32,
                borderRadius: 16,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Info Card Skeleton
          _buildShimmerItem(
            width: double.infinity,
            height: 160,
            borderRadius: 16,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 24),

          // Main Action Button Skeleton
          _buildShimmerItem(
            width: double.infinity,
            height: 50,
            borderRadius: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 32),

          // Settings Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: _buildShimmerItem(
              width: 120,
              height: 20,
              borderRadius: 4,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
          const SizedBox(height: 12),

          // Settings Options Card Skeleton
          _buildShimmerItem(
            width: double.infinity,
            height: 240,
            borderRadius: 16,
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
