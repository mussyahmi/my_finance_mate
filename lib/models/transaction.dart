// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/image_view_page.dart';

class Transaction {
  final String id;
  final String cycleId;
  final DateTime dateTime;
  final String type;
  final String categoryId;
  final String categoryName;
  final String amount;
  final String note;
  final List files;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.cycleId,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.note,
    required this.files,
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
                    MarkdownBody(
                      selectable: true,
                      data: note.replaceAll('\\n', '\n'),
                      onTapLink: (text, url, title) {
                        launchUrl(Uri.parse(url!));
                      },
                    ),
                  ],
                ),
              if (files.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Attachment:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var index = 0; index < files.length; index++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      //* Open a new screen with the larger image
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageViewPage(
                                            imageSource: files[index],
                                            type: 'url',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Image.network(
                                      files[index],
                                      height:
                                          100, //* Adjust the height as needed
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

                //* Fetch the transaction document
                final transactionDoc = await transactionRef.get();

                final data = transactionDoc.data();
                final files =
                    data!['files'] != null ? data['files'] as List : [];

                for (var file in files) {
                  deleteFile(Uri.decodeComponent(extractPathFromUrl(file)));
                }

                //* Update the 'deleted_at' field with the current timestamp
                final now = DateTime.now();
                transactionRef.update({
                  'files': [],
                  'updated_at': now,
                  'deleted_at': now,
                });

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
                          (type == 'spent' ? -double.parse(amount) : 0);

                  final double updatedAmountBalance = cycleOpeningBalance +
                      cycleAmountReceived -
                      cycleAmountSpent;

                  //* Update the cycle document
                  await cyclesRef.update({
                    'amount_spent': cycleAmountSpent.toStringAsFixed(2),
                    'amount_received': cycleAmountReceived.toStringAsFixed(2),
                    'amount_balance': updatedAmountBalance.toStringAsFixed(2),
                    'updated_at': now,
                  });
                }

                final categoryRef =
                    cyclesRef.collection('categories').doc(categoryId);

                //* Fetch the category document
                final categoryDoc = await categoryRef.get();

                if (categoryDoc.exists) {
                  final categoryData =
                      categoryDoc.data() as Map<String, dynamic>;

                  //* Calculate the updated amounts
                  final double totalAmount =
                      double.parse(categoryData['total_amount']) -
                          double.parse(amount);

                  //* Update the category document
                  await categoryRef.update({
                    'total_amount': totalAmount.toStringAsFixed(2),
                    'updated_at': now,
                  });
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

  static String extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);
    List<String> parts = uri.path.split('o/');

    //* Removing the first empty part and joining the rest
    return parts.sublist(1).join('/');
  }

  static void deleteFile(String filePath) async {
    Reference storageReference = FirebaseStorage.instance.ref().child(filePath);

    try {
      await storageReference.delete();
      print('File deleted successfully.');
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
