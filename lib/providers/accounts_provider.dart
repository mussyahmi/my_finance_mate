// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/account.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../models/transaction.dart' as t;
import 'categories_provider.dart';
import 'cycle_provider.dart';
import 'person_provider.dart';

class AccountsProvider extends ChangeNotifier {
  List<Account>? accounts;

  AccountsProvider({this.accounts});

  Future<void> fetchAccounts(BuildContext context, Cycle cycle,
      {bool? refresh}) async {
    final Person user = context.read<PersonProvider>().user!;

    final accountsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .collection('accounts')
        .where('deleted_at', isNull: true)
        .orderBy('name')
        .getSavy(refresh: refresh);
    print('fetchAccounts: ${accountsSnapshot.docs.length}');

    accounts = accountsSnapshot.docs.map((doc) {
      return Account(
        id: doc.id,
        name: doc['name'],
        openingBalance: doc['opening_balance'],
        amountBalance: doc['amount_balance'],
        amountReceived: doc['amount_received'],
        amountSpent: doc['amount_spent'],
        cycleId: cycle.id,
        isExcluded:
            doc.data().containsKey('is_excluded') ? doc['is_excluded'] : false,
      );
    }).toList();

    notifyListeners();
  }

  Future<List<Object>> getAccounts(BuildContext context) async {
    if (accounts == null) return [];

    return accounts!;
  }

  List<Account> getFilteredAccountsByName(
      BuildContext context, String accountName) {
    if (accounts == null) return [];

    return accounts!
        .where((account) =>
            account.name.toLowerCase().contains(accountName.toLowerCase()))
        .toList();
  }

  Account getAccountById(accountId) {
    return accounts!.firstWhere((account) => account.id == accountId);
  }

  Account getAccountByName(accountName) {
    return accounts!.firstWhere((account) => account.name == accountName);
  }

