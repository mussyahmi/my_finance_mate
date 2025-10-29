import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/debt_dialog.dart';

enum DebtType { iOwe, theyOweMe }

class Debt {
  final String id;
  final String personName;
  final String amount;
  final DebtType type;
  final String note;
  final bool isSettled;
  final DateTime createdAt;

  Debt({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.note,
    required this.isSettled,
    required this.createdAt,
  });

  factory Debt.fromMap(String id, Map<String, dynamic> data) {
    return Debt(
      id: id,
      personName: data['personName'],
      amount: data['amount'],
      type: data['type'] == 'iOwe' ? DebtType.iOwe : DebtType.theyOweMe,
      note: data['note'],
      isSettled: data['isSettled'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personName': personName,
      'amount': amount,
      'type': type == DebtType.iOwe ? 'iOwe' : 'theyOweMe',
      'isSettled': isSettled,
      'note': note,
      'createdAt': createdAt,
    };
  }

  static Future<bool> showDebtDialog(BuildContext parentContext, String action,
      {Debt? debt, bool? isTourMode}) async {
    return await showDialog(
          context: parentContext,
          builder: (context) {
            return DebtDialog(
              parentContext: parentContext,
              action: action,
              debt: debt,
            );
          },
        ) ??
        false;
  }
}
