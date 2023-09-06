import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String cycleId;
  final DateTime dateTime;
  final String type;
  final String categoryId;
  final String categoryName;
  final String amount;
  final String note;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.cycleId,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.note,
  });

  void showTransactionSummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transaction Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(categoryName),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Date:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('EE, d MMM yyyy\nh:mm aa').format(dateTime),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('RM$amount'),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${type[0].toUpperCase()}${type.substring(1)}'),
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

  Future<bool> deleteTransaction(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); //* Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                //* Delete the item from Firestore here
                final transactionId = id;

                //* Reference to the Firestore document to delete
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  //todo: Handle the case where the user is not authenticated
                  return;
                }

                final userRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid);
                final transactionRef =
                    userRef.collection('transactions').doc(transactionId);

                //* Update the 'deleted_at' field with the current timestamp
                final now = DateTime.now();
                transactionRef.update({'deleted_at': now});

                final cyclesRef = userRef.collection('cycles').doc(cycleId);

                //* Fetch the current cycle document
                final cycleDoc = await cyclesRef.get();

                if (cycleDoc.exists) {
                  final cycleData = cycleDoc.data() as Map<String, dynamic>;

                  //* Calculate the updated amounts
                  final double cycleOpeningBalance =
                      double.parse(cycleData['opening_balance']);
                  final double cycleAmountReceived =
                      double.parse(cycleData['amount_received']) +
                          (type == 'received' ? -double.parse(amount) : 0);
                  final double cycleAmountSpent =
                      double.parse(cycleData['amount_spent']) +
                          ((type == 'spent' || type == 'saving')
                              ? -double.parse(amount)
                              : 0);

                  final double updatedAmountBalance = cycleOpeningBalance +
                      cycleAmountReceived -
                      cycleAmountSpent;

                  //* Update the cycle document
                  await cyclesRef.update({
                    'amount_spent': cycleAmountSpent.toStringAsFixed(2),
                    'amount_received': cycleAmountReceived.toStringAsFixed(2),
                    'amount_balance': updatedAmountBalance.toStringAsFixed(2),
                  });
                }

                if (type == 'spent') {
                  final categoryRef =
                      cyclesRef.collection('categories').doc(categoryId);

                  //* Fetch the category document
                  final categoryDoc = await categoryRef.get();

                  if (categoryDoc.exists) {
                    final categoryData =
                        categoryDoc.data() as Map<String, dynamic>;

                    //* Calculate the updated amounts
                    final double amountSpent =
                        double.parse(categoryData['amount_spent']) -
                            double.parse(amount);

                    //* Update the cycle document
                    await categoryRef.update({
                      'amount_spent': amountSpent.toStringAsFixed(2),
                    });
                  }
                }

                if (type == 'saving') {
                  final savingsRef =
                      userRef.collection('savings').doc(categoryId);

                  //* Fetch the category document
                  final savingDoc = await savingsRef.get();

                  if (savingDoc.exists) {
                    final savingData = savingDoc.data() as Map<String, dynamic>;

                    //* Calculate the updated amounts
                    final double amountReceived =
                        double.parse(savingData['amount_received']) -
                            double.parse(amount);

                    //* Update the cycle document
                    await savingsRef.update({
                      'amount_received': amountReceived.toStringAsFixed(2),
                    });
                  }
                }

                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(true); //* Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
