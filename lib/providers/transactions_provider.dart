// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../models/transaction.dart' as t;
import '../services/message_services.dart';
import 'accounts_provider.dart';
import 'categories_provider.dart';
import 'cycle_provider.dart';
import 'person_provider.dart';

class TransactionsProvider extends ChangeNotifier {
  List<t.Transaction>? transactions;

  TransactionsProvider({this.transactions});

  Future<void> fetchTransactions(BuildContext context, Cycle cycle,
      {bool? refresh}) async {
    final Person user = context.read<PersonProvider>().user!;

    var transactionQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('deleted_at', isNull: true)
        .where('date_time', isGreaterThanOrEqualTo: cycle.startDate)
        .where('date_time', isLessThanOrEqualTo: cycle.endDate)
        .orderBy('date_time', descending: true);

    final transactionSnapshot =
        await transactionQuery.getSavy(refresh: refresh);
    print('fetchTransactions: ${transactionSnapshot.docs.length}');

    final futureTransactions = transactionSnapshot.docs.map((doc) async {
      final data = doc.data();

      //* Create a Transaction object with the category name
      return t.Transaction(
        id: doc.id,
        cycleId: data['cycle_id'],
        dateTime: (data['date_time'] as Timestamp).toDate(),
        type: data['type'] as String,
        subType: data['category_id'] != null
            ? context
                .read<CategoriesProvider>()
                .getCategoryById(data['category_id'])
                .subType
            : null,
        categoryId: data['category_id'] ?? '',
        categoryName: data['category_id'] != null
            ? context
                .read<CategoriesProvider>()
                .getCategoryById(data['category_id'])
                .name
            : '',
        accountId: data['account_id'] ?? '',
        accountName: data['account_id'] != null
            ? context
                .read<AccountsProvider>()
                .getAccountById(data['account_id'])
                .name
            : '',
        accountToId: data['account_to_id'] ?? '',
        accountToName: data['account_to_id'] != null
            ? context
                .read<AccountsProvider>()
                .getAccountById(data['account_to_id'])
                .name
            : '',
        amount: data['amount'] as String,
        note: data['note'] as String,
        files: data['files'] != null ? data['files'] as List : [],
        createdAt: (data['created_at'] as Timestamp).toDate(),
      );
    }).toList();

    transactions = await Future.wait(futureTransactions);

    final List<t.Transaction> sortedTransactions =
        List<t.Transaction>.from(transactions!)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sortedTransactions.isNotEmpty) {
      context
          .read<PersonProvider>()
          .checkTransactionMade(sortedTransactions[0].createdAt);
    }

