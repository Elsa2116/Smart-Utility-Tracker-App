/// Represents a usage threshold for a specific utility for a user.
///
/// A threshold defines the maximum allowed usage for a utility type (e.g., electricity, water),
/// and is used to trigger alerts when exceeded.
class UsageThreshold {
  // Unique ID of the threshold (auto-incremented in the database)
  final int? id;

  // ID of the user who owns this threshold
  final int userId;

  // Type of utility (e.g., electricity, water)
  final String type;

  // Maximum allowed usage for this utility
  final double maxUsage;

  // Unit of measurement (e.g., kWh for electricity, L for water, m³ for gas)
  final String unit;

  // Constructor to create a UsageThreshold object
  UsageThreshold({
    this.id, // optional, as DB auto-generates it
    required this.userId,
    required this.type,
    required this.maxUsage,
    required this.unit,
  });

  /// Converts the UsageThreshold object to a Map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'maxUsage': maxUsage,
      'unit': unit,
    };
  }

  /// Creates a UsageThreshold object from a Map (retrieved from the database)
  factory UsageThreshold.fromMap(Map<String, dynamic> map) {
    return UsageThreshold(
      id: map['id'], // DB id
      userId: map['userId'],
      type: map['type'],
      maxUsage: map['maxUsage'],
      unit: map['unit'],
    );
  }
}
