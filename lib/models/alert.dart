class Alert {
  final int? id;
  final int userId;
  final String type; // electricity, water, gas
  final double usage;
  final double threshold;
  final DateTime date;
  final String message;

  Alert({
    this.id,
    required this.userId,
    required this.type,
    required this.usage,
    required this.threshold,
    required this.date,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'usage': usage,
      'threshold': threshold,
      'date': date.toIso8601String(),
      'message': message,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      usage: map['usage'],
      threshold: map['threshold'],
      date: DateTime.parse(map['date']),
      message: map['message'],
    );
  }
}
