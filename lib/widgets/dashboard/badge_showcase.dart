import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/badge_provider.dart';
import '../../screens/badges/badge_screen.dart';
import '../../models/badge.dart' as model;

/// Widget showcase badge untuk dashboard.
/// Menampilkan maksimal 5 badge terbaru yang dimiliki user dalam bentuk horizontal list.
class BadgeShowcase extends StatelessWidget {
  const BadgeShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final badgeProvider = Provider.of<BadgeProvider>(context);
    final earnedBadges = badgeProvider.earnedBadges;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Tampilkan maksimal 5 badge terbaru
    final recentBadges = earnedBadges.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, earnedBadges.isNotEmpty),
        const SizedBox(height: 12),
        if (badgeProvider.isLoading)
          _buildLoadingState()
        else if (recentBadges.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          _buildBadgeList(context, recentBadges, isDarkMode),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool hasEarnedBadges) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Badge Saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        if (hasEarnedBadges)
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgeScreen()),
            ),
            child: Row(
              children: [
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.green.shade600,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Mulai menabung untuk mendapatkan badge!',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeList(
    BuildContext context,
    List<model.Badge> recentBadges,
    bool isDarkMode,
  ) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentBadges.length,
        // Optimisasi performa untuk low-end devices
        cacheExtent: 200,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final badge = recentBadges[index];
          return RepaintBoundary(
            child: _buildBadgeCard(context, badge, index, recentBadges.length, isDarkMode),
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    model.Badge badge,
    int index,
    int totalCount,
    bool isDarkMode,
  ) {
    final colors = _getBadgeColors(badge.code, isDarkMode);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BadgeScreen()),
      ),
      child: Container(
        width: 110,
        margin: EdgeInsets.only(right: index < totalCount - 1 ? 12 : 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          // BoxShadow dikurangi untuk performa
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            if (badge.earnedAt != null)
              Text(
                DateFormat('dd MMM yy').format(DateTime.parse(badge.earnedAt!)),
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  _BadgeColors _getBadgeColors(String code, bool isDarkMode) {
    if (code.toLowerCase().contains('platinum')) {
      return _BadgeColors(
        gradientColors: isDarkMode
            ? [Colors.cyan.shade900, Colors.cyan.shade800]
            : [Colors.cyan.shade50, Colors.cyan.shade100],
        textColor: isDarkMode ? Colors.cyan.shade100 : Colors.cyan.shade900,
      );
    } else if (code.toLowerCase().contains('gold')) {
      return _BadgeColors(
        gradientColors: isDarkMode
            ? [Colors.amber.shade900, Colors.amber.shade800]
            : [Colors.amber.shade50, Colors.amber.shade100],
        textColor: isDarkMode ? Colors.amber.shade100 : Colors.amber.shade900,
      );
    } else if (code.toLowerCase().contains('silver')) {
      return _BadgeColors(
        gradientColors: isDarkMode
            ? [Colors.grey.shade800, Colors.grey.shade700]
            : [Colors.grey.shade100, Colors.grey.shade200],
        textColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
      );
    } else {
      return _BadgeColors(
        gradientColors: isDarkMode
            ? [Colors.brown.shade800, Colors.brown.shade700]
            : [Colors.brown.shade50, Colors.brown.shade100],
        textColor: isDarkMode ? Colors.brown.shade200 : Colors.brown.shade800,
      );
    }
  }
}

/// Helper class untuk menyimpan warna badge.
class _BadgeColors {
  final List<Color> gradientColors;
  final Color textColor;

  _BadgeColors({required this.gradientColors, required this.textColor});
}
