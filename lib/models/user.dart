/// Model data untuk merepresentasikan seorang Pengguna (User).
class User {
  /// ID unik pengguna dari database.
  final int id;

  /// Nama lengkap pengguna.
  final String name;

  /// Alamat email pengguna.
  final String email;

  /// Saldo yang tersedia untuk ditarik atau dialokasikan kembali.
  final double availableBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.availableBalance = 0.0,
  });

  /// Mengonversi data JSON dari API menjadi objek User.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      availableBalance: _parseBalance(json),
    );
  }

  /// Helper untuk memparsing saldo dari berbagai format JSON yang mungkin diterima.
  static double _parseBalance(Map<String, dynamic> json) {
    var val = json['available_balance'] ?? json['balance'];
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
