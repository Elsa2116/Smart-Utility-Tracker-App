/// Represents a utility usage reading for a user.
///
/// Each reading records the type of utility (electricity, water),
/// the usage value, and optional notes.
class Reading {
  // Unique ID of the reading (auto-incremented in the database)
  final int? id;

  // ID of the user who owns this reading
  final int userId;

  // Amount of utility usage recorded
  final double usage;

  // Type of utility (electricity, water)
  final String type;

  // Date and time when the reading was recorded
  final DateTime date;

  // Optional notes about the reading
  final String notes;

  // Constructor for creating a Reading object
  Reading({
    this.id, // optional, as DB auto-generates it
    required this.userId,
    required this.usage,
    required this.type,
    required this.date,
    this.notes = '', // default empty notes
  });

  /// Converts the Reading object to a Map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'usage': usage,
      'type': type,
      'date': date.toIso8601String(), // Store date as ISO string
      'notes': notes,
    };
  }

  /// Creates a Reading object from a Map (retrieved from the database)
  factory Reading.fromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'], // DB id
      userId: map['userId'],
      usage: map['usage'],
      type: map['type'],
      date: DateTime.parse(map['date']), // Convert ISO string back to DateTime
      notes: map['notes'] ?? '', // fallback default if notes is null
    );
  }
}
