// lib/models/report.dart
// Model untuk Laporan Progress Tabungan GoalMoney

/// Model utama untuk Laporan Tabungan GoalMoney yang mencakup seluruh data performa.
class SavingsReport {
  /// Tanggal pembuatan laporan.
  final String reportDate;

  /// Judul laporan yang ditampilkan.
  final String reportTitle;

  /// Rentang waktu laporan (mulai - selesai).
  final ReportPeriod period;

  /// Ringkasan statistik tabungan.
  final ReportSummary summary;

  /// Daftar detail performa tiap goal.
  final List<GoalReport> goals;

  /// Daftar pencapaian selama periode laporan.
  final List<Achievement> achievements;

  /// Tips tabungan yang dipersonalisasi.
  final List<SavingsTip> tips;

  /// Rincian tabungan per bulan untuk grafik.
  final List<MonthlyBreakdown> monthlyBreakdown;

  /// Riwayat transaksi selama periode.
  final List<ReportTransaction> transactions;

  /// Badge yang diperoleh dalam periode ini.
  final List<ReportBadge> badges;

  /// Alias untuk kompatibilitas UI lama.
  List<GoalReport> get goalDetails => goals;

  SavingsReport({
    required this.reportDate,
    required this.reportTitle,
    required this.period,
    required this.summary,
    required this.goals,
    required this.achievements,
    required this.tips,
    required this.monthlyBreakdown,
    required this.transactions,
    required this.badges,
  });

  /// Mengonversi JSON dari API Laporan menjadi objek SavingsReport.
  factory SavingsReport.fromJson(Map<String, dynamic> json) {
    return SavingsReport(
      reportDate: json['report_date'] ?? '',
      reportTitle: json['report_title'] ?? 'Laporan Progress Tabungan',
      period: ReportPeriod.fromJson(json['period'] ?? {}),
      summary: ReportSummary.fromJson(json['summary'] ?? {}),
      goals:
          (json['goals'] as List<dynamic>?)
              ?.map((g) => GoalReport.fromJson(g))
              .toList() ??
          [],
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
      tips:
          (json['tips'] as List<dynamic>?)
              ?.map((t) => SavingsTip.fromJson(t))
              .toList() ??
          [],
      monthlyBreakdown:
          (json['monthly_breakdown'] as List<dynamic>?)
              ?.map((m) => MonthlyBreakdown.fromJson(m))
              .toList() ??
          [],
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map((t) => ReportTransaction.fromJson(t))
              .toList() ??
          [],
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((b) => ReportBadge.fromJson(b))
              .toList() ??
          [],
    );
  }
}

/// Mewakili periode waktu (tanggal mulai dan selesai).
class ReportPeriod {
  final String start;
  final String end;

  ReportPeriod({required this.start, required this.end});

  /// Alias getter untuk kompatibilitas UI.
  String get startDate => start;
  String get endDate => end;

  factory ReportPeriod.fromJson(Map<String, dynamic> json) {
    return ReportPeriod(start: json['start'] ?? '', end: json['end'] ?? '');
  }
}

/// Ringkasan statistik utama tabungan user.
class ReportSummary {
  /// Total target yang pernah dibuat.
  final int totalGoals;

  /// Jumlah target yang sudah selesai.
  final int completedGoals;

  /// Jumlah target yang masih aktif.
  final int activeGoals;

  /// Total seluruh uang yang sudah ditabung.
  final double totalSaved;

  /// Total target uang dari seluruh goal.
  final double totalTarget;

  /// Persentase progres kumulatif.
  final double overallProgress;

  /// Jumlah uang yang ditabung khusus dalam periode laporan.
  final double periodSavings;

  /// Total berapa kali user melakukan setoran.
  final int totalDeposits;

  /// Total berapa kali user melakukan penarikan.
  final int totalWithdrawals;

