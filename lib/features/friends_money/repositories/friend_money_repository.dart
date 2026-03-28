import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/friends_money/models/friend_money_model.dart';

final friendMoneyRepositoryProvider = Provider<FriendMoneyRepository>((ref) {
  return FriendMoneyRepository(FirebaseFirestore.instance);
});

class FriendMoneyRepository {
  final FirebaseFirestore _firestore;

  FriendMoneyRepository(this._firestore);

  CollectionReference get _friendMoney => _firestore.collection('friend_money');

  Future<void> addFriendMoney(FriendMoneyModel friendMoney) async {
    try {
      await _friendMoney.doc(friendMoney.id).set(friendMoney.toMap());
    } catch (e) {
      throw Exception('Failed to add friend money record: $e');
    }
  }

  Future<void> updateFriendMoney(FriendMoneyModel friendMoney) async {
    try {
      await _friendMoney.doc(friendMoney.id).update(friendMoney.toMap());
    } catch (e) {
      throw Exception('Failed to update friend money record: $e');
    }
  }

  Stream<List<FriendMoneyModel>> getUserFriendMoney(String userId) {
    return _friendMoney
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FriendMoneyModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> deleteFriendMoney(String id) async {
    try {
      await _friendMoney.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete friend money record: $e');
    }
  }
}
