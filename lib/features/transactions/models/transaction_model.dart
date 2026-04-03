import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category; // e.g., 'Food', 'Transport'
  final String account; // e.g., 'Cash', 'Bank'
  final DateTime date;
  final String? note;
  final bool isHidden;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    required this.date,
    this.note,
    this.isHidden = false,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    String? category,
    String? account,
    DateTime? date,
    String? note,
    bool? isHidden,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      account: account ?? this.account,
      date: date ?? this.date,
      note: note ?? this.note,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'account': account,
      'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'note': note,
      'isHidden': isHidden,
    };
  }

  // Create Object from Firestore Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'expense',
      // SAFELY PARSE AMOUNT AS NUM FIRST
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0, 
      category: map['category'] ?? 'Other',
      account: map['account'] ?? 'Cash',
      date: (map['date'] as Timestamp).toDate(), // Convert back to DateTime
      note: map['note'],
      isHidden: map['isHidden'] ?? false,
    );
  }
}