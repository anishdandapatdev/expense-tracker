import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/features/friends_money/models/friend_money_model.dart';
import 'package:expense_tracker/features/friends_money/repositories/friend_money_repository.dart';

final friendMoneyStreamProvider =
    StreamProvider.family<List<FriendMoneyModel>, String>((ref, userId) {
  final repository = ref.watch(friendMoneyRepositoryProvider);
  return repository.getUserFriendMoney(userId);
});

final friendMoneyControllerProvider = Provider<FriendMoneyController>((ref) {
  final repository = ref.watch(friendMoneyRepositoryProvider);
  return FriendMoneyController(repository);
});

class FriendMoneyController {
  final FriendMoneyRepository _repository;

  FriendMoneyController(this._repository);

  Future<void> addFriendMoney(FriendMoneyModel record) async {
    try {
      await _repository.addFriendMoney(record);
    } catch (e) {
      debugPrint('Error adding friend money record: $e');
      rethrow;
    }
  }

  Future<void> updateFriendMoney(FriendMoneyModel record) async {
    try {
      await _repository.updateFriendMoney(record);
    } catch (e) {
      debugPrint('Error updating friend money record: $e');
      rethrow;
    }
  }

  Future<void> deleteFriendMoney(String id) async {
    try {
      await _repository.deleteFriendMoney(id);
    } catch (e) {
      debugPrint('Error deleting friend money record: $e');
      rethrow;
    }
  }
}
