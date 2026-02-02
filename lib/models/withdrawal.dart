/// Model data untuk merepresentasikan permintaan penarikan dana (Withdrawal).
class Withdrawal {
  /// ID unik penarikan.
  final int id;

  /// ID user yang melakukan penarikan.
  final int userId;

  /// Jumlah nominal yang ditarik.
  final double amount;

  /// Metode penarikan (misal: 'dana', 'gopay', 'bank_transfer').
  final String method;

  /// Nomor rekening atau nomor telepon tujuan.
  final String? accountNumber;

  /// Status penarikan ('pending', 'approved', 'rejected', 'completed').
  final String status;

  /// Catatan dari user saat mengajukan penarikan.
  final String? notes;

  /// Catatan dari admin (misal alasan penolakan).
  final String? adminNotes;

  /// Tanggal pengajuan dibuat.
  final String createdAt;

  /// Tanggal terakhir data diperbarui.
  final String? updatedAt;

  Withdrawal({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    this.accountNumber,
    required this.status,
    this.notes,
    this.adminNotes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Mengonversi JSON dari API menjadi objek Withdrawal.
  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: (json['id'] is int) ? json['id'] as int : 0,
      userId: (json['user_id'] is int) ? json['user_id'] as int : 0,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : 0.0,
      method: json['method'] as String,
      accountNumber: json['account_number'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Mengonversi objek ke Map (JSON) untuk dikirim ke API atau disimpan.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'account_number': accountNumber,
      'status': status,
      'notes': notes,
      'admin_notes': adminNotes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Mendapatkan label status dalam Bahasa Indonesia untuk tampilan UI.
  String getStatusLabel() {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  /// Mendapatkan label metode pembayaran yang lebih rapi untuk tampilan UI.
  String getMethodLabel() {
    switch (method) {
      case 'dana':
        return 'Dana';
      case 'gopay':
        return 'GoPay';
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'bca':
        return 'BCA';
      case 'mandiri':
        return 'Mandiri';
      case 'bni':
        return 'BNI';
      default:
        return method;
    }
  }
}

/// Ringkasan statistik saldo dan penarikan user.
class WithdrawalSummary {
  /// Total saldo tabungan keseluruhan.
  final double totalBalance;

  /// Total dana yang sedang dalam proses penarikan.
  final double totalPendingWithdrawal;

  /// Saldo yang benar-benar bisa ditarik saat ini.
  final double availableForWithdrawal;

  /// Total dana yang sudah berhasil ditarik sebelumnya.
  final double totalCompleted;

  WithdrawalSummary({
    required this.totalBalance,
    required this.totalPendingWithdrawal,
    required this.availableForWithdrawal,
    required this.totalCompleted,
  });

  factory WithdrawalSummary.fromJson(Map<String, dynamic> json) {
    return WithdrawalSummary(
      totalBalance: (json['total_balance'] is num)
          ? (json['total_balance'] as num).toDouble()
          : 0.0,
      totalPendingWithdrawal: (json['total_pending_withdrawal'] is num)
          ? (json['total_pending_withdrawal'] as num).toDouble()
          : 0.0,
      availableForWithdrawal: (json['available_for_withdrawal'] is num)
          ? (json['available_for_withdrawal'] as num).toDouble()
          : 0.0,
      totalCompleted: (json['total_completed'] is num)
          ? (json['total_completed'] as num).toDouble()
          : 0.0,
    );
  }
}
