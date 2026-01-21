class User {
  final int id;
  final String name;
  final String email;

  final double availableBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.availableBalance = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      availableBalance: _parseBalance(json),
    );
  }

  static double _parseBalance(Map<String, dynamic> json) {
    var val = json['available_balance'] ?? json['balance'];
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
