// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'category_list_page.dart';
import 'image_view_page.dart';
import 'savings_page.dart';
import '../models/transaction.dart' as t;

class TransactionFormPage extends StatefulWidget {
  final String cycleId;
  final String action;
  final t.Transaction? transaction;
  const TransactionFormPage(
      {super.key,
      required this.cycleId,
      required this.action,
      this.transaction});

  @override
  TransactionFormPageState createState() => TransactionFormPageState();
}

class TransactionFormPageState extends State<TransactionFormPage> {
  String selectedType = 'spent';
  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  TextEditingController transactionAmountController = TextEditingController();
  TextEditingController transactionNoteController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  bool _isLoading = false;
  List<dynamic> files = [];
  List<dynamic> filesToDelete = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    await _fetchCategories();

    if (widget.transaction != null) {
      selectedType = widget.transaction!.type;
      transactionAmountController.text = widget.transaction!.amount;
      transactionNoteController.text =
          widget.transaction!.note.replaceAll('\\n', '\n');
      selectedDateTime = widget.transaction!.dateTime;
      files = widget.transaction!.files;

      await _fetchCategories();

      selectedCategoryId = widget.transaction!.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.action} Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime(2000), //todo: cycle's start date
                    lastDate: DateTime(2101), //todo: cycle's end date
                  );
                  if (selectedDate != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (selectedTime != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(
                  'Date Time: ${DateFormat('EE, d MMM yyyy h:mm aa').format(selectedDateTime)}',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                onChanged: (newValue) {
                  setState(() {
                    selectedType = newValue as String;
                    selectedCategoryId = null;
                  });

                  _fetchCategories();
                },
                items: ['spent', 'received', 'saving']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                              '${type[0].toUpperCase()}${type.substring(1)}'),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                onChanged: (newValue) async {
                  setState(() {
                    selectedCategoryId = newValue;
                  });

                  if (newValue == 'add_new') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        if (selectedType != 'saving') {
                          return CategoryListPage(
                            cycleId: widget.cycleId,
                            type: selectedType,
                            isFromTransactionForm: true,
                          );
                        } else {
                          return const SavingsPage(
                            isFromTransactionForm: true,
                          );
                        }
                      }),
                    );

                    setState(() {
                      selectedCategoryId = null;
                    });

                    _fetchCategories();
                  }
                },
                items: [
                  const DropdownMenuItem<String>(
                    value: 'add_new',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle),
                        SizedBox(width: 8),
                        Text('Add New'),
                      ],
                    ),
                  ),
                  ...categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: transactionAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'RM ',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: transactionNoteController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              const Text('Attachment:'),
              if (files.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var index = 0; index < files.length; index++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  //* Open a new screen with the larger image
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageViewPage(
                                        imageSource: files[index] is String
                                            ? files[index]
                                            : files[index].path,
                                        type: files[index] is String
                                            ? 'url'
                                            : 'local',
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    if (files[index] is String)
                                      Image.network(
                                        files[index],
                                        height:
                                            100, //* Adjust the height as needed
                                        fit: BoxFit.contain,
                                      )
                                    else
                                      Image.file(
                                        File(files[index].path!),
                                        height:
                                            100, //* Adjust the height as needed
                                        fit: BoxFit.contain,
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (files[index] is String) {
                                            setState(() {
                                              filesToDelete = [
                                                ...filesToDelete,
                                                files[index]
                                              ];
                                            });
                                          }

                                          setState(() {
                                            files.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          color: Colors.red,
                                          child: const Icon(Icons.close),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform
                      .pickFiles(allowMultiple: true, type: FileType.image);
                  if (result != null) {
                    for (var file in result.files) {
                      //* Check if file size is less than or equal to 5MB (5 * 1024 * 1024 bytes)
                      if (file.size <= 5 * 1024 * 1024) {
                        setState(() {
                          files = [...files, file];
                        });
                      } else {
                        //* Notify user about the file size limit
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('File Size Limit Exceeded'),
                              content: Text(
                                  'The file ${file.name} exceeds 5MB and cannot be uploaded.'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                },
                child: const Text('Add Attachment'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_isLoading) return;

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    await _updateTransactionToFirebase();
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    CollectionReference<Map<String, dynamic>> categoriesRef;

    if (selectedType != 'saving') {
      final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
      categoriesRef = cyclesRef.collection('categories');
    } else {
      categoriesRef = userRef.collection('savings');
    }

    Query<Map<String, dynamic>> query =
        categoriesRef.where('deleted_at', isNull: true);

    if (selectedType != 'saving') {
      query = query.where('type', isEqualTo: selectedType);
    }

    final categoriesSnapshot = await query.get();

    final fetchedCategories = categoriesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedCategories
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    setState(() {
      categories = fetchedCategories;
    });
  }

  Future<void> _updateTransactionToFirebase() async {
    //* Get the values from the form
    String type = selectedType;
    String categoryId = selectedCategoryId!;
    String amount = transactionAmountController.text;
    String note = transactionNoteController.text.replaceAll('\n', '\\n');
    DateTime dateTime = selectedDateTime;

    //* Validate the form data (add your own validation logic here)

    //* Get current timestamp
    final now = DateTime.now();

    //* Get the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated
      return;
    }

    try {
      //* Reference to the Firestore document to add the transaction
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final transactionsRef = userRef.collection('transactions');

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

      if (widget.action == 'Add') {
        //* Create a new transaction document
        await transactionsRef.add({
          'cycle_id': widget.cycleId,
          'date_time': dateTime,
          'type': type,
          'category_id': categoryId,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
          'files': downloadURLs,
        });
      } else if (widget.action == 'Edit') {
        await transactionsRef.doc(widget.transaction!.id).update({
          'date_time': dateTime,
          'type': type,
          'category_id': categoryId,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'updated_at': now,
          'files': downloadURLs,
        });

        for (var fileToDelete in filesToDelete) {
          t.Transaction.deleteFile(Uri.decodeComponent(
              t.Transaction.extractPathFromUrl(fileToDelete)));
        }
      }

      final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);

      //* Fetch the current cycle document
      final cycleDoc = await cyclesRef.get();

      if (cycleDoc.exists) {
        final cycleData = cycleDoc.data() as Map<String, dynamic>;

        //* Calculate the updated amounts
        final double cycleOpeningBalance =
            double.parse(cycleData['opening_balance']);
        final double cycleAmountReceived =
            double.parse(cycleData['amount_received']) +
                (widget.transaction != null &&
                        widget.transaction!.type == 'received'
                    ? -double.parse(widget.transaction!.amount)
                    : 0);
        final double cycleAmountSpent =
            double.parse(cycleData['amount_spent']) +
                (widget.transaction != null &&
                        (widget.transaction!.type == 'spent' ||
                            widget.transaction!.type == 'saving')
                    ? -double.parse(widget.transaction!.amount)
                    : 0);

        final newAmount = double.parse(amount);

        final double updatedAmountBalance = cycleOpeningBalance +
            cycleAmountReceived -
            cycleAmountSpent +
            ((type == 'spent' || type == 'saving') ? -newAmount : newAmount);

        //* Update the cycle document
        await cyclesRef.update({
          'amount_spent': (cycleAmountSpent +
                  ((type == 'spent' || type == 'saving') ? newAmount : 0))
              .toStringAsFixed(2),
          'amount_received':
              (cycleAmountReceived + (type == 'received' ? newAmount : 0))
                  .toStringAsFixed(2),
          'amount_balance': updatedAmountBalance.toStringAsFixed(2),
          'updated_at': now,
        });
      }

      if (type == 'spent') {
        final categoryRef = cyclesRef.collection('categories').doc(categoryId);

        //* Fetch the category document
        final categoryDoc = await categoryRef.get();

        if (categoryDoc.exists) {
          final categoryData = categoryDoc.data() as Map<String, dynamic>;

          //* Calculate the updated amounts
          final double amountSpent =
              double.parse(categoryData['amount_spent']) +
                  double.parse(amount) -
                  (widget.transaction != null
                      ? double.parse(widget.transaction!.amount)
                      : 0);

          //* Update the cycle document
          await categoryRef.update({
            'amount_spent': amountSpent.toStringAsFixed(2),
            'updated_at': now,
          });
        }
      }

      if (type == 'saving') {
        final savingsRef = userRef.collection('savings').doc(categoryId);

        //* Fetch the category document
        final savingDoc = await savingsRef.get();

        if (savingDoc.exists) {
          final savingData = savingDoc.data() as Map<String, dynamic>;

          //* Calculate the updated amounts
          final double amountReceived =
              double.parse(savingData['amount_received']) +
                  double.parse(amount) -
                  (widget.transaction != null
                      ? double.parse(widget.transaction!.amount)
                      : 0);

          //* Update the cycle document
          await savingsRef.update({
            'amount_received': amountReceived.toStringAsFixed(2),
            'updated_at': now,
          });
        }
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      //* Handle any errors that occur during the Firestore operation
      print('Error saving transaction: $e');
      //* You can show an error message to the user if needed
    }
  }
}
