// lib/screens/analytics/analytics_screen.dart
// Analytics Dashboard dengan grafik statistik

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import 'streak_calendar_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiClient _apiClient = ApiClient();
  int _selectedYear = DateTime.now().year;

  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _recommendationData;
  bool _isLoading = true;
  String? _error;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Helper to safely convert API values (String/num) to num
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
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StreakCalendarScreen()),
            ),
            tooltip: 'Streak Calendar',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
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
                    const SizedBox(height: 12),
                    _buildLineChart(isDark),
                    const SizedBox(height: 24),

                    // Goal Progress Bar Chart
                    _buildSectionTitle('🎯 Progress Goal'),
                    const SizedBox(height: 12),
                    _buildBarChart(isDark),
                    const SizedBox(height: 24),

                    // Category Distribution Pie Chart
                    _buildSectionTitle('📊 Distribusi Kategori Goal'),
                    const SizedBox(height: 12),
                    _buildPieChart(isDark),
                    const SizedBox(height: 24),

                    // Recommendations
                    if (_recommendationData != null &&
                        (_recommendationData!['count'] ?? 0) > 0) ...[
                      _buildSectionTitle('🤖 Smart Recommendations'),
                      const SizedBox(height: 12),
                      _buildRecommendations(isDark),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

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
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
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

  Widget _buildPieChart(bool isDark) {
    final categories = _analyticsData?['category_distribution'] as List? ?? [];

    final activeCategories = categories
        .where((c) => (c['count'] as int?) != null && (c['count'] as int) > 0)
        .toList();

    if (activeCategories.isEmpty) {
      return _buildEmptyChart('Belum ada goal', isDark);
    }

    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];

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
                sections: List.generate(activeCategories.length, (i) {
                  final cat = activeCategories[i];
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
              mainAxisSize: MainAxisSize.min,
              children: List.generate(activeCategories.length, (i) {
                final cat = activeCategories[i];
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
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Text(
                        _formatCompact(
                          (cat['total_saved'] as num?)?.toDouble() ?? 0,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                            color: Colors.grey[600],
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

  Widget _buildEmptyChart(String message, bool isDark) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[600])),
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
