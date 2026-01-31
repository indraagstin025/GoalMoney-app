// lib/models/badge.dart
// Model untuk Badge system

class Badge {
  final int id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String requirementType;
  final int requirementValue;
  final num currentValue;
  final bool earned;
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

class BadgeStats {
  final int earned;
  final int total;
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

class NewBadgeResponse {
  final List<Badge> newBadges;
  final int count;
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
