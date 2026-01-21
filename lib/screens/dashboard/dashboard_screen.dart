import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../core/photo_storage_service.dart';
import '../../providers/theme_provider.dart';
import '../goals/goal_list_screen.dart';
import '../goals/add_goal_screen.dart';
import '../profile/profile_screen.dart';
import '../withdrawals/withdrawal_screen.dart';
import '../notifications/notification_screen.dart';
import '../../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      
      // Fetch both dashboard summary and user profile to get latest balance
      await Future.wait([
        goalProvider.fetchDashboardSummary(),
        goalProvider.fetchGoals(),
        authProvider.fetchProfile(),
      ]);
    });

    _loadProfilePhoto();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final photoPath = await PhotoStorageService.getProfilePhotoPath();
      if (mounted) {
        setState(() => _profilePhotoPath = photoPath);
      }
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfilePhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final goalProvider = Provider.of<GoalProvider>(context);
    final summary = goalProvider.summary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await goalProvider.fetchDashboardSummary();
            await goalProvider.fetchGoals();
          },
          child: Column(
            children: [
              _buildCustomHeader(user, context),

              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (summary != null)
                        _buildSummaryCard(summary, currency, user),

                      const SizedBox(height: 32),

                      Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildShortcutItem(
                            context,
                            icon: Icons.list_alt_rounded,
                            label: 'My Goals',
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GoalListScreen(),
                              ),
                            ),
                          ),
                          _buildShortcutItem(
                            context,
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Add Goal',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddGoalScreen(),
                              ),
                            ),
                          ),
                          _buildShortcutItem(
                            context,
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Withdraw',
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WithdrawalScreen(),
                              ),
                            ),
                          ),
                          _buildShortcutItem(
                            context,
                            icon: Icons.person_rounded,
                            label: 'Profile',
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(dynamic user, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GoalMoney',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.lightGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hi, ${user?.name ?? "Saver"} 👋',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).toggleTheme();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                    color: Colors.blue.shade50,
                    image:
                        _profilePhotoPath != null &&
                            File(_profilePhotoPath!).existsSync()
                        ? DecorationImage(
                            image: FileImage(File(_profilePhotoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      _profilePhotoPath == null ||
                          !File(_profilePhotoPath!).existsSync()
                      ? Icon(Icons.person, color: Colors.blue.shade300)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    Map<String, dynamic> summary,
    NumberFormat currency,
    dynamic user,
  ) {
    final totalSaved = (summary['total_saved'] is num)
        ? (summary['total_saved'] as num).toDouble()
        : 0.0;
    
    // Safely parse available balance with robust fallback
    double availableBalance = 0.0;
    var val = summary['available_balance'] ?? summary['balance'];
    if (val is num) {
      availableBalance = val.toDouble();
    } else if (val is String) {
      availableBalance = double.tryParse(val) ?? 0.0;
    }

    // Fallback to user provider if summary is 0 but user has balance
    if (availableBalance == 0 && user != null && user.availableBalance > 0) {
      availableBalance = user.availableBalance;
    }

    return SummaryCard(
      totalSaved: totalSaved,
      availableBalance: availableBalance, // Pass to widget
      overallProgress: (summary['overall_progress'] is num)
          ? (summary['overall_progress'] as num).toDouble()
          : 0.0,
      currencyFormat: currency,
    );
  }

  Widget _buildShortcutItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
