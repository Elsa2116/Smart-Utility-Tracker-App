class Payment {
  final int? id;
  final int userId;
  final double amount;
  final String type; // electricity, water, gas
  final String paymentMethod; // telebirr, cbe_birr, bank_transfer, mobile_money
  final DateTime date;
  final String status; // pending, completed, failed
  final String notes;

  Payment({
    this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.paymentMethod = 'telebirr',
    required this.date,
    this.status = 'pending',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      type: map['type'],
      paymentMethod: map['paymentMethod'] ?? 'telebirr',
      date: DateTime.parse(map['date']),
      status: map['status'] ?? 'pending',
      notes: map['notes'] ?? '',
    );
  }
}
