// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class Category {
  final String id;
  final String name;
  final String type;
  final String note;
  final String budget;
  final String totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.note,
    required this.budget,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  String amountBalance() {
    return (double.parse(budget) - double.parse(totalAmount))
        .toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(totalAmount) / double.parse(budget);
  }

  void showCategorySummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Category Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Name:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(name),
                ],
              ),
              if (budget.isNotEmpty && budget != '0.00')
                Column(
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Budget:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('RM$budget'),
                      ],
                    ),
                  ],
                ),
              if (totalAmount != '0.00')
                Column(
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('RM$totalAmount'),
                      ],
                    ),
                  ],
                ),
              if (note.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    MarkdownBody(
                      selectable: true,
                      data: note.replaceAll('\n', '\\\n'),
                      onTapLink: (text, url, title) {
                        launchUrl(Uri.parse(url!));
                      },
                    ),
                  ],
                ),
              //* Add more transaction details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); //* Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> hasTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return false;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionsSnapshot = await transactionsRef
        .where('category_id', isEqualTo: id)
        .where('deleted_at', isNull: true)
        .get();

    return transactionsSnapshot.docs.isNotEmpty;
  }

  static Future<void> updateCategoryNameForAllTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //* Handle the case where the user is not authenticated.
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionsSnapshot = await transactionsRef.get();

    print('initiate updateCategoryNameForAllTransactions');

    for (var doc in transactionsSnapshot.docs) {
      final data = doc.data();

      DocumentSnapshot<Map<String, dynamic>> categoryDoc;
      categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycle_id'])
          .collection('categories')
          .doc(data['category_id'])
          .get();

      final categoryName = categoryDoc['name'] as String;

      await transactionsRef.doc(doc.id).update({'category_name': categoryName});
    }

    print('done updateCategoryNameForAllTransactions');
  }

  static Future<void> recalculateCategoryTotalAmount(String cycleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //* Handle the case where the user is not authenticated.
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    final categoriesSnapshot = await categoriesRef.get();

    print('initiate recalculateCategoryTotalAmount');

    for (var doc in categoriesSnapshot.docs) {
      final transactionsRef = userRef.collection('transactions');

      final transactionsSnapshot = await transactionsRef
          .where('cycle_id', isEqualTo: cycleId)
          .where('category_id', isEqualTo: doc.id)
          .where('deleted_at', isNull: true)
          .get();

      double totalAmount = 0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();

        totalAmount += double.parse(data['amount']);
      }

      await categoriesRef
          .doc(doc.id)
          .update({'total_amount': totalAmount.toStringAsFixed(2)});
    }

    print('done recalculateCategoryTotalAmount');
  }

  static Future<List<Category>> fetchCategories(String cycleId, String? type,
      [bool isUniqueCategoryNames = false]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    Query<Map<String, dynamic>> query =
        categoriesRef.where('deleted_at', isNull: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    final categoriesSnapshot = await query.get();

    List<Category> fetchedCategories = categoriesSnapshot.docs
        .map((doc) => Category(
              id: doc.id,
              name: doc['name'],
              type: doc['type'],
              note: doc['note'],
              budget: doc['budget'],
              totalAmount: doc['total_amount'],
              createdAt: (doc['created_at'] as Timestamp).toDate(),
              updatedAt: (doc['updated_at'] as Timestamp).toDate(),
            ))
        .toList();

    if (isUniqueCategoryNames) {
      final Set<String> uniqueCategoryNames = {};
      final List<Category> filteredCategories = [];

      for (var doc in categoriesSnapshot.docs) {
        final categoryName = doc['name'] as String;
        if (!uniqueCategoryNames.contains(categoryName)) {
          uniqueCategoryNames.add(categoryName);

          final category = Category(
            id: doc.id,
            name: categoryName,
            type: doc['type'],
            note: doc['note'],
            budget: doc['budget'],
            totalAmount: doc['total_amount'],
            createdAt: (doc['created_at'] as Timestamp).toDate(),
            updatedAt: (doc['updated_at'] as Timestamp).toDate(),
          );

          filteredCategories.add(category);
        }
      }

      fetchedCategories = filteredCategories;
    }

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedCategories.sort((a, b) => (a.name).compareTo(b.name));

    return fetchedCategories;
  }
}