  Future<void> updateAccount(BuildContext context, String action, String name,
      String openingBalance, bool isExcluded,
      {Account? account}) async {
    try {
      final Person user = context.read<PersonProvider>().user!;
      final Cycle cycle = context.read<CycleProvider>().cycle!;

      //* Get current timestamp
      final now = DateTime.now();

      if (action == 'Add') {
        //* Create the new account document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(cycle.id)
            .collection('accounts')
            .add({
          'name': name,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'opening_balance': openingBalance,
          'amount_balance': openingBalance,
          'amount_received': '0.00',
          'amount_spent': '0.00',
          'is_excluded': isExcluded,
        });
      } else if (action == 'Edit') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(cycle.id)
            .collection('accounts')
            .doc(account!.id)
            .update({
          'name': name,
          'opening_balance': openingBalance,
          'amount_balance': (double.parse(account.amountBalance) -
                  double.parse(account.openingBalance) +
                  double.parse(openingBalance))
              .toStringAsFixed(2),
          'updated_at': now,
          'is_excluded': isExcluded,
        });
      }

      //* Update cycle's data
      await context.read<CycleProvider>().updateCycleFromAccount(
          context, action, openingBalance, now, account);

      await context.read<CycleProvider>().fetchCycle(context);
      await context.read<AccountsProvider>().fetchAccounts(context, cycle);

      notifyListeners();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      print('Error $action account: $e');
    }
  }

  Future<void> updateAccountFromTransaction(
    BuildContext context,
    String action,
    String type,
    String amount,
    DateTime now,
    t.Transaction? transaction,
    String accountId,
    String? accountToId,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;
    late Map<String, double> result;

    final Account account = getAccountById(accountId);
    late Account accountTo;

    double accountAmountBalance = double.parse(account.amountBalance);
    double accountAmountSpent = double.parse(account.amountSpent);
    double accountAmountReceived = double.parse(account.amountReceived);

    if (action != 'Add') {
      result = await _updatePrevAccountFromTransaction(
        user,
        cycle,
        action,
        transaction!,
      );

      //* before from same after from
      if (transaction.accountId == accountId) {
        //cash==general
        accountAmountBalance = result['prevAccountAmountBalance']!;
        accountAmountSpent = result['prevAccountAmountSpent']!;
        accountAmountReceived = result['prevAccountAmountReceived']!;
      }

      //* before to same after from
      if (transaction.type == 'transfer' &&
          transaction.accountToId == accountId) {
        //false
        accountAmountBalance = result['prevAccountToAmountBalance']!;
        accountAmountReceived = result['prevAccountToAmountReceived']!;
      }
    }

    late double accountToAmountBalance;
    late double accountToAmountReceived;

    if (type == 'transfer') {
      accountTo = getAccountById(accountToId);

      accountToAmountBalance = double.parse(accountTo.amountBalance);
      accountToAmountReceived = double.parse(accountTo.amountReceived);

      if (action != 'Add') {
        //* before from same after to
        if (transaction!.accountId == accountToId) {
          accountToAmountBalance = result['prevAccountAmountBalance']!;
          accountToAmountReceived = result['prevAccountAmountReceived']!;
        }

        //* before to same after to
        if (transaction.type == 'transfer' &&
            transaction.accountToId == accountToId) {
          accountToAmountBalance = result['prevAccountToAmountBalance']!;
          accountToAmountReceived = result['prevAccountToAmountReceived']!;
        }
      }
    }

    if (action != 'Delete') {
      if (type == 'spent') {
        accountAmountBalance -= double.parse(amount);
        accountAmountSpent += double.parse(amount);
      } else if (type == 'received') {
        accountAmountBalance += double.parse(amount);
        accountAmountReceived += double.parse(amount);
      } else if (type == 'transfer') {
        accountAmountBalance -= double.parse(amount);
        accountAmountReceived -= double.parse(amount);

        accountToAmountBalance += double.parse(amount);
        accountToAmountReceived += double.parse(amount);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc(cycle.id)
          .collection('accounts')
          .doc(accountId)
          .update({
        'amount_balance': accountAmountBalance.toStringAsFixed(2),
        'amount_spent': accountAmountSpent.toStringAsFixed(2),
        'amount_received': accountAmountReceived.toStringAsFixed(2),
      });

      if (type == 'transfer') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(cycle.id)
            .collection('accounts')
            .doc(accountToId)
            .update({
          'amount_balance': accountToAmountBalance.toStringAsFixed(2),
          'amount_received': accountToAmountReceived.toStringAsFixed(2),
        });
      }
    }
  }

  Future<Map<String, double>> _updatePrevAccountFromTransaction(
    Person user,
    Cycle cycle,
    String action,
    t.Transaction transaction,
  ) async {
    final Account account = getAccountById(transaction.accountId);
    late Account accountTo;

    double prevAccountAmountBalance = double.parse(account.amountBalance);
    double prevAccountAmountSpent = double.parse(account.amountSpent);
    double prevAccountAmountReceived = double.parse(account.amountReceived);

    late double prevAccountToAmountBalance;
    late double prevAccountToAmountReceived;

    if (transaction.type == 'transfer') {
      accountTo = getAccountById(transaction.accountToId);

      prevAccountToAmountBalance = double.parse(accountTo.amountBalance);
      prevAccountToAmountReceived = double.parse(accountTo.amountReceived);
    }

    if (transaction.type == 'spent') {
      prevAccountAmountBalance += double.parse(transaction.amount);
      prevAccountAmountSpent -= double.parse(transaction.amount);
    } else if (transaction.type == 'received') {
      prevAccountAmountBalance -= double.parse(transaction.amount);
      prevAccountAmountReceived -= double.parse(transaction.amount);
    } else if (transaction.type == 'transfer') {
      prevAccountAmountBalance += double.parse(transaction.amount);
      prevAccountAmountReceived += double.parse(transaction.amount);

      prevAccountToAmountBalance -= double.parse(transaction.amount);
      prevAccountToAmountReceived -= double.parse(transaction.amount);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .collection('accounts')
        .doc(transaction.accountId)
        .update({
      'amount_balance': prevAccountAmountBalance.toStringAsFixed(2),
      'amount_spent': prevAccountAmountSpent.toStringAsFixed(2),
      'amount_received': prevAccountAmountReceived.toStringAsFixed(2),
    });

    if (transaction.type == 'transfer') {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc(cycle.id)
          .collection('accounts')
          .doc(transaction.accountToId)
          .update({
        'amount_balance': prevAccountToAmountBalance.toStringAsFixed(2),
        'amount_received': prevAccountToAmountReceived.toStringAsFixed(2),
      });
    }

    return {
      'prevAccountAmountBalance': prevAccountAmountBalance,
      'prevAccountAmountSpent': prevAccountAmountSpent,
      'prevAccountAmountReceived': prevAccountAmountReceived,
      if (transaction.type == 'transfer')
        'prevAccountToAmountBalance': prevAccountToAmountBalance,
      if (transaction.type == 'transfer')
        'prevAccountToAmountReceived': prevAccountToAmountReceived,
    };
  }

  Future<void> deleteAccount(
    BuildContext context,
    Account account,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    //* Update the 'deleted_at' field with the current timestamp
    final now = DateTime.now();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .collection('accounts')
        .doc(account.id)
        .update({
      'updated_at': now,
      'deleted_at': now,
    });

    accounts!.removeWhere((acc) => acc.id == account.id);

    //* Update cycle's data
    await context.read<CycleProvider>().updateCycleFromAccount(
        context, 'Delete', account.openingBalance, now, account);

    await context.read<CycleProvider>().fetchCycle(context);

    notifyListeners();
  }

  Future<void> migrateAccountFeature(BuildContext context) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    //* Get current timestamp
    final now = DateTime.now();

    //* Create the new account document
    final newAccountDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .collection('accounts')
        .add({
      'name': 'General',
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'opening_balance': cycle.openingBalance,
      'amount_balance': cycle.amountBalance,
      'amount_received': cycle.amountReceived,
      'amount_spent': cycle.amountSpent,
    });

    //* Query the transactions within the cycle dates
    var transactionSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('deleted_at', isNull: true)
        .where('date_time', isGreaterThanOrEqualTo: cycle.startDate)
        .where('date_time', isLessThanOrEqualTo: cycle.endDate)
        .orderBy('date_time', descending: true)
        .getSavy();
    print('migrateAccountFeature: ${transactionSnapshot.docs.length}');

    //* Iterate over each transaction and add the new "account_id" field
    for (var doc in transactionSnapshot.docs) {
      await doc.reference.update({
        'account_id': newAccountDoc.id,
        'account_to_id': null,
      });
    }

    await context.read<CategoriesProvider>().fetchCategories(context, cycle);
    await context.read<AccountsProvider>().fetchAccounts(context, cycle);

    notifyListeners();
  }
}
