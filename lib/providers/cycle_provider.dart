// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/account.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../models/transaction.dart' as t;
import '../pages/cycle_add_page.dart';
import '../pages/dashboard_page.dart';
import 'accounts_provider.dart';
import 'categories_provider.dart';
import 'transactions_provider.dart';
import 'person_provider.dart';

class CycleProvider extends ChangeNotifier {
  Cycle? cycle;

  CycleProvider({this.cycle});

  Future<void> fetchCycle(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<PersonProvider>().user!;
    final DateTime now = DateTime.now();

    final cycleQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .orderBy('cycle_no', descending: true)
        .limit(1);
    final cycleSnapshot = await cycleQuery.getSavy(refresh: refresh);
    print('fetchCycle: ${cycleSnapshot.docs.length}');

    if (cycleSnapshot.docs.isNotEmpty) {
      final cycleDoc = cycleSnapshot.docs.first;

      cycle = Cycle(
        id: cycleDoc.id,
        cycleNo: cycleDoc['cycle_no'],
        cycleName: cycleDoc['cycle_name'],
        openingBalance: cycleDoc['opening_balance'],
        amountBalance: cycleDoc['amount_balance'],
        amountReceived: cycleDoc['amount_received'],
        amountSpent: cycleDoc['amount_spent'],
        startDate: (cycleDoc['start_date'] as Timestamp).toDate(),
        endDate: (cycleDoc['end_date'] as Timestamp).toDate(),
        isLastCycle: true,
      );

      if (cycle!.endDate.isBefore(now)) {
        //* Last cycle has ended, redirect to add cycle page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CycleAddPage(cycle: cycle)),
          (route) =>
              false, //* This line removes all previous routes from the stack
        );
      }

      notifyListeners();
    } else {
      //* No cycles found, redirect to add cycle page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const CycleAddPage(cycle: null)),
        (route) =>
            false, //* This line removes all previous routes from the stack
      );
    }
  }

  Future<void> switchCycle(BuildContext context, Cycle newCycle) async {
    cycle = newCycle;

    await context.read<CategoriesProvider>().fetchCategories(context, newCycle);
    await context.read<AccountsProvider>().fetchAccounts(context, newCycle);
    await context
        .read<TransactionsProvider>()
        .fetchTransactions(context, newCycle);

    notifyListeners();
  }

  Future<void> addCycle(BuildContext context, String cycleName,
      DateTime startDate, DateTime endDate, String openingBalance) async {
    final Person user = context.read<PersonProvider>().user!;
    final DateTime now = DateTime.now();

    //* Create the new cycle document
    final newCycleDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .add({
      'cycle_no': cycle != null ? cycle!.cycleNo + 1 : 1,
      'cycle_name': cycleName,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'opening_balance': openingBalance,
      'amount_balance': openingBalance,
      'amount_received': '0.00',
      'amount_spent': '0.00',
    });

    if (cycle != null) {
      await _copyCategoriesFromLastCycle(user, cycle!.id, newCycleDoc.id, now);
      await _copyAccountsFromLastCycle(user, cycle!.id, newCycleDoc.id, now);
    }

    await context.read<CycleProvider>().fetchCycle(context);
    await context
        .read<CategoriesProvider>()
        .fetchCategories(context, context.read<CycleProvider>().cycle!);
    await context
        .read<CategoriesProvider>()
        .fetchCategories(context, context.read<CycleProvider>().cycle!);
    await context
        .read<AccountsProvider>()
        .fetchAccounts(context, context.read<CycleProvider>().cycle!);
    await context
        .read<TransactionsProvider>()
        .fetchTransactions(context, context.read<CycleProvider>().cycle!);

    notifyListeners();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => const DashboardPage(refresh: true)),
      (route) => false, //* This line removes all previous routes from the stack
    );
  }

  Future<void> _copyCategoriesFromLastCycle(
    Person user,
    String lastCycleId,
    String newCycleId,
    DateTime now,
  ) async {
    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(lastCycleId)
        .collection('categories')
        .where('deleted_at', isNull: true)
        .getSavy();
    print('copyCategoriesFromLastCycle: ${categoriesSnapshot.docs.length}');

    for (var doc in categoriesSnapshot.docs) {
      final categoryData = doc.data();
      categoryData['total_amount'] = '0.00';
      categoryData['created_at'] = now;
      categoryData['updated_at'] = now;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc(newCycleId)
          .collection('categories')
          .add(categoryData);
    }
  }

  Future<void> _copyAccountsFromLastCycle(
    Person user,
    String lastCycleId,
    String newCycleId,
    DateTime now,
  ) async {
    final accountsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(lastCycleId)
        .collection('accounts')
        .where('deleted_at', isNull: true)
        .getSavy();
    print('_copyAccountsFromLastCycle: ${accountsSnapshot.docs.length}');

    for (var doc in accountsSnapshot.docs) {
      final accountData = doc.data();
      accountData['opening_balance'] = accountData['amount_balance'];
      accountData['amount_received'] = '0.00';
      accountData['amount_spent'] = '0.00';
      accountData['created_at'] = now;
      accountData['updated_at'] = now;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc(newCycleId)
          .collection('accounts')
          .add(accountData);
    }
  }

  Future<void> updateCycleByAttribute(
    BuildContext context,
    String attribute,
    dynamic value,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .update({attribute: value});

    if (attribute == 'cycle_name') {
      cycle.cycleName = value;
    } else if (attribute == 'end_date') {
      cycle.endDate = value;
    }

    notifyListeners();
  }

  Future<void> updateCycleFromTransaction(
    BuildContext context,
    String action,
    String type,
    String amount,
    DateTime now,
    t.Transaction? transaction,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    final double cycleOpeningBalance = double.parse(cycle.openingBalance);
    double cycleAmountReceived = double.parse(cycle.amountReceived);
    double cycleAmountSpent = double.parse(cycle.amountSpent);

    //* Calculate the cycle's amounts before including this transaction
    if (action != 'Add' && transaction!.type != 'transfer') {
      if (transaction.type == 'spent') {
        cycleAmountSpent -= double.parse(transaction.amount);
      } else {
        cycleAmountReceived -= double.parse(transaction.amount);
      }
    }

    final newAmount = double.parse(amount);

    double updatedAmountBalance =
        cycleOpeningBalance + cycleAmountReceived - cycleAmountSpent;

    if (action != 'Delete' && type != 'transfer') {
      updatedAmountBalance += type == 'spent' ? -newAmount : newAmount;
      cycleAmountSpent += type == 'spent' ? newAmount : 0;
      cycleAmountReceived += type == 'received' ? newAmount : 0;
    }

    //* Update the cycle document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .update({
      'amount_spent': cycleAmountSpent.toStringAsFixed(2),
      'amount_received': cycleAmountReceived.toStringAsFixed(2),
      'amount_balance': updatedAmountBalance.toStringAsFixed(2),
      'updated_at': now,
    });
  }

  Future<void> updateCycleFromAccount(
    BuildContext context,
    String action,
    String amount,
    DateTime now,
    Account? account,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    double cycleOpeningBalance = double.parse(cycle.openingBalance);
    double cycleAmountBalance = double.parse(cycle.amountBalance);

    //* Calculate the cycle's amounts before including this account
    if (action != 'Add') {
      cycleOpeningBalance -= double.parse(account!.openingBalance);
      cycleAmountBalance -= double.parse(account.openingBalance);
    }

    final newAmount = double.parse(amount);
    print(newAmount);

    double updatedOpeningBalance = cycleOpeningBalance;
    double updatedAmountBalance = cycleAmountBalance;

    if (action != 'Delete') {
      updatedOpeningBalance += newAmount;
      updatedAmountBalance += newAmount;
    }

    //* Update the cycle document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .update({
      'opening_balance': updatedOpeningBalance.toStringAsFixed(2),
      'amount_balance': updatedAmountBalance.toStringAsFixed(2),
      'updated_at': now,
    });
  }
}
