import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String type;
  final String note;
  final String budget;
  final String amountSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.note,
    required this.budget,
    required this.amountSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  String amountBalance() {
    return (double.parse(budget) - double.parse(amountSpent))
        .toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(amountSpent) / double.parse(budget);
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
              if (note.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(note.replaceAll('\\n', '\n')),
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
}
