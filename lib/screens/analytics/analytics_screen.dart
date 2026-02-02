// lib/screens/analytics/analytics_screen.dart
// Analytics Dashboard dengan grafik statistik

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import 'streak_calendar_screen.dart';

/// Layar Dashboard Analitik yang menampilkan statistik tabungan dalam bentuk grafik.
/// Menggunakan paket `fl_chart` untuk visualisasi data tren, progress, dan distribusi.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  /// Instance ApiClient untuk mengambil data analitik dari backend.
  final ApiClient _apiClient = ApiClient();

  /// Tahun yang dipilih untuk filter data statistik.
  int _selectedYear = DateTime.now().year;

  /// Data analitik mentah yang diterima dari API.
  Map<String, dynamic>? _analyticsData;

  /// Data rekomendasi strategi menabung.
  Map<String, dynamic>? _recommendationData;

  /// Status loading selama pengambilan data.
  bool _isLoading = true;

  /// Pesan error jika terjadi kegagalan pengambilan data.
  String? _error;

  /// Formatter mata uang Rupiah untuk tampilan nominal.
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Helper untuk mengonversi nilai dari API secara aman menjadi tipe [num].
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
    _loadData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        _apiClient.dio.get('/analytics/summary?year=$_selectedYear'),
        _apiClient.dio.get('/recommendations'),
      ]);

      if (responses[0].statusCode == 200 &&
          responses[0].data['success'] == true) {
        _analyticsData = responses[0].data['data'];
      }

      if (responses[1].statusCode == 200 &&
          responses[1].data['success'] == true) {
        _recommendationData = responses[1].data['data'];
      }

      if (_mounted) setState(() => _isLoading = false);
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
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Stats
                            _buildSummaryStats(isDark),
                            const SizedBox(height: 24),

                            // Year Selector
                            _buildYearSelector(),
                            const SizedBox(height: 16),

                            // Monthly Trend Line Chart
                            _buildSectionTitle('📈 Tren Tabungan Bulanan'),
                            const SizedBox(height: 8),
                            _buildLineChart(isDark),
                            const SizedBox(height: 24),

                            // Savings Goals Progress
                            _buildSectionTitle('🎯 Progress Goal'),
                            const SizedBox(height: 8),
                            _buildBarChart(isDark),
                            const SizedBox(height: 24),

                            // Goal Category Distribution (Pie Chart)
                            _buildSectionTitle('📊 Distribusi Kategori Goal'),
                            const SizedBox(height: 8),
                            _buildPieChart(isDark),
                            const SizedBox(height: 24),

                            // Top Recommendations (AI-driven simple logic)
                            _buildSectionTitle('✨ Rekomendasi Strategi'),
                            const SizedBox(height: 8),
                            _buildRecommendations(isDark),
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

  /// Membangun header kustom dengan logo dan tombol navigasi.
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
                  Icons.calendar_month,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StreakCalendarScreen(),
                  ),
                ),
                tooltip: 'Streak Calendar',
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: _loadData,
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

  /// Membangun kartu ringkasan statistik (Total tabungan, Progress, dll).
  Widget _buildSummaryStats(bool isDark) {
    final summary = _analyticsData?['summary'] ?? {};

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
              _buildStatItem(
                '💰',
                currencyFormatter.format(_toNum(summary['total_saved'])),
                'Total Tabungan',
              ),
              _buildStatItem(
                '🎯',
                '${summary['overall_progress'] ?? 0}%',
                'Overall Progress',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '✅',
                '${summary['completed_goals'] ?? 0}',
                'Goal Selesai',
              ),
              _buildStatItem(
                '🔄',
                '${summary['active_goals'] ?? 0}',
                'Goal Aktif',
              ),
              _buildStatItem(
                '📊',
                '${summary['total_deposits'] ?? 0}',
                'Total Deposit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun item statistik individu dengan ikon emoji.
  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
        ),
      ],
    );
  }

  /// Membangun kontrol pemilih tahun (Lalu/Selanjutnya).
  Widget _buildYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() => _selectedYear--);
            _loadData();
          },
        ),
        Text(
          '$_selectedYear',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedYear < DateTime.now().year
              ? () {
                  setState(() => _selectedYear++);
                  _loadData();
                }
              : null,
        ),
      ],
    );
  }

  /// Membangun teks judul untuk setiap bagian analitik.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  /// Membangun grafik garis (Line Chart) untuk tren tabungan bulanan.
  Widget _buildLineChart(bool isDark) {
    final monthlyTrend = _analyticsData?['monthly_trend'] as List? ?? [];

    if (monthlyTrend.isEmpty) {
      return _buildEmptyChart('Belum ada data transaksi', isDark);
    }

    final maxY = monthlyTrend
        .map((m) => (m['total'] as num?)?.toDouble() ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Text(
                    _formatCompact(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade400 : Colors.black87,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= monthlyTrend.length)
                    return const Text('');
                  return Text(
                    monthlyTrend[value.toInt()]['month_short'] ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade400 : Colors.black87,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(monthlyTrend.length, (i) {
                return FlSpot(
                  i.toDouble(),
                  (monthlyTrend[i]['total'] as num?)?.toDouble() ?? 0,
                );
              }),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final month = monthlyTrend[spot.x.toInt()];
                  return LineTooltipItem(
                    '${month['month_name']}\n${currencyFormatter.format(spot.y)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun grafik batang (Bar Chart) untuk perbandingan progress antar goal.
  Widget _buildBarChart(bool isDark) {
    final goalComparison = _analyticsData?['goal_comparison'] as List? ?? [];

    if (goalComparison.isEmpty) {
      return _buildEmptyChart('Belum ada goal', isDark);
    }

    return Container(
      height: 200,
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: List.generate(goalComparison.length, (i) {
            final goal = goalComparison[i];
            final progress = (goal['progress'] as num?)?.toDouble() ?? 0;
            final isCompleted = goal['is_completed'] ?? false;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: progress,
                  color: isCompleted ? Colors.green : Colors.blue,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 25 != 0) return const Text('');
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade400 : Colors.black87,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= goalComparison.length)
                    return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      goalComparison[value.toInt()]['name'] ?? '',
                      style: TextStyle(
                        fontSize: 8,
                        color: isDark ? Colors.grey.shade400 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final goal = goalComparison[group.x];
                return BarTooltipItem(
                  '${goal['full_name']}\n${rod.toY.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun grafik lingkaran (Pie Chart) berdasarkan kategori goal.
  Widget _buildPieChart(bool isDark) {
    final categories = _analyticsData?['category_distribution'] as List? ?? [];

    if (categories.isEmpty) {
      return _buildEmptyChart('Belum ada data distribusi', isDark);
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

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
      child: Row(
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                sections: List.generate(categories.length, (i) {
                  final cat = categories[i];
                  return PieChartSectionData(
                    value: (cat['count'] as num).toDouble(),
                    color: colors[i % colors.length],
                    title: '${cat['count']}',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 50,
                  );
                }),
                centerSpaceRadius: 25,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(categories.length, (i) {
                final cat = categories[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat['label'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCompact(
                          (cat['total_saved'] as num?)?.toDouble() ?? 0,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun bagian rekomendasi strategi menabung pintar.
  Widget _buildRecommendations(bool isDark) {
    final recommendations =
        _recommendationData?['recommendations'] as List? ?? [];
    final globalTip = _recommendationData?['global_tip'] ?? '';

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
          // Global tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(globalTip, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Top 3 recommendations
          ...recommendations.take(3).map((rec) {
            final urgency = rec['urgency'] ?? 'normal';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _getUrgencyEmoji(urgency),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['goal_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Saran: ${currencyFormatter.format(_toNum(rec['daily_suggestion']))}/hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rec['days_remaining'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(urgency).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rec['days_remaining']}d',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getUrgencyColor(urgency),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Menampilkan tampilan placeholder jika data grafik kosong.
  Widget _buildEmptyChart(String message, bool isDark) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }

  String _getUrgencyEmoji(String urgency) {
    switch (urgency) {
      case 'critical':
      case 'overdue':
        return '🚨';
      case 'high':
        return '⚠️';
      case 'medium':
        return '📊';
      default:
        return '✨';
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'critical':
      case 'overdue':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }
}
