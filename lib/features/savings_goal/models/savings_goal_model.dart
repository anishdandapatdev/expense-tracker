import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {
  final String id;
  final String userId;
  final double targetAmount;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.targetAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'targetAmount': targetAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
