import 'package:flutter/material.dart';
import '../../screens/goals/goal_list_screen.dart';
import '../../screens/withdrawals/withdrawal_screen.dart';
import '../../screens/badges/badge_screen.dart';
import '../../screens/reports/report_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/profile/profile_screen.dart';

/// Widget menu shortcut untuk dashboard.
/// Menampilkan grid menu pintasan untuk navigasi cepat ke fitur utama aplikasi.
class ShortcutMenu extends StatelessWidget {
  const ShortcutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ShortcutItem(
          icon: Icons.savings_rounded,
          label: 'Goals',
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalListScreen()),
          ),
        ),
        _ShortcutItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Withdraw',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
          ),
        ),
        _ShortcutItem(
          icon: Icons.emoji_events_rounded,
          label: 'Badges',
          color: Colors.amber,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BadgeScreen()),
          ),
        ),
        _ShortcutItem(
          icon: Icons.assessment_rounded,
          label: 'Laporan',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          ),
        ),
        _ShortcutItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
          ),
        ),
        _ShortcutItem(
          icon: Icons.person_rounded,
          label: 'Profile',
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }
}

/// Widget item shortcut individual.
class _ShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 72) / 3,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? color.withOpacity(0.15)
              : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDarkMode ? 0.25 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
