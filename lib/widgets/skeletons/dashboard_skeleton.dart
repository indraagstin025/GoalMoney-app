import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada dashboard.
/// Memberikan umpan balik visual yang halus saat data sedang dimuat dari server.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Skeleton (Sudah ada di Dashboard original tapi kita buat statis)
          _buildHeaderSkeleton(baseColor, highlightColor, isDarkMode),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Summary Card Skeleton
                _buildShimmerItem(
                  width: double.infinity,
                  height: 180,
                  borderRadius: 24,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),

                const SizedBox(height: 32),

                // 3. Badge Showcase Title Skeleton
                _buildShimmerItem(
                  width: 120,
                  height: 24,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),

                const SizedBox(height: 16),

                // 4. Badges Horizontal List Skeleton
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildShimmerItem(
                        width: 100,
                        height: 140,
                        borderRadius: 16,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 5. Menu Title Skeleton
                _buildShimmerItem(
                  width: 80,
                  height: 24,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),

                const SizedBox(height: 16),

                // 6. Menu Grid Skeleton
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => Column(
                    children: [
                      _buildShimmerItem(
                        width: 60,
                        height: 60,
                        borderRadius: 30, // Circle
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      const SizedBox(height: 8),
                      _buildShimmerItem(
                        width: 40,
                        height: 12,
                        borderRadius: 2,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton(Color base, Color highlight, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerItem(
                width: 120,
                height: 28,
                borderRadius: 4,
                baseColor: base,
                highlightColor: highlight,
              ),
              const SizedBox(height: 8),
              _buildShimmerItem(
                width: 80,
                height: 16,
                borderRadius: 4,
                baseColor: base,
                highlightColor: highlight,
              ),
            ],
          ),
          Row(
            children: [
              _buildShimmerItem(
                width: 36,
                height: 36,
                borderRadius: 18,
                baseColor: base,
                highlightColor: highlight,
              ),
              const SizedBox(width: 12),
              _buildShimmerItem(
                width: 48,
                height: 48,
                borderRadius: 24,
                baseColor: base,
                highlightColor: highlight,
              ),
            ],
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
