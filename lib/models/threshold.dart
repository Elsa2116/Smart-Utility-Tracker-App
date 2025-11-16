class UsageThreshold {
  final int? id;
  final int userId;
  final String type; // electricity, water, gas
  final double maxUsage;
  final String unit; // kWh, L, m³

  UsageThreshold({
    this.id,
    required this.userId,
    required this.type,
    required this.maxUsage,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'maxUsage': maxUsage,
      'unit': unit,
    };
  }

  factory UsageThreshold.fromMap(Map<String, dynamic> map) {
    return UsageThreshold(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      maxUsage: map['maxUsage'],
      unit: map['unit'],
    );
  }
}
