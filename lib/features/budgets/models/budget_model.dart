class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'limitAmount': limitAmount,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      limitAmount: (map['limitAmount'] ?? 0.0).toDouble(),
    );
  }
}