import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Analitik dan Kalender Streak.
/// Memberikan umpan balik visual yang halus saat data statistik dan heatmap sedang dimuat.
class AnalyticsSkeleton extends StatelessWidget {
  final bool isCalendar;

  const AnalyticsSkeleton({super.key, this.isCalendar = false});

  /// Factory untuk skeleton dashboard analitik utama.
  static Widget dashboard() => const AnalyticsSkeleton(isCalendar: false);

  /// Factory untuk skeleton kalender streak.
  static Widget calendar() => const AnalyticsSkeleton(isCalendar: true);

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
          if (isCalendar)
            _buildCalendarSkeleton(baseColor, highlightColor)
          else
            _buildDashboardSkeleton(baseColor, highlightColor),
        ],
      ),
    );
  }

  /// Membangun skeleton untuk Dashboard Analitik Utama.
  Widget _buildDashboardSkeleton(Color baseColor, Color highlightColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Stats Card Skeleton
        _buildShimmerItem(
          width: double.infinity,
          height: 160,
          borderRadius: 16,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 24),

        // Year Selector Skeleton
        Center(
          child: _buildShimmerItem(
            width: 150,
            height: 40,
            borderRadius: 8,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ),
        const SizedBox(height: 24),

        // Section Title
        _buildShimmerItem(
          width: 200,
          height: 20,
          borderRadius: 4,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 12),

        // Large Chart Skeleton
        _buildShimmerItem(
          width: double.infinity,
          height: 200,
          borderRadius: 16,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 24),

        // Another Section Title
        _buildShimmerItem(
          width: 150,
          height: 20,
          borderRadius: 4,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 12),

        // Bar/Pie Chart Skeleton
        _buildShimmerItem(
          width: double.infinity,
          height: 180,
          borderRadius: 16,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
      ],
    );
  }

  /// Membangun skeleton untuk Kalender Streak.
  Widget _buildCalendarSkeleton(Color baseColor, Color highlightColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak Stats Card Skeleton
        _buildShimmerItem(
          width: double.infinity,
          height: 150,
          borderRadius: 16,
          baseColor: baseColor,
          highlightColor: highlightColor,
        ),
        const SizedBox(height: 24),

        // Year Selector Skeleton
        Center(
          child: _buildShimmerItem(
            width: 120,
            height: 40,
            borderRadius: 8,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ),
        const SizedBox(height: 24),

        // Calendar Heatmap Grid Skeletons (12 Months)
        ...List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerItem(
                  width: 60,
                  height: 14,
                  borderRadius: 2,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 8),
                _buildShimmerItem(
                  width: double.infinity,
                  height: 60,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ],
            ),
          );
        }),
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
