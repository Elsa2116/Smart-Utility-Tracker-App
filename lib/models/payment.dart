/// Represents a payment made by a user for utility usage.
///
/// Payment can be for electricity, water, or gas, and can have different statuses.
class Payment {
  // Unique ID of the payment (auto-incremented in the database)
  final int? id;

  // ID of the user who made the payment
  final int userId;

  // Amount paid
  final double amount;

  // Type of utility payment (e.g., electricity, water)
  final String type;

  // Method used to make the payment
  // Examples: telebirr, cbe_birr, bank_transfer, mobile_money
  final String paymentMethod;

  // Date and time when the payment was made
  final DateTime date;

  // Payment status: pending, completed, failed
  final String status;

  // Optional notes about the payment
  final String notes;

  // Constructor for creating a Payment object
  Payment({
    this.id, // optional, as DB auto-generates it
    required this.userId,
    required this.amount,
    required this.type,
    this.paymentMethod = 'telebirr', // default value
    required this.date,
    this.status = 'pending', // default status
    this.notes = '', // default empty notes
  });

  /// Converts the Payment object to a Map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(), // Store date as ISO string
      'status': status,
      'notes': notes,
    };
  }

  /// Creates a Payment object from a Map (retrieved from the database)
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'], // DB id
      userId: map['userId'],
      amount: map['amount'],
      type: map['type'],
      paymentMethod: map['paymentMethod'] ?? 'telebirr', // fallback default
      date: DateTime.parse(map['date']), // Convert ISO string back to DateTime
      status: map['status'] ?? 'pending', // fallback default
      notes: map['notes'] ?? '', // fallback default
    );
  }
}
