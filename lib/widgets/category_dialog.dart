import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../extensions/firestore_extensions.dart';

class CategoryDialog extends StatefulWidget {
  final String cycleId;
  final String type;
  final String action;
  final Category? category;
  final Function onCategoryChanged;

  const CategoryDialog(
      {Key? key,
      required this.cycleId,
      required this.type,
      required this.action,
      required this.category,
      required this.onCategoryChanged})
      : super(key: key);

  @override
  CategoryDialogState createState() => CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialog> {
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryBudgetController =
      TextEditingController();
  final TextEditingController _categoryNoteController = TextEditingController();
  bool _isBudgetEnabled = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      _categoryNameController.text = widget.category?.name ?? '';
      _categoryBudgetController.text = widget.category?.budget ?? '';
      _categoryNoteController.text = widget.category?.note ?? '';
      _isBudgetEnabled = _categoryBudgetController.text.isNotEmpty &&
          _categoryBudgetController.text != '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('${widget.action} Category'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category\' name.';
                    }
                    return null;
                  },
                ),
                if (_isBudgetEnabled) //* Show budget field only when the checkbox is checked
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: _categoryBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Budget',
                          prefixText: 'RM ',
                        ),
                      ),
                    ],
                  ),
                if (widget.type == 'spent')
                  Row(
                    children: [
                      Checkbox(
                        value: _isBudgetEnabled,
                        onChanged: (bool? value) {
                          setState(() {
                            _isBudgetEnabled = value ?? false;
                          });
                        },
                      ),
                      const Text('Set a Budget'),
                    ],
                  ),
                if (widget.type == 'spent') const SizedBox(height: 10),
                if (widget.type == 'received') const SizedBox(height: 20),
                TextField(
                  controller: _categoryNoteController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); //* Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();

              final categoryName = _categoryNameController.text;
              final categoryBudget = _categoryBudgetController.text;
              final categoryNote = _categoryNoteController.text;

              final message = _validate(categoryName, categoryBudget);

              if (message.isNotEmpty) {
                final snackBar = SnackBar(
                  content: Text(
                    message,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onError),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  showCloseIcon: true,
                  closeIconColor: Theme.of(context).colorScheme.onError,
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                return;
              }

              //* Call the function to update to Firebase
              updateCategoryToFirebase(
                  categoryName, categoryBudget, categoryNote);

              //* Close the dialog
              Navigator.of(context).pop(true);
            },
            child: Text(widget.action == 'Edit' ? 'Save' : widget.action),
          ),
        ],
      ),
    );
  }

  String _validate(String name, String budget) {
    if (name.isEmpty) {
      return 'Please enter category\'s name.';
    }

    if (_isBudgetEnabled) {
      if (budget.isEmpty) {
        return 'Please enter category\'s budget.';
      }

      //* Remove any commas from the string
      String cleanedValue = budget.replaceAll(',', '');

      //* Check if the cleaned value is a valid double
      if (double.tryParse(cleanedValue) == null) {
        return 'Please enter a valid number.';
      }

      //* Check if the value is a positive number
      if (double.parse(cleanedValue) <= 0) {
        return 'Please enter a positive value.';
      }

      //* Custom currency validation (you can modify this based on your requirements)
      //* Here, we are checking if the value has up to 2 decimal places
      List<String> splitValue = cleanedValue.split('.');
      if (splitValue.length > 1 && splitValue[1].length > 2) {
        return 'Please enter a valid currency value with up to 2 decimal places';
      }

      _categoryBudgetController.text = cleanedValue;
    }

    return '';
  }

  //* Function to update category to Firebase Firestore
  Future<void> updateCategoryToFirebase(
      String categoryName, String categoryBudget, String categoryNote) async {
    try {
      //* Get current timestamp
      final now = DateTime.now();

      //* Get the current user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        //todo: Handle the case where user is not authenticated
        return;
      }

      if (widget.action == 'Add') {
        //* Create the new category document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(widget.cycleId)
            .collection('categories')
            .add({
          'name': categoryName,
          'budget': double.parse(_isBudgetEnabled ? categoryBudget : '0.00')
              .toStringAsFixed(2),
          'note': categoryNote,
          'type': widget.type,
          'total_amount': '0.00',
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        final docId =
            widget.category!.id; //* Get the ID of the category item to edit
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(widget.cycleId)
            .collection('categories')
            .doc(docId)
            .update({
          'name': categoryName,
          'budget': double.parse(_isBudgetEnabled ? categoryBudget : '0.00')
              .toStringAsFixed(2),
          'note': categoryNote,
          'updated_at': now,
        });

        //* If the category name is modified, propagate the change to all associated transactions
        if (widget.category!.name != categoryName) {
          final transactionsRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions');

          final querySnapshot = await transactionsRef
              .where('category_id', isEqualTo: docId)
              .where('deleted_at', isNull: true)
              .getSavy();

          for (var doc in querySnapshot.docs) {
            await transactionsRef
                .doc(doc.id)
                .update({'category_name': categoryName});
          }
        }
      }

      //* Notify the parent widget about the category addition
      widget.onCategoryChanged();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      // ignore: avoid_print
      print('Error adding transaction: $e');
    }
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }
}
