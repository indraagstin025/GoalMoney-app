/// Model data untuk merepresentasikan sebuah Goal (Target Tabungan).
class Goal {
  /// ID unik tiap goal dari database.
  final int id;

  /// Nama atau judul dari target tabungan.
  final String name;

  /// Jumlah uang total yang ingin dikumpulkan.
  final double targetAmount;

  /// Jumlah uang yang sudah berhasil dikumpulkan saat ini.
  final double currentAmount;

  /// Tanggal batas waktu pencapaian (format: YYYY-MM-DD), bersifat opsional.
  final String? deadline;

  /// Deskripsi atau catatan tambahan mengenai target ini.
  final String? description;

  /// Persentase progres saat ini (bisa berupa int atau double dari API).
  final dynamic progressPercentage;

  /// Path file untuk foto profil target (lokal).
  final String? photoPath;

  /// Tipe penyimpanan: 'digital' (e-wallet) atau 'cash' (fisik).
  final String? type;

  /// Tanggal kapan goal ini dibuat (untuk keperluan filtering).
  final String? createdAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.description,
    this.progressPercentage,
    this.photoPath,
    this.type,
    this.createdAt,
  });

  /// Mengonversi data JSON dari API menjadi objek Goal.
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      deadline: json['deadline'],
      description: json['description'],
      type: json['type'],
      progressPercentage: json['progress_percentage'],
      photoPath:
          null, // Path foto dimuat secara terpisah oleh PhotoStorageService
      createdAt: json['created_at'],
    );
  }

  /// Mendapatkan nilai persentase progres sebagai double.
  double get progress => (progressPercentage is num)
      ? (progressPercentage as num).toDouble()
      : 0.0;

  /// Mengecek apakah target tabungan sudah tercapai (progres >= 100%).
  bool get isCompleted => progress >= 100.0;
}
