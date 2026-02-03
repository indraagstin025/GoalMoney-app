// lib/screens/analytics/streak_calendar_screen.dart
// UI untuk menampilkan streak calendar heatmap

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../widgets/analytics_skeleton.dart';

/// Layar Kalender Streak yang menampilkan heatmap aktivitas menabung pengguna.
/// Mirip dengan GitHub contribution graph, menunjukkan intensitas aktivitas harian.
class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  /// Instance ApiClient untuk mengambil data streak dari server.
  final ApiClient _apiClient = ApiClient();

  /// Tahun yang dipilih untuk tampilan kalender.
  int _selectedYear = DateTime.now().year;

  /// Bulan opsional untuk filter (jika diperlukan detail bulanan).
  int? _selectedMonth;

  /// Data streak mentah (current streak, longest streak, calendar data).
  Map<String, dynamic>? _streakData;

  /// Status loading data.
  bool _isLoading = true;

  /// Pesan error jika fetching gagal.
  String? _error;

  /// Formatter mata uang Rupiah.
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Helper konversi nilai API ke [num] secara aman.
  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url = '/analytics/streak?year=$_selectedYear';
      if (_selectedMonth != null) {
        url += '&month=$_selectedMonth';
      }

      final response = await _apiClient.dio.get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (_mounted) {
          setState(() {
            _streakData = response.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Branded Header
            _buildCustomHeader(context, isDark),

            Expanded(
              child: _isLoading
                  ? AnalyticsSkeleton.calendar()
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : RefreshIndicator(
                      onRefresh: _loadStreakData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Streak Stats Card
                            _buildStreakStatsCard(isDark),
                            const SizedBox(height: 16),

                            // Year Selector
                            _buildYearSelector(isDark),
                            const SizedBox(height: 16),

                            // Calendar Heatmap
                            _buildCalendarHeatmap(isDark),
                            const SizedBox(height: 16),

                            // Monthly Summary
                            _buildMonthlySummary(isDark),
                            const SizedBox(height: 16),

                            // Legend
                            _buildLegend(isDark),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun header kustom layar.
  Widget _buildCustomHeader(BuildContext context, bool isDark) {
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

          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: _loadStreakData,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun kartu statistik streak (Current, Longest, Active Days).
  Widget _buildStreakStatsCard(bool isDark) {
    final streak = _streakData?['streak'] ?? {};
    final currentStreak = streak['current'] ?? 0;
    final longestStreak = streak['longest'] ?? 0;
    final isActiveToday = streak['is_active_today'] ?? false;
    final stats = _streakData?['stats'] ?? {};

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakStat(
                '🔥',
                '$currentStreak',
                'Current Streak',
                Colors.white,
              ),
              Container(height: 50, width: 1, color: Colors.white24),
              _buildStreakStat(
                '🏆',
                '$longestStreak',
                'Longest Streak',
                Colors.white,
              ),
              Container(height: 50, width: 1, color: Colors.white24),
              _buildStreakStat(
                '📅',
                '${stats['active_days'] ?? 0}',
                'Active Days',
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActiveToday
                  ? '✅ Sudah nabung hari ini!'
                  : '⏰ Belum nabung hari ini',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Item statistik streak individu.
  Widget _buildStreakStat(
    String icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  /// Selektor tahun untuk navigasi data historis.
  Widget _buildYearSelector(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() => _selectedYear--);
            _loadStreakData();
          },
        ),
        Text(
          '$_selectedYear',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedYear < DateTime.now().year
              ? () {
                  setState(() => _selectedYear++);
                  _loadStreakData();
                }
              : null,
        ),
      ],
    );
  }

  /// Membangun heatmap kalender 12 bulan.
  Widget _buildCalendarHeatmap(bool isDark) {
    final calendar = _streakData?['calendar'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Aktivitas Menabung',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Months grid
          ...List.generate(12, (monthIndex) {
            final month = monthIndex + 1;
            final lastDay = DateTime(_selectedYear, month + 1, 0);
            final daysInMonth = lastDay.day;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMonthName(month),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: List.generate(daysInMonth, (dayIndex) {
                    final day = dayIndex + 1;
                    final dateStr =
                        '$_selectedYear-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final dayData = calendar[dateStr];
                    final intensity = dayData?['intensity'] ?? 0;

                    return GestureDetector(
                      onTap: dayData != null
                          ? () => _showDayDetail(dateStr, dayData)
                          : null,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getIntensityColor(intensity, isDark),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Mendapatkan warna berdasarkan intensitas tabungan (0-4).
  Color _getIntensityColor(int intensity, bool isDark) {
    switch (intensity) {
      case 4:
        return Colors.green.shade800;
      case 3:
        return Colors.green.shade600;
      case 2:
        return Colors.green.shade400;
      case 1:
        return Colors.green.shade200;
      default:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  /// Membangun daftar ringkasan total tabungan per bulan.
  Widget _buildMonthlySummary(bool isDark) {
    final summary = _streakData?['monthly_summary'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📜 Ringkasan Bulanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...summary.map<Widget>((month) {
            final total = (month['total'] as num?)?.toDouble() ?? 0;
            if (total == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    month['month_name'] ?? '',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(_toNum(total)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Membangun legenda warna intensitas heatmap.
  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Less', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) {
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getIntensityColor(i, isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(fontSize: 11)),
      ],
    );
  }

  /// Menampilkan detail transaksi untuk hari yang dipilih melalui BottomSheet.
  void _showDayDetail(String date, Map<String, dynamic> data) {
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
            Text(
              '📅 $date',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      currencyFormatter.format(_toNum(data['amount'])),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Total Deposit'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${data['count'] ?? 0}x',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text('Transaksi'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
