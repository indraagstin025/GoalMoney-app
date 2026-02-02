/// Model data untuk merepresentasikan sebuah Badge (Penghargaan).
class Badge {
  /// ID unik badge.
  final int id;

  /// Kode unik identifikasi badge (misal: 'saver_bronze').
  final String code;

  /// Nama badge yang ditampilkan.
  final String name;

  /// Penjelasan mengenai badge ini.
  final String description;

  /// Icon emoji atau path icon badge.
  final String icon;

  /// Tipe syarat untuk mendapatkan badge (misal: 'total_savings').
  final String requirementType;

  /// Nilai target yang harus dicapai untuk mendapatkan badge.
  final int requirementValue;

  /// Nilai progres user saat ini untuk badge ini.
  final num currentValue;

  /// Status apakah badge sudah berhasil didapatkan.
  final bool earned;

  /// Tanggal kapan badge ini didapatkan (jika sudah didapatkan).
  final String? earnedAt;

  Badge({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirementType,
    required this.requirementValue,
    required this.currentValue,
    required this.earned,
    this.earnedAt,
  });

  /// Mengonversi JSON dari API menjadi objek Badge.
  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      requirementType: json['requirement_type'] ?? '',
      requirementValue: json['requirement_value'] ?? 0,
      currentValue: json['current_value'] ?? 0,
      earned: json['earned'] ?? false,
      earnedAt: json['earned_at'],
    );
  }

  /// Mengonversi objek ke Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'current_value': currentValue,
      'earned': earned,
      'earned_at': earnedAt,
    };
  }
}

/// Model statistik badge keseluruhan user.
class BadgeStats {
  /// Jumlah badge yang sudah didapatkan.
  final int earned;

  /// Total badge yang tersedia dalam sistem.
  final int total;

  /// Persentase kelengkapan koleksi badge.
  final double progress;

  BadgeStats({
    required this.earned,
    required this.total,
    required this.progress,
  });

  factory BadgeStats.fromJson(Map<String, dynamic> json) {
    return BadgeStats(
      earned: json['earned'] ?? 0,
      total: json['total'] ?? 0,
      progress: (json['progress'] ?? 0).toDouble(),
    );
  }
}

/// Model respons saat user baru saja mendapatkan badge baru.
class NewBadgeResponse {
  /// Daftar badge yang baru saja diraih.
  final List<Badge> newBadges;

  /// Jumlah badge baru.
  final int count;

  /// Statistik badge terbaru setelah penambahan badge.
  final Map<String, dynamic> stats;

  NewBadgeResponse({
    required this.newBadges,
    required this.count,
    required this.stats,
  });

  factory NewBadgeResponse.fromJson(Map<String, dynamic> json) {
    return NewBadgeResponse(
      newBadges: (json['new_badges'] as List? ?? [])
          .map((b) => Badge.fromJson(b))
          .toList(),
      count: json['count'] ?? 0,
      stats: json['stats'] ?? {},
    );
  }
}
