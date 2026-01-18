class Transaction {
  final int id;
  final int goalId;
  final double amount;
  final String? description;
  final String transactionDate;

  Transaction({
    required this.id,
    required this.goalId,
    required this.amount,
    this.description,
    required this.transactionDate,
  });

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
