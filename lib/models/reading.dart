class Reading {
  final int? id;
  final int userId;
  final double usage;
  final String type; // electricity, water, gas
  final DateTime date;
  final String notes;

  Reading({
    this.id,
    required this.userId,
    required this.usage,
    required this.type,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'usage': usage,
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Reading.fromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'],
      userId: map['userId'],
      usage: map['usage'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
    );
  }
}
