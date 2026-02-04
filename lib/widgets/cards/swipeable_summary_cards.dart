import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget kumpulan kartu ringkasan yang dapat digeser (swipeable).
/// Menampilkan ringkasan Total Tabungan, Tabungan Cash, dan Tabungan E-Wallet dalam bentuk slide.
class SwipeableSummaryCards extends StatefulWidget {
  /// Total seluruh tabungan digital & cash.
  final double totalSaved;

  /// Total tabungan dalam bentuk tunai (Cash).
  final double totalCash;

  /// Total tabungan dalam bentuk digital (E-Wallet).
  final double totalDigital;

  /// Jumlah goal dengan tipe Cash yang sedang aktif.
  final int cashGoalsCount;

  /// Jumlah goal dengan tipe Digital yang sedang aktif.
  final int digitalGoalsCount;

  /// Saldo aktif akun user.
  final double availableBalance;

  /// Persentase progres seluruh goal (0-100).
  final double overallProgress;

  /// Formatter mata uang.
  final NumberFormat currencyFormat;

  const SwipeableSummaryCards({
    super.key,
    required this.totalSaved,
    required this.totalCash,
    required this.totalDigital,
    required this.cashGoalsCount,
    required this.digitalGoalsCount,
    required this.availableBalance,
    required this.overallProgress,
    required this.currencyFormat,
  });

  @override
  State<SwipeableSummaryCards> createState() => _SwipeableSummaryCardsState();
}

class _SwipeableSummaryCardsState extends State<SwipeableSummaryCards> {
  /// Kontroler untuk mengelola perpindahan halaman kartu.
  final PageController _pageController = PageController();

  /// Indeks halaman kartu yang sedang aktif.
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView with cards - wrapped in RepaintBoundary for performance
        RepaintBoundary(
          child: SizedBox(
            height: 200,
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildTotalCard(),
                _buildCashCard(),
                _buildDigitalCard(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator
        _buildPageIndicator(),
      ],
    );
  }

  /// Membangun kartu slide pertama: Ringkasan Total.
  Widget _buildTotalCard() {
    return _SummaryCardBase(
      title: 'TOTAL TABUNGAN',
      amount: widget.totalSaved,
      icon: Icons.account_balance_wallet_rounded,
      gradient: [Colors.green.shade800, Colors.green.shade500],
      subtitle: 'Semua Goals',
      currencyFormat: widget.currencyFormat,
      showProgress: true,
      progress: widget.overallProgress,
    );
  }

  /// Membangun kartu slide kedua: Ringkasan Tabungan Tunai (Cash).
  Widget _buildCashCard() {
    return _SummaryCardBase(
      title: 'TABUNGAN CASH',
      amount: widget.totalCash,
      icon: Icons.savings_rounded,
      gradient: [Colors.orange.shade800, Colors.orange.shade500],
      subtitle: '${widget.cashGoalsCount} Goals Aktif',
      currencyFormat: widget.currencyFormat,
      showProgress: false,
    );
  }

  /// Membangun kartu slide ketiga: Ringkasan Tabungan E-Wallet (Digital).
  Widget _buildDigitalCard() {
    return _SummaryCardBase(
      title: 'TABUNGAN E-WALLET',
      amount: widget.totalDigital,
      icon: Icons.credit_card_rounded,
      gradient: [Colors.blue.shade800, Colors.blue.shade500],
      subtitle: '${widget.digitalGoalsCount} Goals Aktif',
      currencyFormat: widget.currencyFormat,
      showProgress: false,
    );
  }

  /// Membangun indikator titik-titik di bawah kartu slide.
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.green.shade700
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Komponen dasar kartu ringkasan dengan desain modern (optimized untuk low-end devices).
class _SummaryCardBase extends StatelessWidget {
  /// Judul kartu (misal: "TOTAL TABUNGAN").
  final String title;

  /// Nominal uang yang ditampilkan.
  final double amount;

  /// Ikon yang mewakili tipe tabungan.
  final IconData icon;

  /// Daftar warna gradasi background.
  final List<Color> gradient;

  /// Teks keterangan tambahan di bagian bawah.
  final String subtitle;

  /// Formatter mata uang.
  final NumberFormat currencyFormat;

  /// Apakah progres bar harus ditampilkan.
  final bool showProgress;

  /// Nilai progres dalam persentase.
  final double progress;

  const _SummaryCardBase({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
    required this.subtitle,
    required this.currencyFormat,
    this.showProgress = false,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          // Gradient background yang lebih ringan (tanpa BackdropFilter)
          gradient: LinearGradient(
            colors: [
              gradient[0],
              gradient[1],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          // BoxShadow yang lebih ringan untuk performa
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle (ringan)
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Amount
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Subtitle or Progress
                  if (showProgress)
                    _buildProgressSection()
                  else
                    _buildSubtitleChip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white.withOpacity(0.9),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
