import 'package:flutter/material.dart';

import '../widgets/change_password_dialog.dart';
import '../widgets/person_dialog.dart';

class Person {
  String uid;
  String displayName;
  String email;
  String imageUrl;
  DateTime lastLogin;
  int dailyTransactionsMade;
  bool forceRefresh;

  Person({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.imageUrl,
    required this.lastLogin,
    required this.dailyTransactionsMade,
    required this.forceRefresh,
  });

  Future<bool> showEditDisplayNameDialog(
    BuildContext context,
  ) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return PersonDialog(
          user: this,
        );
      },
    );
  }

  Future<bool> showChangePasswordDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return ChangePasswordDialog();
      },
    );
  }
}
