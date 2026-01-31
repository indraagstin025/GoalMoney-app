// lib/screens/badges/badge_screen.dart
// UI untuk menampilkan koleksi badges user

import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/badge.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeProvider>().fetchBadges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Koleksi Badge'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Diperoleh', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Belum Diperoleh', icon: Icon(Icons.lock_outline)),
          ],
        ),
      ),
      body: Consumer<BadgeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Stats Card
              _buildStatsCard(provider, isDark),

              // Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Earned Badges
                    _buildBadgeGrid(provider.earnedBadges, true, isDark),
                    // Unearned Badges
                    _buildBadgeGrid(provider.unearnedBadges, false, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BadgeProvider provider, bool isDark) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '${stats.earned} / ${stats.total}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Badge Diperoleh',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.progress / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.progress.toStringAsFixed(1)}% Complete',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(List<Badge> badges, bool earned, bool isDark) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? Icons.emoji_events_outlined : Icons.lock_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              earned
                  ? 'Belum ada badge yang diperoleh'
                  : 'Semua badge sudah diperoleh! 🎉',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return _buildBadgeCard(badges[index], earned, isDark);
      },
    );
  }

  Widget _buildBadgeCard(Badge badge, bool earned, bool isDark) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, earned),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: earned
              ? Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: earned
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: earned
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: earned
                    ? Text(badge.icon, style: const TextStyle(fontSize: 36))
                    : Icon(Icons.lock, size: 32, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 12),
            // Badge Name
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: earned ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            // Earned date or requirement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    earned && badge.earnedAt != null
                        ? _formatDate(badge.earnedAt!)
                        : _getRequirementText(badge),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: earned ? 11 : 10,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: earned ? FontWeight.w500 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!earned) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _getProgressRatio(badge),
                        minHeight: 4,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(badge),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressRatio(Badge badge) {
    if (badge.requirementValue == 0) return 0.0;
    double ratio = badge.currentValue / badge.requirementValue;
    return ratio.clamp(0.0, 1.0);
  }

  Color _getProgressColor(Badge badge) {
    double ratio = _getProgressRatio(badge);
    if (ratio >= 0.75) return Colors.green;
    if (ratio >= 0.4) return Colors.orange;
    return Colors.blue;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getRequirementText(Badge badge) {
    switch (badge.requirementType) {
      case 'streak':
        return 'Nabung ${badge.requirementValue} hari berturut-turut';
      case 'goal_complete':
        return 'Selesaikan ${badge.requirementValue} goal';
      case 'total_saved':
        return 'Total tabungan Rp ${_formatNumber(badge.requirementValue)}';
      case 'deposit_count':
        return 'Deposit ${badge.requirementValue} kali';
      case 'active_goals':
        return 'Punya ${badge.requirementValue} goal aktif';
      case 'first_deposit':
        return 'Lakukan deposit pertama';
      case 'early_complete':
        return 'Selesaikan goal sebelum deadline';
      default:
        return badge.description;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(0)}jt';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}rb';
    }
    return number.toString();
  }

  void _showBadgeDetail(Badge badge, bool earned) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: earned
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: earned
                    ? Text(badge.icon, style: const TextStyle(fontSize: 50))
                    : Icon(Icons.lock, size: 50, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              badge.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: earned
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: earned
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    earned ? 'Berhasil Diperoleh!' : 'Progress Kamu',
                    style: TextStyle(
                      color: earned ? Colors.green[700] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!earned) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          badge.requirementType == 'total_saved'
                              ? 'Rp ${_formatNumber(badge.currentValue.toInt())}'
                              : '${badge.currentValue}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          badge.requirementType == 'total_saved'
                              ? 'Rp ${_formatNumber(badge.requirementValue)}'
                              : '${badge.requirementValue}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _getProgressRatio(badge),
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(badge),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_getProgressRatio(badge) * 100).toStringAsFixed(0)}% Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Diperoleh pada ${_formatDate(badge.earnedAt ?? "")}',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
