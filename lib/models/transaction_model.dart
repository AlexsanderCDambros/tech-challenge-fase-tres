class TransactionModel {
  final String? id;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String type; // 'income' ou 'expense'
  final String? receiptUrl;

  TransactionModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.type,
    this.receiptUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'type': type,
      'receiptUrl': receiptUrl,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      type: map['type'] ?? 'expense',
      receiptUrl: map['receiptUrl'],
    );
  }
}