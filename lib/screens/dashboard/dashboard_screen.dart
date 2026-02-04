import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../core/photo_storage_service.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/dialogs/badge_celebration_dialog.dart';
import '../../widgets/cards/swipeable_summary_cards.dart';
import '../../widgets/skeletons/dashboard_skeleton.dart';
import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/dashboard/badge_showcase.dart';
import '../../widgets/dashboard/shortcut_menu.dart';

/// Layar Dashboard Utama.
/// Menampilkan ringkasan keuangan, daftar badge terbaru, dan menu pintasan ke fitur utama.
/// Menggunakan [WidgetsBindingObserver] untuk memantau siklus hidup aplikasi (lifecycle) dan memperbarui data saat aplikasi resumed.
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

    // Mengambil data awal saat frame pertama dirender.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });

    _loadProfilePhoto();
  }

  /// Fetch semua data awal secara paralel.
  Future<void> _fetchInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

    await Future.wait([
      goalProvider.fetchDashboardSummary(),
      goalProvider.fetchGoals(),
      authProvider.fetchProfile(),
      badgeProvider.fetchBadges().then((_) {
        // Jika ada badge baru yang didapat, tampilkan dialog perayaan.
        if (badgeProvider.newlyEarnedBadges.isNotEmpty && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => BadgeCelebrationDialog(
              newBadges: badgeProvider.newlyEarnedBadges,
            ),
          );
        }
      }),
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Memuat path foto profil dari penyimpanan lokal.
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

  /// Memantau perubahan lifecycle aplikasi.
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

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              // Header Kustom
              DashboardHeader(
                user: user,
                profilePhotoPath: _profilePhotoPath,
              ),

              Expanded(
                child: goalProvider.isLoading && summary == null
                    ? const DashboardSkeleton()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kartu Ringkasan (Saldo, Progres, dll)
                            if (summary != null)
                              _buildSummaryCard(summary, currency, user),

                            const SizedBox(height: 24),

                            // Bagian Showcase Badge
                            const BadgeShowcase(),

                            const SizedBox(height: 24),

                            // Label Menu Pintasan
                            Text(
                              'Pintasan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Menu Pintasan
                            const ShortcutMenu(),
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

  /// Handler untuk pull-to-refresh.
  Future<void> _onRefresh() async {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

    await Future.wait([
      goalProvider.fetchDashboardSummary(),
      goalProvider.fetchGoals(),
      badgeProvider.fetchBadges(),
    ]);
  }

  /// Membangun kartu ringkasan menggunakan widget SwipeableSummaryCards.
  Widget _buildSummaryCard(
    Map<String, dynamic> summary,
    NumberFormat currency,
    dynamic user,
  ) {
    final totalSaved = (summary['total_saved'] ?? 0).toDouble();
    final totalCash = (summary['total_cash'] ?? 0).toDouble();
    final totalDigital = (summary['total_digital'] ?? 0).toDouble();
    final cashGoalsCount = summary['cash_goals_count'] ?? 0;
    final digitalGoalsCount = summary['digital_goals_count'] ?? 0;
    final availableBalance = (summary['total_balance'] ?? 0).toDouble();
    final totalTarget = (summary['total_target'] ?? 0).toDouble();
    final overallProgress = totalTarget > 0 
        ? (totalSaved / totalTarget * 100).clamp(0.0, 100.0) 
        : 0.0;

    return SwipeableSummaryCards(
      totalSaved: totalSaved,
      totalCash: totalCash,
      totalDigital: totalDigital,
      cashGoalsCount: cashGoalsCount,
      digitalGoalsCount: digitalGoalsCount,
      availableBalance: availableBalance,
      overallProgress: overallProgress,
      currencyFormat: currency,
    );
  }
}
