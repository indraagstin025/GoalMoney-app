import 'package:flutter/material.dart';
import '../../widgets/about_skeleton.dart';

/// Layar "Tentang Aplikasi" yang memberikan informasi detail mengenai GoalMoney.
/// Menampilkan deskripsi aplikasi, tujuan, fitur unggulan, tim pembuat, dan versi aplikasi.
class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Simulasi inisialisasi singkat untuk menampilkan skeleton loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(context, isDarkMode),

            // Content
            Expanded(
              child: _isInitializing
                  ? const AboutSkeleton()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo & App Name
                          _buildAppLogo(),
                          const SizedBox(height: 32),

                          // App Description
                          _buildSection(
                            title: 'Tentang GoalMoney',
                            icon: Icons.info_outline_rounded,
                            isDarkMode: isDarkMode,
                            child: Text(
                              'GoalMoney adalah aplikasi manajemen keuangan yang dirancang untuk membantu Anda mencapai tujuan finansial dengan lebih mudah dan terorganisir. '
                              'Dengan GoalMoney, Anda dapat mengelola tabungan untuk berbagai goal, baik dalam bentuk cash (celengan fisik) maupun digital (e-wallet).',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Purpose / Tujuan
                          _buildSection(
                            title: 'Tujuan Aplikasi',
                            icon: Icons.flag_outlined,
                            isDarkMode: isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBulletPoint(
                                  '🎯 Membantu pengguna mencapai tujuan finansial dengan sistematis',
                                  isDarkMode,
                                ),
                                _buildBulletPoint(
                                  '💰 Memfasilitasi pengelolaan tabungan cash & digital',
                                  isDarkMode,
                                ),
                                _buildBulletPoint(
                                  '📊 Memberikan visualisasi progress yang jelas dan motivasi',
                                  isDarkMode,
                                ),
                                _buildBulletPoint(
                                  '🏆 Meningkatkan kesadaran finansial melalui badge achievements',
                                  isDarkMode,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Features
                          _buildSection(
                            title: 'Fitur Unggulan',
                            icon: Icons.star_outline_rounded,
                            isDarkMode: isDarkMode,
                            child: Column(
                              children: [
                                _buildFeatureCard(
                                  icon: Icons.savings_rounded,
                                  title: 'Dual Goal System',
                                  description:
                                      'Kelola tabungan cash (celengan fisik) dan digital (e-wallet) dalam satu aplikasi.',
                                  color: Colors.orange,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureCard(
                                  icon: Icons.analytics_rounded,
                                  title: 'Goal Intelligence',
                                  description:
                                      'Prediksi AI untuk estimasi pencapaian goal berdasarkan pola tabungan Anda.',
                                  color: Colors.blue,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureCard(
                                  icon: Icons.account_balance_wallet_rounded,
                                  title: 'Smart Withdrawal',
                                  description:
                                      'Sistem penarikan dana digital yang aman dengan validasi multi-layer.',
                                  color: Colors.green,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureCard(
                                  icon: Icons.emoji_events_rounded,
                                  title: 'Badge System',
                                  description:
                                      'Dapatkan badge achievements saat mencapai milestone tertentu.',
                                  color: Colors.amber,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureCard(
                                  icon: Icons.assessment_rounded,
                                  title: 'Laporan & Analytics',
                                  description:
                                      'Visualisasi data tabungan dengan grafik dan statistik mendalam.',
                                  color: Colors.purple,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureCard(
                                  icon: Icons.dark_mode_rounded,
                                  title: 'Dark Mode',
                                  description:
                                      'Tampilan mode gelap untuk kenyamanan mata di malam hari.',
                                  color: Colors.indigo,
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Team
                          _buildSection(
                            title: 'Tim Pembuat',
                            icon: Icons.groups_rounded,
                            isDarkMode: isDarkMode,
                            child: Column(
                              children: [
                                _buildTeamMemberCard(
                                  name: 'Indra Agustin',
                                  npm: '714230051',
                                  role: 'Developer',
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 12),
                                _buildTeamMemberCard(
                                  name: 'Efendi Sugiantoro',
                                  npm: '714230018',
                                  role: 'Developer',
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Version & Copyright
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    'Version 1.0.0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '© 2024 GoalMoney',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Made with by Team Proyek 3 TI in Indonesia',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun header kustom dengan logo dan tombol kembali.
  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GoalMoney Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'GoalMoney',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.lightGreen,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Back Button
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Membangun bagian logo besar dan nama aplikasi di tengah layar.
  Widget _buildAppLogo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.savings_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'GoalMoney',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.lightGreen,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wujudkan Impian Finansialmu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper untuk membangun satu bagian (Section) dengan ikon dan judul.
  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// Membangun item daftar (bullet point) untuk teks deskripsi.
  Widget _buildBulletPoint(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun kartu fitur (Feature Card) yang berisi ikon, judul, dan deskripsi singkat fitur.
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun kartu profil untuk anggota tim pembuat aplikasi.
  Widget _buildTeamMemberCard({
    required String name,
    required String npm,
    required String role,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade700.withOpacity(0.1),
            Colors.green.shade500.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NPM: $npm',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