  ReportSummary({
    required this.totalGoals,
    required this.completedGoals,
    required this.activeGoals,
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
    required this.periodSavings,
    required this.totalDeposits,
    required this.totalWithdrawals,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalGoals: json['total_goals'] ?? 0,
      completedGoals: json['completed_goals'] ?? 0,
      activeGoals: json['active_goals'] ?? 0,
      totalSaved: (json['total_saved'] as num?)?.toDouble() ?? 0.0,
      totalTarget: (json['total_target'] as num?)?.toDouble() ?? 0.0,
      overallProgress: (json['overall_progress'] as num?)?.toDouble() ?? 0.0,
      periodSavings: (json['period_savings'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: json['total_deposits'] ?? 0,
      totalWithdrawals: json['total_withdrawals'] ?? 0,
    );
  }
}

/// Detail performa untuk objek Goal di dalam laporan.
class GoalReport {
  final int id;
  final String name;
  final String type;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final double progressPercentage;
  final String status;
  final String? deadline;
  final int? daysRemaining;
  final int totalDeposits;
  final String? lastDepositDate;
  final String? description;

  GoalReport({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.progressPercentage,
    required this.status,
    this.deadline,
    this.daysRemaining,
    required this.totalDeposits,
    this.lastDepositDate,
    this.description,
  });

  factory GoalReport.fromJson(Map<String, dynamic> json) {
    return GoalReport(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'digital',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'active',
      deadline: json['deadline'],
      daysRemaining: json['days_remaining'],
      totalDeposits: json['total_deposits'] ?? 0,
      lastDepositDate: json['last_deposit_date'],
      description: json['description'],
    );
  }

  bool get isCompleted => status == 'completed';

  /// Alias getter untuk progres.
  double get progress => progressPercentage;
}

/// Representasi pencapaian atau milestone yang diraih user.
class Achievement {
  /// Tipe pencapaian (misal: 'goal_completed').
  final String type;

  /// Icon emoji atau path icon.
  final String icon;

  /// Judul pencapaian.
  final String title;

  /// Penjelasan detail pencapaian.
  final String description;

  /// Nama target yang terkait (jika ada).
  final String? goalName;

  final double? amount;
  final double? progress;
  final double? remaining;
  final String? date;

  Achievement({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    this.goalName,
    this.amount,
    this.progress,
    this.remaining,
    this.date,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      type: json['type'] ?? '',
      icon: json['icon'] ?? '🎯',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      goalName: json['goal_name'],
      amount: (json['amount'] as num?)?.toDouble(),
      progress: (json['progress'] as num?)?.toDouble(),
      remaining: (json['remaining'] as num?)?.toDouble(),
      date: json['date'],
    );
  }
}

/// Tips menabung yang disarankan sistem.
class SavingsTip {
  final String icon;
  final String tip;
  final String priority;

  SavingsTip({required this.icon, required this.tip, this.priority = 'medium'});

  factory SavingsTip.fromJson(Map<String, dynamic> json) {
    return SavingsTip(
      icon: json['icon'] ?? '💡',
      tip: json['tip'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }
}

/// Rincian tabungan bulanan (untuk keperluan charting).
class MonthlyBreakdown {
  final String month;
  final int monthNumber;
  final int year;
  final double amount;
  final int depositCount;

  MonthlyBreakdown({
    required this.month,
    required this.monthNumber,
    required this.year,
    required this.amount,
    required this.depositCount,
  });

  /// Alias getter untuk total tabungan.
  double get totalSaved => amount;

  /// Alias getter untuk jumlah setoran.
  int get transactionCount => depositCount;

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> json) {
    return MonthlyBreakdown(
      month: json['month'] ?? '',
      monthNumber: json['month_number'] ?? 0,
      year: json['year'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      depositCount: json['deposit_count'] ?? 0,
    );
  }
}

/// Data transaksi di dalam Laporan.
class ReportTransaction {
  final int id;
  final String goalName;
  final double amount;
  final String method;
  final String? description;
  final String date;

  ReportTransaction({
    required this.id,
    required this.goalName,
    required this.amount,
    required this.method,
    this.description,
    required this.date,
  });

  factory ReportTransaction.fromJson(Map<String, dynamic> json) {
    return ReportTransaction(
      id: json['id'] ?? 0,
      goalName: json['goal_name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] ?? 'manual',
      description: json['description'],
      date: json['date'] ?? '',
    );
  }
}

/// Mewakili Badge yang diraih oleh user.
class ReportBadge {
  final int id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String requirementType;
  final String earnedAt;
  final int? progressValue;

  ReportBadge({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirementType,
    required this.earnedAt,
    this.progressValue,
  });

  factory ReportBadge.fromJson(Map<String, dynamic> json) {
    return ReportBadge(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      requirementType: json['requirement_type'] ?? 'goal_count',
      earnedAt: json['earned_at'] ?? '',
      progressValue: json['progress_value'],
    );
  }

  /// Mendapatkan kategori badge dari kode prefix.
  String get displayCategory => code.split('_').first.toLowerCase();

  /// Mendapatkan tingkatan (tier) badge.
  String get displayTier {
    if (code.contains('platinum')) return 'platinum';
    if (code.contains('gold')) return 'gold';
    if (code.contains('silver')) return 'silver';
    return 'bronze';
  }
}
