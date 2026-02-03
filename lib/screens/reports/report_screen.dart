// lib/screens/reports/report_screen.dart
// Laporan Progress Tabungan GoalMoney - UI Screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';
import '../../models/report.dart';
import '../../services/report_export_service.dart';
import '../../widgets/report_skeleton.dart';

/// Layar Laporan Tabungan yang menyajikan data statistik mendalam tentang progress user.
/// Memungkinkan user untuk memfilter laporan berdasarkan periode (hari, minggu, bulan, tahun, atau kustom).
/// User juga dapat mengekspor laporan ke format PDF.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// Formatter mata uang Rupiah.
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Status apakah proses ekspor sedang berjalan.
  bool _isExporting = false;

  /// Kontroler input pencarian goal.
  final TextEditingController _searchCtrl = TextEditingController();

  /// Filter periode yang dipilih (Default: Bulan Ini).
  String _selectedFilter = 'Bulan Ini';

  /// Tanggal awal untuk filter kustom.
  DateTime? _customStartDate;

  /// Tanggal akhir untuk filter kustom.
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(_selectedFilter);
    });
  }

  /// Menerapkan filter periode yang dipilih dan menerjemahkannya ke rentang tanggal.
  void _applyFilter(String filter) {
    setState(() => _selectedFilter = filter);

    String? startStr;
    String? endStr;
    final now = DateTime.now();

    if (filter == 'Hari Ini') {
      startStr = DateFormat('yyyy-MM-dd').format(now);
      endStr = startStr;
    } else if (filter == 'Minggu Ini') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      startStr = DateFormat('yyyy-MM-dd').format(weekStart);
      endStr = DateFormat('yyyy-MM-dd').format(now);
    } else if (filter == 'Bulan Ini') {
      startStr = DateFormat('yyyy-MM-01').format(now);
      endStr = DateFormat('yyyy-MM-dd').format(now);
    } else if (filter == 'Tahun Ini') {
      startStr = DateFormat('yyyy-01-01').format(now);
      endStr = DateFormat('yyyy-MM-dd').format(now);
    } else if (filter == 'Kustom' &&
        _customStartDate != null &&
        _customEndDate != null) {
      startStr = DateFormat('yyyy-MM-dd').format(_customStartDate!);
      endStr = DateFormat('yyyy-MM-dd').format(_customEndDate!);
    }

    _loadReport(startDate: startStr, endDate: endStr);
  }

  /// Mengambil data laporan dari server melalui [GoalProvider].
  Future<void> _loadReport({String? startDate, String? endDate}) async {
    try {
      await context.read<GoalProvider>().fetchReport(
        startDate: startDate,
        endDate: endDate,
        searchQuery: _searchCtrl.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat laporan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Membuat teks ringkasan laporan untuk dibagikan secara teks ke aplikasi lain.
  String _generateShareText(SavingsReport report) {
    final buffer = StringBuffer();

    buffer.writeln('📊 ${report.reportTitle}');
    buffer.writeln(
      '📅 Periode: ${report.period.startDate} - ${report.period.endDate}',
    );
    buffer.writeln('');
    buffer.writeln('📈 RINGKASAN TABUNGAN');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '💰 Total Ditabung: ${currencyFormatter.format(report.summary.totalSaved)}',
    );
    buffer.writeln(
      '🎯 Total Target: ${currencyFormatter.format(report.summary.totalTarget)}',
    );
    buffer.writeln(
      '📊 Progress: ${report.summary.overallProgress.toStringAsFixed(1)}%',
    );
    buffer.writeln('');
    buffer.writeln('📋 GOAL TABUNGAN');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✅ Selesai: ${report.summary.completedGoals}');
    buffer.writeln('🔄 Aktif: ${report.summary.activeGoals}');
    buffer.writeln('📁 Total: ${report.summary.totalGoals}');
    buffer.writeln('');

    if (report.achievements.isNotEmpty) {
      buffer.writeln('🏆 PENCAPAIAN');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      for (var achievement in report.achievements) {
        buffer.writeln('${achievement.icon} ${achievement.title}');
      }
      buffer.writeln('');
    }

    if (report.tips.isNotEmpty) {
      buffer.writeln('💡 TIPS MENABUNG');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      for (var tip in report.tips) {
        buffer.writeln('• ${tip.tip}');
      }
      buffer.writeln('');
    }

    buffer.writeln('Generated by GoalMoney App 💚');

    return buffer.toString();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Menampilkan pemilih rentang tanggal kustom (Date Range Picker).
  void _showCustomRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _applyFilter('Kustom');
    }
  }

  /// Membangun bar pencarian dan baris chip filter periode.
  Widget _buildFilterAndSearch(bool isDark) {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari goal...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                        });
                        _applyFilter(_selectedFilter);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onSubmitted: (_) => _applyFilter(_selectedFilter),
          ),
        ),
        const SizedBox(height: 12),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Hari Ini'),
              const SizedBox(width: 8),
              _buildFilterChip('Minggu Ini'),
              const SizedBox(width: 8),
              _buildFilterChip('Bulan Ini'),
              const SizedBox(width: 8),
              _buildFilterChip('Tahun Ini'),
              const SizedBox(width: 8),
              _buildFilterChip('Kustom', icon: Icons.date_range),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper untuk membangun satu chip filter periode.
  Widget _buildFilterChip(String label, {IconData? icon}) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.green,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          if (label == 'Kustom') {
            _showCustomRangePicker();
          } else {
            _applyFilter(label);
          }
        }
      },
      selectedColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : isDark
            ? Colors.white
            : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
      side: BorderSide(
        color: isSelected
            ? Colors.green
            : isDark
            ? Colors.grey.shade700
            : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  /// Membagikan laporan dalam bentuk teks ke media sosial atau pesan.
  void _shareReport(SavingsReport report) async {
    final shareText = _generateShareText(report);
    await Share.share(shareText, subject: report.reportTitle);
  }

  /// Menyalin isi ringkasan laporan ke Clipboard sistem.
  void _copyReport(SavingsReport report) {
    final shareText = _generateShareText(report);
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan berhasil disalin'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Mengekspor data laporan ke dalam file PDF.
  Future<void> _exportToPdf(SavingsReport report) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Membuat file PDF...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final file = await ReportExportService.exportToPdf(report);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
        _showExportSuccessDialog('PDF', file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// Menampilkan dialog sukses setelah file laporan berhasil dibuat.
  void _showExportSuccessDialog(String type, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text('$type Berhasil Dibuat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File laporan telah berhasil dibuat.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ReportExportService.openFile(File(filePath));
              } catch (e) {
                // File might not be openable on some devices
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Buka File'),
          ),
        ],
      ),
    );
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
              child: Consumer<GoalProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingReport) {
                    return const ReportSkeleton();
                  }

                  final report = provider.report;
                  if (report == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada laporan',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadReport,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Muat Laporan'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadReport,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter & Search Section
                          _buildFilterAndSearch(isDark),
                          const SizedBox(height: 16),

                          // Header Card
                          _buildHeaderCard(report, isDark),
                          const SizedBox(height: 16),

                          // Summary Card
                          _buildSummaryCard(report, isDark),
                          const SizedBox(height: 16),

                          // Goal Details
                          if (report.goalDetails.isNotEmpty) ...[
                            _buildSectionTitle('🎯 Detail Goal', Icons.flag),
                            const SizedBox(height: 8),
                            ...report.goalDetails.map(
                              (goal) => _buildGoalCard(goal, isDark),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Achievements
                          if (report.achievements.isNotEmpty) ...[
                            _buildSectionTitle(
                              '🏆 Pencapaian',
                              Icons.emoji_events,
                            ),
                            const SizedBox(height: 8),
                            _buildAchievementsCard(report.achievements, isDark),
                            const SizedBox(height: 16),
                          ],

                          // Tips
                          if (report.tips.isNotEmpty) ...[
                            _buildSectionTitle(
                              '💡 Tips Menabung',
                              Icons.lightbulb,
                            ),
                            const SizedBox(height: 8),
                            _buildTipsCard(report.tips, isDark),
                            const SizedBox(height: 16),
                          ],

                          // Monthly Breakdown
                          if (report.monthlyBreakdown.isNotEmpty) ...[
                            _buildSectionTitle(
                              '📈 Tren Bulanan',
                              Icons.trending_up,
                            ),
                            const SizedBox(height: 8),
                            _buildMonthlyBreakdownCard(
                              report.monthlyBreakdown,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Transaction History Section
                          if (report.transactions.isNotEmpty) ...[
                            _buildSectionTitle(
                              '📝 Riwayat Transaksi',
                              Icons.history,
                            ),
                            const SizedBox(height: 8),
                            _buildTransactionsCard(report.transactions, isDark),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun header kustom dengan logo dan menu tindakan ekspor.
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
              Consumer<GoalProvider>(
                builder: (context, provider, _) {
                  if (provider.report != null) {
                    return PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onSelected: (value) {
                        if (value == 'share') {
                          _shareReport(provider.report!);
                        } else if (value == 'copy') {
                          _copyReport(provider.report!);
                        } else if (value == 'pdf') {
                          _exportToPdf(provider.report!);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Export ke PDF'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('Bagikan Laporan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Salin Teks'),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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

  /// Membangun kartu header utama dengan informasi periode laporan.
  Widget _buildHeaderCard(SavingsReport report, bool isDark) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assessment,
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
                      report.reportTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Periode: ${report.period.startDate} - ${report.period.endDate}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderStat('Total Goal', '${report.summary.totalGoals}'),
                _buildDivider(),
                _buildHeaderStat('Selesai', '${report.summary.completedGoals}'),
                _buildDivider(),
                _buildHeaderStat(
                  'Progress',
                  '${report.summary.overallProgress.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildSummaryCard(SavingsReport report, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.green[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan Keuangan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Ditabung',
            currencyFormatter.format(report.summary.totalSaved),
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Total Target',
            currencyFormatter.format(report.summary.totalTarget),
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Sisa Target',
            currencyFormatter.format(
              report.summary.totalTarget - report.summary.totalSaved,
            ),
            Colors.orange,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: report.summary.overallProgress / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                report.summary.overallProgress >= 100
                    ? Colors.green
                    : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${report.summary.overallProgress.toStringAsFixed(1)}% tercapai',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[700], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGoalCard(GoalReport goal, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (goal.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'active':
      case 'on_track':
        statusColor = Colors.blue;
        statusIcon = Icons.trending_up;
        break;
      case 'behind':
        statusColor = Colors.orange;
        statusIcon = Icons.trending_down;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    // Terjemahkan status untuk tampilan
    String displayStatus;
    switch (goal.status.toLowerCase()) {
      case 'completed':
        displayStatus = 'Selesai';
        break;
      case 'active':
      case 'on_track':
        displayStatus = 'Dalam Progres';
        break;
      case 'behind':
        displayStatus = 'Tertinggal';
        break;
      default:
        displayStatus = goal.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terkumpul',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    Text(
                      currencyFormatter.format(goal.currentAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    Text(
                      currencyFormatter.format(goal.targetAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  Text(
                    '${goal.progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${goal.deadline}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(List<Achievement> achievements, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: achievements.map((achievement) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        achievement.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTipsCard(List<SavingsTip> tips, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tip.icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.tip,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            tip.priority,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tip.priority,
                          style: TextStyle(
                            color: _getPriorityColor(tip.priority),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMonthlyBreakdownCard(
    List<MonthlyBreakdown> breakdown,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Bulan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Ditabung',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Transaksi',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...breakdown.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.month,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      currencyFormatter.format(item.totalSaved),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.transactionCount}x',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
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

  Widget _buildTransactionsCard(
    List<ReportTransaction> transactions,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Tanggal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Goal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Jumlah',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...transactions.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.date.split(' ')[0],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      t.goalName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      currencyFormatter.format(t.amount),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 12,
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
}
