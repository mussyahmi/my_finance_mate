import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_list_page.dart';
import 'subcategory_list_page.dart';

class AddTransactionPage extends StatefulWidget {
  final String cycleId;
  const AddTransactionPage({super.key, required this.cycleId});

  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  String selectedType = 'spent';
  String? selectedCategory;
  String? selectedSubcategory;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subcategories = [];
  TextEditingController transactionAmountController = TextEditingController();
  TextEditingController transactionNoteController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
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
                    // ignore: use_build_context_synchronously
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
                  'Date Time: ${DateFormat('EEEE, dd MMM yyyy hh:mm aa').format(selectedDateTime)}',
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
                    selectedSubcategory = null;
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
                      selectedSubcategory = null;
                    });

                    _fetchCategories();
                  }

                  _fetchSubcategories(newValue as String);
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
              DropdownButtonFormField<String>(
                value: selectedSubcategory,
                onChanged: (newValue) async {
                  setState(() {
                    selectedSubcategory = newValue;
                  });

                  if (newValue == 'add_new') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SubcategoryListPage(
                              cycleId: widget.cycleId,
                              categoryId: selectedCategory as String,
                              categoryName: 'Subcategory List')),
                    );

                    setState(() {
                      selectedSubcategory = null;
                    });

                    _fetchSubcategories(selectedCategory as String);

                    return;
                  }
                },
                items: [
                  ...subcategories.map((subcategory) {
                    return DropdownMenuItem<String>(
                      value: subcategory['id'],
                      child: Text(subcategory['name']),
                    );
                  }).toList(),
                  if (selectedCategory != null)
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
                  labelText: 'Subcategory',
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
                  //* Get the values from the form
                  String type = selectedType;
                  String categoryId = selectedCategory!;
                  String subcategoryId = selectedSubcategory!;
                  String amount = transactionAmountController.text;
                  String note =
                      transactionNoteController.text.replaceAll('\n', '\\n');
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
                    final userRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid);
                    final transactionsRef = userRef.collection('transactions');

                    //* Create a new transaction document
                    await transactionsRef.add({
                      'cycleId': widget.cycleId,
                      'dateTime': dateTime,
                      'type': type,
                      'categoryId': categoryId,
                      'subcategoryId': subcategoryId,
                      'amount': amount,
                      'note': note,
                      'created_at': now,
                      'updated_at': now,
                      'deleted_at': null,
                      'version_json': null,
                    });

                    //* After saving the transaction, you can navigate back to the previous page
                    // ignore: use_build_context_synchronously
                    Navigator.pop(
                        context); //* Close the transaction adding page
                  } catch (e) {
                    //* Handle any errors that occur during the Firestore operation
                    // ignore: avoid_print
                    print('Error saving transaction: $e');
                    //* You can show an error message to the user if needed
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit'),
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

  Future<void> _fetchSubcategories(String categoryId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
    final categoriesRef = cyclesRef.collection('categories').doc(categoryId);
    final subcategoriesRef = categoriesRef.collection('subcategories');

    final subcategoriesSnapshot =
        await subcategoriesRef.where('deleted_at', isNull: true).get();

    final fetchedSubcategories = subcategoriesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'budget': doc['budget'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by 'created_at' in ascending order (most recent last)
    fetchedSubcategories.sort((a, b) =>
        (a['created_at'] as DateTime).compareTo((b['created_at'] as DateTime)));

    setState(() {
      subcategories = fetchedSubcategories;
    });
  }
}
