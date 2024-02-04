import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Person {
  String id;
  String fullName;
  String nickname;
  String email;
  String photoUrl;
  DateTime lastLogin;
  int transactionLimit;
  int transactionsMade;

  Person({
    required this.id,
    required this.fullName,
    required this.nickname,
    required this.email,
    required this.photoUrl,
    required this.lastLogin,
    required this.transactionLimit,
    required this.transactionsMade,
  });

  Future<void> resetTransactionLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    //* Update transactions made
    await userRef.update({'transactions_made': 0});
  }
}
