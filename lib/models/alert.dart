/// Represents an alert for a user's utility usage.
///
/// Alerts are generated when usage exceeds a defined threshold.
/// Example types: electricity, water
class Alert {
  // Unique ID of the alert (auto-incremented in database)
  final int? id;

  // ID of the user to whom this alert belongs
  final int userId;

  // Type of utility (e.g., electricity, water)
  final String type;

  // The actual usage value that triggered the alert
  final double usage;

  // The threshold value that was exceeded
  final double threshold;

  // The date and time when the alert was generated
  final DateTime date;

  // Alert message to be displayed to the user
  final String message;

  // Constructor to create an Alert object
  Alert({
    this.id, // optional because it may be auto-generated in DB
    required this.userId,
    required this.type,
    required this.usage,
    required this.threshold,
    required this.date,
    required this.message,
  });

  /// Converts the Alert object to a Map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'usage': usage,
      'threshold': threshold,
      'date': date.toIso8601String(), // Store date as ISO string
      'message': message,
    };
  }

  /// Creates an Alert object from a Map (retrieved from the database)
  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'], // DB id
      userId: map['userId'],
      type: map['type'],
      usage: map['usage'],
      threshold: map['threshold'],
      date: DateTime.parse(map['date']), // Convert ISO string back to DateTime
      message: map['message'],
    );
  }
}
