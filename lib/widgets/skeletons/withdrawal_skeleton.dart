import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget untuk menampilkan skeleton loading (shimmer effect) pada halaman Penarikan.
/// Mendukung skeleton untuk form request dan skeleton untuk daftar riwayat.
class WithdrawalSkeleton extends StatelessWidget {
  final bool isHistory;

  const WithdrawalSkeleton({super.key, this.isHistory = false});

  /// Pintasan untuk menampilkan skeleton riwayat.
  static Widget history() => const WithdrawalSkeleton(isHistory: true);

  /// Pintasan untuk menampilkan skeleton form request.
  static Widget form() => const WithdrawalSkeleton(isHistory: false);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final highlightColor = isDarkMode ? Colors.grey[700] : Colors.grey[100];

    if (isHistory) {
      return _buildHistorySkeleton(baseColor!, highlightColor!);
    }
    return _buildFormSkeleton(baseColor!, highlightColor!);
  }

  /// Membangun skeleton untuk Tab Riwayat (Daftar Transaksi).
  Widget _buildHistorySkeleton(Color baseColor, Color highlightColor) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildShimmerItem(
          width: double.infinity,
          height: 100,
          borderRadius: 16,
          baseColor: baseColor,
          highlightColor: highlightColor,
        );
      },
    );
  }

  /// Membangun skeleton untuk Tab Request (Balance Card & Form).
  Widget _buildFormSkeleton(Color baseColor, Color highlightColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card Skeleton
          _buildShimmerItem(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: 32),

          // Form Field Skeletons
          ...List.generate(4, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerItem(
                  width: 120,
                  height: 14,
                  borderRadius: 2,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 8),
                _buildShimmerItem(
                  width: double.infinity,
                  height: 56,
                  borderRadius: 12,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          const SizedBox(height: 12),
          // Submit Button Skeleton
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
