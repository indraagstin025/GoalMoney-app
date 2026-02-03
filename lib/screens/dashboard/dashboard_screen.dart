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
import '../reports/report_screen.dart';
import '../badges/badge_screen.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/badge_celebration_dialog.dart';
import '../analytics/analytics_screen.dart';
import '../../widgets/swipeable_summary_cards.dart';
import '../../widgets/dashboard_skeleton.dart';

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
    WidgetsBinding.instance.addObserver(
      this,
    ); // Menambahkan observer untuk lifecycle aplikasi (resume, pause, dll).

    // Mengambil data awal saat frame pertama dirender.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

      // Fetch semua data secara paralel: ringkasan dashboard, list goal, profil user, dan badge.
      Future.wait([
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
    });

    _loadProfilePhoto();
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
  /// Jika aplikasi kembali ke foreground (resumed), muat ulang foto profil.
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
          // Fitur Pull-to-Refresh untuk memuat ulang data dashboard.
          onRefresh: () async {
            await goalProvider.fetchDashboardSummary();
            await goalProvider.fetchGoals();
            await Provider.of<BadgeProvider>(
              context,
              listen: false,
            ).fetchBadges();
          },
          child: Column(
            children: [
              // Header Kustom
              _buildCustomHeader(user, context),

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
                            _buildBadgeShowcase(context),

                            const SizedBox(height: 32),

                            // Judul Menu
                            Text(
                              'Menu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Grid Menu Pintasan
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
                                  icon: Icons.emoji_events_rounded,
                                  label: 'Badges',
                                  color: Colors.amber,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BadgeScreen(),
                                    ),
                                  ),
                                ),
                                _buildShortcutItem(
                                  context,
                                  icon: Icons.assessment_rounded,
                                  label: 'Laporan',
                                  color: Colors.green,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReportScreen(),
                                    ),
                                  ),
                                ),
                                _buildShortcutItem(
                                  context,
                                  icon: Icons.analytics_rounded,
                                  label: 'Analytics',
                                  color: Colors.indigo,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AnalyticsScreen(),
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

  /// Membangun header kustom dengan nama user, foto profil, dan tombol notifikasi.
  Widget _buildCustomHeader(dynamic user, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sapaan User
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
          // Aksi Kanan (Theme, Notif, Profile)
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
                // Foto Profil
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

  /// Membangun kartu ringkasan menggunakan widget SwipeableSummaryCards.
  Widget _buildSummaryCard(
    Map<String, dynamic> summary,
    NumberFormat currency,
    dynamic user,
  ) {
    final totalSaved = (summary['total_saved'] is num)
        ? (summary['total_saved'] as num).toDouble()
        : 0.0;

    // Ambil total tunai dan digital
    final totalCash = (summary['total_cash'] is num)
        ? (summary['total_cash'] as num).toDouble()
        : 0.0;
    final totalDigital = (summary['total_digital'] is num)
        ? (summary['total_digital'] as num).toDouble()
        : 0.0;
    final cashGoalsCount = (summary['cash_goals_count'] is num)
        ? (summary['cash_goals_count'] as num).toInt()
        : 0;
    final digitalGoalsCount = (summary['digital_goals_count'] is num)
        ? (summary['digital_goals_count'] as num).toInt()
        : 0;

    // Parsing saldo tersedia dengan aman
    double availableBalance = 0.0;
    var val = summary['available_balance'] ?? summary['balance'];
    if (val is num) {
      availableBalance = val.toDouble();
    } else if (val is String) {
      availableBalance = double.tryParse(val) ?? 0.0;
    }

    // Fallback ke user provider jika summary 0 tapi user punya saldo (inkonsistensi data sementara)
    if (availableBalance == 0 && user != null && user.availableBalance > 0) {
      availableBalance = user.availableBalance;
    }

    final overallProgress = (summary['overall_progress'] is num)
        ? (summary['overall_progress'] as num).toDouble()
        : 0.0;

    // Menggunakan SwipeableSummaryCards yang mendukung geser kartu
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

  /// Membangun bagian showcase badge yang menampilkan badge yang sudah didapatkan user.
  Widget _buildBadgeShowcase(BuildContext context) {
    final badgeProvider = Provider.of<BadgeProvider>(context);
    final earnedBadges = badgeProvider.earnedBadges;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Tampilkan maksimal 5 badge terbaru
    final recentBadges = earnedBadges.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (earnedBadges.isNotEmpty)
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
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.green.shade600,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (badgeProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recentBadges.isEmpty)
          // Tampilan kosong jika belum ada badge
          Container(
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
                    color: isDarkMode
                        ? Colors.grey.shade500
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mulai menabung untuk mendapatkan badge!',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          // List horizontal badge yang dimiliki
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentBadges.length,
              itemBuilder: (context, index) {
                final badge = recentBadges[index];

                // Tentukan warna gradient berdasarkan kode badge
                List<Color> gradientColors;
                Color textColor;

                if (badge.code.toLowerCase().contains('platinum')) {
                  gradientColors = isDarkMode
                      ? [Colors.cyan.shade900, Colors.cyan.shade800]
                      : [Colors.cyan.shade50, Colors.cyan.shade100];
                  textColor = isDarkMode
                      ? Colors.cyan.shade100
                      : Colors.cyan.shade900;
                } else if (badge.code.toLowerCase().contains('gold')) {
                  gradientColors = isDarkMode
                      ? [Colors.amber.shade900, Colors.amber.shade800]
                      : [Colors.amber.shade50, Colors.amber.shade100];
                  textColor = isDarkMode
                      ? Colors.amber.shade100
                      : Colors.amber.shade900;
                } else if (badge.code.toLowerCase().contains('silver')) {
                  gradientColors = isDarkMode
                      ? [Colors.grey.shade800, Colors.grey.shade700]
                      : [Colors.grey.shade100, Colors.grey.shade200];
                  textColor = isDarkMode
                      ? Colors.grey.shade300
                      : Colors.grey.shade800;
                } else {
                  gradientColors = isDarkMode
                      ? [Colors.brown.shade800, Colors.brown.shade700]
                      : [Colors.brown.shade50, Colors.brown.shade100];
                  textColor = isDarkMode
                      ? Colors.brown.shade200
                      : Colors.brown.shade800;
                }

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BadgeScreen()),
                  ),
                  child: Container(
                    width: 110,
                    margin: EdgeInsets.only(
                      right: index < recentBadges.length - 1 ? 12 : 0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (badge.earnedAt != null)
                          Text(
                            DateFormat(
                              'dd MMM yy',
                            ).format(DateTime.parse(badge.earnedAt!)),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Helper widget untuk membuat item shortcut menu.
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
