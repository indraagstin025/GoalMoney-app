/// Model data untuk merepresentasikan sebuah Transaksi Tabungan (Setoran).
class Transaction {
  /// ID unik transaksi dari database.
  final int id;

  /// ID goal (target tabungan) yang terkait dengan transaksi ini.
  final int goalId;

  /// Jumlah nominal uang dalam transaksi.
  final double amount;

  /// Catatan atau deskripsi tambahan untuk transaksi ini.
  final String? description;

  /// Tanggal terjadinya transaksi (format: YYYY-MM-DD HH:mm:ss).
  final String transactionDate;

  Transaction({
    required this.id,
    required this.goalId,
    required this.amount,
    this.description,
    required this.transactionDate,
  });

  /// Mengonversi data JSON dari API menjadi objek Transaction.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      goalId: json['goal_id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      transactionDate: json['transaction_date'],
    );
  }
}
