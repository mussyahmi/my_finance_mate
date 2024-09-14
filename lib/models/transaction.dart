// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/image_view_page.dart';
import '../pages/transaction_form_page.dart';
import '../size_config.dart';
import 'cycle.dart';
import '../extensions/string_extension.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import '../extensions/firestore_extensions.dart';
import 'person.dart';

class Transaction {
  final String id;
  final String cycleId;
  final DateTime dateTime;
  final String type;
  final String? subType;
  final String categoryId;
  final String categoryName;
  final String amount;
  final String note;
  final List files;
  final Person person;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.cycleId,
    required this.type,
    required this.subType,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.note,
    required this.files,
    required this.person,
  });

  static Future<List<Transaction>> fetchTransactions(
    Person user,
    int? limit,
  ) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    var transactionQuery = transactionsRef
        .where('deleted_at', isNull: true)
        .orderBy('date_time', descending: true);

    if (limit != null) {
      transactionQuery = transactionQuery.limit(limit);
    }

    final transactionSnapshot = await transactionQuery.getSavy();

    final transactions = transactionSnapshot.docs.map((doc) async {
      final data = doc.data();

      //* Fetch the category name based on the categoryId
      DocumentSnapshot<Map<String, dynamic>> categoryDoc;
      categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycle_id'])
          .collection('categories')
          .doc(data['category_id'])
          .getSavy();

      final categoryName = categoryDoc['name'] as String;

      //* Create a Transaction object with the category name
      return Transaction(
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
      );
    }).toList();

    var result = await Future.wait(transactions);

    return result;
  }

  static Future<List<Transaction>> fetchFilteredTransactions(
    Person user,
    DateTimeRange? selectedDateRange,
    String? selectedType,
    String? subType,
    String? selectedCategoryName,
  ) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    Query<Map<String, dynamic>> transactionQuery =
        transactionsRef.where('deleted_at', isNull: true);

    if (selectedDateRange != null) {
      transactionQuery = transactionQuery
          .where('date_time', isGreaterThanOrEqualTo: selectedDateRange.start)
          .where('date_time', isLessThanOrEqualTo: selectedDateRange.end);
    }

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

    List<Transaction> transactions = [];

    for (var doc in transactionSnapshot.docs) {
      final data = doc.data();

      //* Fetch the category name based on the categoryId
      DocumentSnapshot<Map<String, dynamic>> categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycle_id'])
          .collection('categories')
          .doc(data['category_id'])
          .getSavy();

      final categoryName = categoryDoc['name'] as String;

      //* Map data to your Transaction class
      if (subType == 'others') {
        if (!data.containsKey('subType') || data['subType'] == null) {
          transactions = [
            ...transactions,
            Transaction(
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
        transactions = [
          ...transactions,
          Transaction(
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
    // }).toList();

    var result = transactions;

    //* Sort the list as needed
    result.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return result;
  }

  void showTransactionDetails(
      BuildContext context, Person user, Function onTransactionChanged) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CustomDraggableScrollableSheet(
          initialSize: 0.65,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () async {
                      final result = await deleteTransaction(context, user);

                      if (result) {
                        Navigator.of(context).pop();
                        onTransactionChanged();
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final transactionCycle = await cycle(user);

                      //* Edit action
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionFormPage(
                            user: person,
                            cycle: transactionCycle!,
                            action: 'Edit',
                            transaction: this,
                          ),
                        ),
                      );

                      if (result) {
                        Navigator.of(context).pop();
                        onTransactionChanged();
                      }
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              )
            ],
          ),
          contents: Column(
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
                  Text(
                      '${type.capitalize()}${subType != null ? ' (${subType!.capitalize()})' : ''}'),
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
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: SizeConfig.screenHeight! * 0.2,
                      ),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          selectable: true,
                          data: note.replaceAll('\n', '  \n'),
                          onTapLink: (text, url, title) {
                            launchUrl(Uri.parse(url!));
                          },
                        ),
                      ),
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
            ],
          ),
        );
      },
    );
  }

  Future<bool> deleteTransaction(BuildContext context, Person user) async {
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

                final userRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid);
                final transactionRef =
                    userRef.collection('transactions').doc(transactionId);

                //* Fetch the transaction document
                final transactionDoc = await transactionRef.getSavy();

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
                final cycleDoc = await cyclesRef.getSavy();

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
                final categoryDoc = await categoryRef.getSavy();

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

  Future<Cycle?> cycle(Person user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cycleRef = userRef.collection('cycles').doc(cycleId);

    final cycleDoc = await cycleRef.getSavy();

    if (cycleDoc.exists) {
      final Map<String, dynamic> data = cycleDoc.data()!;

      return Cycle(
        id: cycleDoc.id,
        cycleNo: data['cycle_no'],
        cycleName: data['cycle_name'],
        openingBalance: data['opening_balance'],
        amountBalance: data['amount_balance'],
        amountReceived: data['amount_received'],
        amountSpent: data['amount_spent'],
        startDate: (data['start_date'] as Timestamp).toDate(),
        endDate: (data['end_date'] as Timestamp).toDate(),
      );
    }

    return null;
  }
}
