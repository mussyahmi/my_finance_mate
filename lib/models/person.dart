import 'package:cloud_firestore/cloud_firestore.dart';

class Person {
  String uid;
  String fullName;
  String nickname;
  String email;
  String photoUrl;
  DateTime lastLogin;
  int dailyTransactionsMade;

  Person({
    required this.uid,
    required this.fullName,
    required this.nickname,
    required this.email,
    required this.photoUrl,
    required this.lastLogin,
    required this.dailyTransactionsMade,
  });

  Future<void> checkTransactionMade(
      DateTime lastTansactionDate, String userUid) async {
    DateTime today = DateTime.now();

    if (!(lastTansactionDate.year == today.year &&
            lastTansactionDate.month == today.month &&
            lastTansactionDate.day == today.day) &&
        dailyTransactionsMade > 0) {
      await resetTransactionMade(uid);
    }
  }

  static Future<void> resetTransactionMade(String userUid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userUid);

    //* Update transactions made
    await userRef.update({'transactions_made': 0});
  }
}
