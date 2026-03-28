import 'package:cloud_firestore/cloud_firestore.dart';

class FriendMoneyModel {
  final String id;
  final String userId;
  final String friendName;
  final String type; // 'lent' (they owe you) or 'borrowed' (you owe them)
  final double amount;
  final DateTime date;
  final String? note;
  final bool isSettled;

  FriendMoneyModel({
    required this.id,
    required this.userId,
    required this.friendName,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    this.isSettled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendName': friendName,
      'type': type,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'isSettled': isSettled,
    };
  }

  factory FriendMoneyModel.fromMap(Map<String, dynamic> map) {
    return FriendMoneyModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      friendName: map['friendName'] ?? '',
      type: map['type'] ?? 'lent',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'],
      isSettled: map['isSettled'] ?? false,
    );
  }
}
