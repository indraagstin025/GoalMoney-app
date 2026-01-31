class Goal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String? description;
  final dynamic progressPercentage; // Can be int or double from JSON
  final String? photoPath;
  final String? type; // 'digital' or 'cash'

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
  });

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
      photoPath: null, // Photo path will be loaded separately
    );
  }

  double get progress => (progressPercentage is num)
      ? (progressPercentage as num).toDouble()
      : 0.0;

  bool get isCompleted => progress >= 100.0;
}
