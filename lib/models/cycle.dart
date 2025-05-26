// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import '../widgets/cycle_dialog.dart';

import '../models/person.dart';

class Cycle {
  String id;
  int cycleNo;
  String cycleName;
  String openingBalance;
  String amountBalance;
  String amountReceived;
  String amountSpent;
  DateTime startDate;
  DateTime endDate;
  bool isLastCycle;

  Cycle({
    required this.id,
    required this.cycleNo,
    required this.cycleName,
    required this.openingBalance,
    required this.amountBalance,
    required this.amountReceived,
    required this.amountSpent,
    required this.startDate,
    required this.endDate,
    required this.isLastCycle,
  });

  Future<bool> showCycleDialog(
    BuildContext context,
    Person user,
    String title,
  ) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CycleDialog(
          user: user,
          cycle: this,
          title: title,
        );
      },
    );
  }
}
