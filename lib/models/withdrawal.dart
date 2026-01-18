class Withdrawal {
  final int id;
  final int userId;
  final double amount;
  final String method;
  final String? accountNumber;
  final String status;
  final String? notes;
  final String? adminNotes;
  final String createdAt;
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

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: (json['id'] is int) ? json['id'] as int : 0,
      userId: (json['user_id'] is int) ? json['user_id'] as int : 0,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      method: json['method'] as String,
      accountNumber: json['account_number'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

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

class WithdrawalSummary {
  final double totalBalance;
  final double totalPendingWithdrawal;
  final double availableForWithdrawal;
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
