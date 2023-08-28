// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_list_page.dart';
import 'dashboard_page.dart';
import 'transaction.dart' as t;

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
  String? selectedCategory;
  List<Map<String, dynamic>> categories = [];
  TextEditingController transactionAmountController = TextEditingController();
  TextEditingController transactionNoteController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    await _fetchCategories();

    if (widget.transaction != null) {
      selectedType = widget.transaction!.type;
      selectedCategory = widget.transaction!.categoryId;
      transactionAmountController.text = widget.transaction!.amount;
      transactionNoteController.text = widget.transaction!.note;
      selectedDateTime = widget.transaction!.dateTime;
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
                  });
                },
                items: ['spent', 'received']
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
                value: selectedCategory,
                onChanged: (newValue) async {
                  setState(() {
                    selectedCategory = newValue;
                  });

                  if (newValue == 'add_new') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CategoryListPage(cycleId: widget.cycleId)),
                    );

                    setState(() {
                      selectedCategory = null;
                    });

                    _fetchCategories();
                  }
                },
                items: [
                  ...categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
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
    final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    final categoriesSnapshot =
        await categoriesRef.where('deleted_at', isNull: true).get();

    final fetchedCategories = categoriesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by 'created_at' in ascending order (most recent last)
    fetchedCategories.sort((a, b) =>
        (a['created_at'] as DateTime).compareTo((b['created_at'] as DateTime)));

    setState(() {
      categories = fetchedCategories;
    });
  }

  Future<void> _updateTransactionToFirebase() async {
    //* Get the values from the form
    String type = selectedType;
    String categoryId = selectedCategory!;
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

      if (widget.action == 'Add') {
        //* Create a new transaction document
        await transactionsRef.add({
          'cycleId': widget.cycleId,
          'dateTime': dateTime,
          'type': type,
          'categoryId': categoryId,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        await transactionsRef.doc(widget.transaction!.id).update({
          'dateTime': dateTime,
          'type': type,
          'categoryId': categoryId,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'updated_at': now,
        });
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
                        widget.transaction!.type == 'spent'
                    ? -double.parse(widget.transaction!.amount)
                    : 0);

        final newAmount = double.parse(amount);

        final double updatedAmountBalance = cycleOpeningBalance +
            cycleAmountReceived -
            cycleAmountSpent +
            (type == 'spent' ? -newAmount : newAmount);

        //* Update the cycle document
        await cyclesRef.update({
          'amount_spent': (cycleAmountSpent + (type == 'spent' ? newAmount : 0))
              .toStringAsFixed(2),
          'amount_received':
              (cycleAmountReceived + (type == 'received' ? newAmount : 0))
                  .toStringAsFixed(2),
          'amount_balance': updatedAmountBalance.toStringAsFixed(2),
        });
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      //* Handle any errors that occur during the Firestore operation
      // ignore: avoid_print
      print('Error saving transaction: $e');
      //* You can show an error message to the user if needed
    }
  }
}