    notifyListeners();
  }

  Future<List<Object>> fetchFilteredTransactions(
    BuildContext context,
    DateTimeRange? selectedDateRange,
    String? selectedType,
    String? subType,
    String? selectedAccountId,
    String? selectedCategoryId,
    String? selectedAccountToId,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    List<t.Transaction> transferTransactions = [];
    List<t.Transaction> filteredTransactions = [];

    if (selectedDateRange != null) {
      // TODO: need to maintain later when want to use
      Query<Map<String, dynamic>> transactionQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('deleted_at', isNull: true);

      transactionQuery = transactionQuery
          .where('date_time', isGreaterThanOrEqualTo: selectedDateRange.start)
          .where('date_time', isLessThanOrEqualTo: selectedDateRange.end);

      if (subType != null) {
        transactionQuery = transactionQuery.where('type', isEqualTo: 'spent');

        if (subType != 'others') {
          transactionQuery =
              transactionQuery.where('subType', isEqualTo: subType);
        }
      } else {
        if (selectedType != null) {
          transactionQuery =
              transactionQuery.where('type', isEqualTo: selectedType);
        }

        if (selectedAccountId != null) {
          transactionQuery = transactionQuery.where('account_id',
              isEqualTo: selectedAccountId);
        }

        if (selectedCategoryId != null) {
          transactionQuery = transactionQuery.where('category_id',
              isEqualTo: selectedCategoryId);
        }

        if (selectedAccountToId != null) {
          transactionQuery = transactionQuery.where('account_to_id',
              isEqualTo: selectedAccountToId);
        }
      }

      final transactionSnapshot = await transactionQuery.getSavy();
      print('fetchFilteredTransactions: ${transactionSnapshot.docs.length}');

      for (var doc in transactionSnapshot.docs) {
        final data = doc.data();

        //* Map data to your Transaction class
        if (subType == 'others') {
          if (!data.containsKey('subType') || data['subType'] == null) {
            filteredTransactions = [
              ...filteredTransactions,
              t.Transaction(
                id: doc.id,
                cycleId: data['cycle_id'],
                dateTime: (data['date_time'] as Timestamp).toDate(),
                type: data['type'] as String,
                subType: data['subType'],
                categoryId: data['category_id'] ?? '',
                categoryName: data['category_id'] != null
                    ? context
                        .read<CategoriesProvider>()
                        .getCategoryById(data['category_id'])
                        .name
                    : '',
                accountId: data['account_id'] ?? '',
                accountName: data['account_id'] != null
                    ? context
                        .read<AccountsProvider>()
                        .getAccountById(data['account_id'])
                        .name
                    : '',
                accountToId: data['account_to_id'] ?? '',
                accountToName: data['account_to_id'] != null
                    ? context
                        .read<AccountsProvider>()
                        .getAccountById(data['account_to_id'])
                        .name
                    : '',
                amount: data['amount'] as String,
                note: data['note'] as String,
                files: data['files'] != null ? data['files'] as List : [],
                createdAt: (data['created_at'] as Timestamp).toDate(),
              )
            ];
          }
        } else {
          filteredTransactions = [
            ...filteredTransactions,
            t.Transaction(
              id: doc.id,
              cycleId: data['cycle_id'],
              dateTime: (data['date_time'] as Timestamp).toDate(),
              type: data['type'] as String,
              subType: data['subType'],
              categoryId: data['category_id'] ?? '',
              categoryName: data['category_id'] != null
                  ? context
                      .read<CategoriesProvider>()
                      .getCategoryById(data['category_id'])
                      .name
                  : '',
              accountId: data['account_id'] ?? '',
              accountName: data['account_id'] != null
                  ? context
                      .read<AccountsProvider>()
                      .getAccountById(data['account_id'])
                      .name
                  : '',
              accountToId: data['account_to_id'] ?? '',
              accountToName: data['account_to_id'] != null
                  ? context
                      .read<AccountsProvider>()
                      .getAccountById(data['account_to_id'])
                      .name
                  : '',
              amount: data['amount'] as String,
              note: data['note'] as String,
              files: data['files'] != null ? data['files'] as List : [],
              createdAt: (data['created_at'] as Timestamp).toDate(),
            )
          ];
        }
      }
    } else {
      Iterable<t.Transaction> queryTranfer = [];
      Iterable<t.Transaction> query = transactions!;

      if (subType != null) {
        query = query.where((transaction) => transaction.type == 'spent');

        if (subType != 'others') {
          query = query.where((transaction) => transaction.subType == subType);
        } else {
          query = query.where((transaction) =>
              transaction.subType != 'needs' &&
              transaction.subType != 'wants' &&
              transaction.subType != 'savings');
        }
      } else {
        if (selectedType != null) {
          if (selectedType == 'received' && selectedAccountId != null) {
            queryTranfer = query.where((transaction) =>
                transaction.accountToId == selectedAccountId &&
                transaction.type == 'transfer');
          }

          query =
              query.where((transaction) => transaction.type == selectedType);
        }

        if (selectedAccountId != null) {
          query = query.where(
              (transaction) => transaction.accountId == selectedAccountId);
        }

        if (selectedCategoryId != null) {
          query = query.where(
              (transaction) => transaction.categoryId == selectedCategoryId);
        }

        if (selectedAccountToId != null) {
          query = query.where(
              (transaction) => transaction.accountToId == selectedAccountToId);
        }
      }

      transferTransactions = queryTranfer.toList();
      filteredTransactions = query.toList();
    }

    var result = (transferTransactions + filteredTransactions).toSet().toList();

    //* Sort the list as needed
    result.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return result;
  }

  Future<List<Object>> getLatestTransactions(BuildContext context) async {
    if (transactions == null) return [];

    return transactions!.take(10).toList();
  }

  bool hasCategory(String categoryId) {
    return transactions!
        .any((transaction) => transaction.categoryId == categoryId);
  }

  bool hasAccount(String accountId) {
    return transactions!
        .any((transaction) => transaction.accountId == accountId);
  }

  t.Transaction getTransactionById(transactionId) {
    return transactions!.firstWhere((account) => account.id == transactionId);
  }

  Future<void> updateTransaction(
    BuildContext context,
    String action,
    DateTime dateTime,
    String type,
    String? categoryId,
    String accountId,
    String? accountToId,
    String amount,
    String note,
    List<dynamic> files,
    List<dynamic> filesToDelete,
    t.Transaction? transaction,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    //* Get current timestamp
    final now = DateTime.now();

    try {
      List downloadURLs =
          await _uploadAndDeleteFiles(user, action, files, filesToDelete);

      if (action == 'Add') {
        //* Create a new transaction document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .add({
          'cycle_id': cycle.id,
          'date_time': dateTime,
          'type': type,
          'account_id': accountId,
          'account_to_id': accountToId,
          'category_id': categoryId,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'files': downloadURLs,
        });

        //* Update transactions made
        if (!user.isPremium) {
          final int newDailyTransactionsMade = user.dailyTransactionsMade + 1;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'daily_transactions_made': newDailyTransactionsMade});

          user.dailyTransactionsMade = newDailyTransactionsMade;
        }
      } else if (action == 'Edit') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc(transaction!.id)
            .update({
          'date_time': dateTime,
          'type': type,
          'account_id': accountId,
          'account_to_id': accountToId,
          'category_id': categoryId,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'updated_at': now,
          'files': downloadURLs,
        });
      }

      if (!(action != 'Add' &&
          transaction!.type == 'transfer' &&
          type == 'transfer')) {
        //* Update cycle's data
        await context.read<CycleProvider>().updateCycleFromTransaction(
            context, action, type, amount, now, transaction);

        //* Update category's data
        await context.read<CategoriesProvider>().updateCategoryFromTransaction(
            context, action, type, categoryId, amount, now, transaction);
      }

      //* Update account's data
      await context.read<AccountsProvider>().updateAccountFromTransaction(
            context,
            action,
            type,
            amount,
            now,
            transaction,
            accountId,
            accountToId,
          );

      final MessageService messageService = MessageService();

      EasyLoading.showSuccess(action == 'Edit'
          ? messageService.getRandomDoneUpdateMessage()
          : messageService.getRandomDoneAddMessage());

      await context.read<CycleProvider>().fetchCycle(context);
      await context.read<CategoriesProvider>().fetchCategories(context, cycle);
      await context.read<AccountsProvider>().fetchAccounts(context, cycle);
      await context
          .read<TransactionsProvider>()
          .fetchTransactions(context, cycle);

      notifyListeners();
    } catch (e) {
      //* Handle any errors that occur during the Firestore operation
      print('Error $action transaction: $e');
      //* You can show an error message to the user if needed
    }
  }

  Future<List> _uploadAndDeleteFiles(
    Person user,
    String action,
    List<dynamic> files,
    List<dynamic> filesToDelete,
  ) async {
    List downloadURLs = [];

    for (var file in files) {
      if (file is! String) {
        //* Generate a unique file name
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('${user.uid}/transactions/$fileName');

        UploadTask uploadTask = storageReference.putFile(File(file.path!));

        await uploadTask.whenComplete(() async {
          print('File Uploaded');
          String downloadURL = await storageReference.getDownloadURL();
          print('Download URL: $downloadURL');
          downloadURLs = [...downloadURLs, downloadURL];
        });
      } else {
        //* for existing file
        downloadURLs = [...downloadURLs, file];
      }
    }

    if (action == 'Edit') {
      for (var fileToDelete in filesToDelete) {
        t.Transaction.deleteFile(Uri.decodeComponent(
            t.Transaction.extractPathFromUrl(fileToDelete)));
      }
    }

    return downloadURLs;
  }

  Future<void> deleteTransaction(
    BuildContext context,
    String transactionId,
  ) async {
    final Person user = context.read<PersonProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    final t.Transaction trans = getTransactionById(transactionId);

    for (var file in trans.files) {
      t.Transaction.deleteFile(
          Uri.decodeComponent(t.Transaction.extractPathFromUrl(file)));
    }

    //* Update the 'deleted_at' field with the current timestamp
    final now = DateTime.now();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(transactionId)
        .update({
      'files': [],
      'updated_at': now,
      'deleted_at': now,
    });

    if (trans.type != 'transfer') {
      //* Update cycle's data
      await context.read<CycleProvider>().updateCycleFromTransaction(
            context,
            'Delete',
            trans.type,
            trans.amount,
            now,
            trans,
          );

      //* Update category's data
      await context.read<CategoriesProvider>().updateCategoryFromTransaction(
            context,
            'Delete',
            trans.type,
            trans.categoryId,
            trans.amount,
            now,
            trans,
          );
    }

    //* Update account's data
    await context.read<AccountsProvider>().updateAccountFromTransaction(
          context,
          'Delete',
          trans.type,
          trans.amount,
          now,
          trans,
          trans.accountId,
          trans.accountToId,
        );

    final MessageService messageService = MessageService();

    EasyLoading.showSuccess(messageService.getRandomDoneDeleteMessage());

    await context.read<CycleProvider>().fetchCycle(context);
    await context.read<CategoriesProvider>().fetchCategories(context, cycle);
    await context.read<AccountsProvider>().fetchAccounts(context, cycle);
    await context
        .read<TransactionsProvider>()
        .fetchTransactions(context, cycle);

    notifyListeners();
  }

  Future<List<t.Transaction>> fetchTransactionsWithAttachmentsFromCycle(
      BuildContext context, Cycle cycle) async {
    final Person user = context.read<PersonProvider>().user!;

    var transactionQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('deleted_at', isNull: true)
        .where('date_time', isGreaterThanOrEqualTo: cycle.startDate)
        .where('date_time', isLessThanOrEqualTo: cycle.endDate)
        .where('files', isNotEqualTo: []).orderBy('date_time',
            descending: true);

    final transactionSnapshot = await transactionQuery.getSavy(refresh: true);
    print('fetchTransactions: ${transactionSnapshot.docs.length}');

    final futureTransactions = transactionSnapshot.docs.map((doc) async {
      final data = doc.data();

      Category? category;
      Account? account;
      Account? accountTo;

      if (data['category_id'] != null) {
        category = await context
            .read<CategoriesProvider>()
            .fetchCategoryByIdFromCycle(context, cycle, data['category_id']);
      }

      if (data['account_id'] != null) {
        account = await context
            .read<AccountsProvider>()
            .fetchAccountByIdFromCycle(context, cycle, data['account_id']);
      }

      if (data['account_to_id'] != null) {
        accountTo = await context
            .read<AccountsProvider>()
            .fetchAccountByIdFromCycle(context, cycle, data['account_to_id']);
      }

      //* Create a Transaction object with the category name
      return t.Transaction(
        id: doc.id,
        cycleId: data['cycle_id'],
        dateTime: (data['date_time'] as Timestamp).toDate(),
        type: data['type'] as String,
        subType: data['category_id'] != null ? category!.subType : null,
        categoryId: data['category_id'] ?? '',
        categoryName: data['category_id'] != null ? category!.name : '',
        accountId: data['account_id'] ?? '',
        accountName: data['account_id'] != null ? account!.name : '',
        accountToId: data['account_to_id'] ?? '',
        accountToName: data['account_to_id'] != null ? accountTo!.name : '',
        amount: data['amount'] as String,
        note: data['note'] as String,
        files: data['files'] != null ? data['files'] as List : [],
        createdAt: (data['created_at'] as Timestamp).toDate(),
      );
    }).toList();

    final trans = await Future.wait(futureTransactions);

    return List<t.Transaction>.from(trans)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // i want to transform transaction list to json that i can copy to paste to chatgpt
  List<Map<String, dynamic>> toJson() {
    if (transactions == null) return [];

    return transactions!.map((transaction) => transaction.toJson()).toList();
  }
}
