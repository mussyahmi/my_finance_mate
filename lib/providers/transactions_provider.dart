// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../models/transaction.dart' as t;
import '../services/ad_mob_service.dart';
import 'categories_provider.dart';
import 'cycle_provider.dart';
import 'user_provider.dart';

class TransactionsProvider extends ChangeNotifier {
  List<t.Transaction>? transactions;

  TransactionsProvider({this.transactions});

  Future<void> fetchTransactions(BuildContext context, Cycle cycle,
      {bool? refresh}) async {
    final Person user = context.read<UserProvider>().user!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    var transactionQuery = transactionsRef
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
        subType: data['subType'],
        categoryId: data['category_id'],
        categoryName: data['category_name'],
        amount: data['amount'] as String,
        note: data['note'] as String,
        files: data['files'] != null ? data['files'] as List : [],
        person: user,
      );
    }).toList();

    transactions = await Future.wait(futureTransactions);
    notifyListeners();
  }

  Future<List<t.Transaction>> fetchFilteredTransactions(
    BuildContext context,
    DateTimeRange? selectedDateRange,
    String? selectedType,
    String? subType,
    String? selectedCategoryName,
  ) async {
    final Person user = context.read<UserProvider>().user!;
    List<t.Transaction> filteredTransactions = [];

    if (selectedDateRange != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final transactionsRef = userRef.collection('transactions');

      Query<Map<String, dynamic>> transactionQuery =
          transactionsRef.where('deleted_at', isNull: true);

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

        if (selectedCategoryName != null) {
          transactionQuery = transactionQuery.where('category_name',
              isEqualTo: selectedCategoryName);
        }
      }

      final transactionSnapshot = await transactionQuery.getSavy();
      print('fetchFilteredTransactions: ${transactionSnapshot.docs.length}');

      for (var doc in transactionSnapshot.docs) {
        final data = doc.data();

        //* Fetch the category name based on the categoryId
        DocumentSnapshot<Map<String, dynamic>> categoryDoc = await userRef
            .collection('cycles')
            .doc(data['cycle_id'])
            .collection('categories')
            .doc(data['category_id'])
            .getSavy();
        print('fetchFilteredTransactions - categoryDoc: 1');

        final categoryName = categoryDoc['name'] as String;

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
                categoryId: data['category_id'],
                categoryName: categoryName,
                amount: data['amount'] as String,
                note: data['note'] as String,
                files: data['files'] != null ? data['files'] as List : [],
                person: user,
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
              categoryId: data['category_id'],
              categoryName: categoryName,
              amount: data['amount'] as String,
              note: data['note'] as String,
              files: data['files'] != null ? data['files'] as List : [],
              person: user,
            )
          ];
        }
      }
    } else {
      Iterable<t.Transaction> query = transactions!;

      if (subType != null) {
        query =
            transactions!.where((transaction) => transaction.type == 'spent');

        if (subType != 'others') {
          query = transactions!
              .where((transaction) => transaction.subType == subType);
        }
      } else {
        if (selectedType != null) {
          query = transactions!
              .where((transaction) => transaction.type == selectedType);
        }

        if (selectedCategoryName != null) {
          query = transactions!.where((transaction) =>
              transaction.categoryName == selectedCategoryName);
        }
      }

      filteredTransactions = query.toList();
    }

    var result = filteredTransactions;

    //* Sort the list as needed
    result.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return result;
  }

  Future<List<t.Transaction>> getLatestTransactions() async {
    if (transactions == null) return [];

    return transactions!.take(10).toList();
  }

  bool hasCategory(String categoryId) {
    return transactions!
        .any((transaction) => transaction.categoryId == categoryId);
  }

  Future<void> updateTransaction(
    BuildContext context,
    String action,
    DateTime dateTime,
    String type,
    String? subType,
    String categoryId,
    String amount,
    String note,
    List<dynamic> files,
    List<dynamic> filesToDelete,
    t.Transaction? transaction,
  ) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;
    final List<Category> categories =
        context.read<CategoriesProvider>().categories!;

    //* Get current timestamp
    final now = DateTime.now();

    try {
      //* Reference to the Firestore document to add the transaction
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final transactionsRef = userRef.collection('transactions');

      List downloadURLs =
          await _uploadAndDeleteFiles(user, action, files, filesToDelete);

      if (action == 'Add') {
        //* Create a new transaction document
        await transactionsRef.add({
          'cycle_id': cycle.id,
          'date_time': dateTime,
          'type': type,
          'subType': type == 'spent' ? subType : null,
          'category_id': categoryId,
          'category_name': categories
              .firstWhere((category) => category.id == categoryId)
              .name,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
          'files': downloadURLs,
        });

        //* Update transactions made
        final adMobService = context.read<AdMobService>();

        if (adMobService.status) {
          await userRef.update(
              {'daily_transactions_made': user.dailyTransactionsMade + 1});
        }
      } else if (action == 'Edit') {
        await transactionsRef.doc(transaction!.id).update({
          'date_time': dateTime,
          'type': type,
          'subType': type == 'spent' ? subType : null,
          'category_id': categoryId,
          'category_name': categories
              .firstWhere((category) => category.id == categoryId)
              .name,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'updated_at': now,
          'files': downloadURLs,
        });
      }

      //* Update cycle's data
      await context.read<CycleProvider>().updateCycleFromTransaction(
          context, action, type, amount, now, transaction);

      //* Update category's data
      await context.read<CategoriesProvider>().updateCategoryFromTransaction(
          context, action, categoryId, amount, now, transaction);

      await context.read<CycleProvider>().fetchCycle(context);
      await context.read<CategoriesProvider>().fetchCategories(context, cycle);
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
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionRef =
        userRef.collection('transactions').doc(transactionId);

    final t.Transaction trans = transactions!
        .firstWhere((transaction) => transaction.id == transactionId);

    for (var file in trans.files) {
      t.Transaction.deleteFile(
          Uri.decodeComponent(t.Transaction.extractPathFromUrl(file)));
    }

    //* Update the 'deleted_at' field with the current timestamp
    final now = DateTime.now();
    transactionRef.update({
      'files': [],
      'updated_at': now,
      'deleted_at': now,
    });

    //* Update cycle's data
    await context.read<CycleProvider>().updateCycleFromTransaction(
        context, 'Delete', trans.type, trans.amount, now, trans);

    await context.read<CategoriesProvider>().updateCategoryFromTransaction(
        context, 'Delete', trans.categoryId, trans.amount, now, trans);

    await context.read<CycleProvider>().fetchCycle(context);
    await context.read<CategoriesProvider>().fetchCategories(context, cycle);
    await context
        .read<TransactionsProvider>()
        .fetchTransactions(context, cycle);

    notifyListeners();
  }
}
