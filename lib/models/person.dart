import 'package:cloud_firestore/cloud_firestore.dart';

class Person {
  String uid;
  String fullName;
  String nickname;
  String email;
  String photoUrl;
  DateTime lastLogin;
  int transactionLimit;
  int transactionsMade;

  Person({
    required this.uid,
    required this.fullName,
    required this.nickname,
    required this.email,
    required this.photoUrl,
    required this.lastLogin,
    required this.transactionLimit,
    required this.transactionsMade,
  });

  static Future<void> resetTransactionLimit(String userUid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userUid);

    //* Update transactions made
    await userRef.update({'transactions_made': 0});
  }
}
