import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubcategoryDialog extends StatefulWidget {
  final String cycleId;
  final String categoryId;
  final String action;
  final Map subcategory;
  final Function onSubcategoryChanged;

  const SubcategoryDialog(
      {Key? key,
      required this.cycleId,
      required this.categoryId,
      required this.action,
      required this.subcategory,
      required this.onSubcategoryChanged})
      : super(key: key);

  @override
  SubcategoryDialogState createState() => SubcategoryDialogState();
}

class SubcategoryDialogState extends State<SubcategoryDialog> {
  final TextEditingController _subcategoryNameController =
      TextEditingController();
  final TextEditingController _subcategoryBudgetController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.subcategory.isNotEmpty) {
      _subcategoryNameController.text = widget.subcategory['name'] ?? '';
      _subcategoryBudgetController.text = widget.subcategory['budget'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} Subcategory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _subcategoryNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subcategoryBudgetController,
            keyboardType: TextInputType.number, //* Allow only numeric input
            decoration: const InputDecoration(
              labelText: 'Budget',
              prefixText: 'RM ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); //* Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final subcategoryName = _subcategoryNameController.text;
            final subcategoryBudget = _subcategoryBudgetController.text;
            if (subcategoryName.isNotEmpty && subcategoryBudget.isNotEmpty) {
              //* Call the function to add to Firebase
              addSubcategoryToFirebase(subcategoryName, subcategoryBudget);

              //* Close the dialog
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.action),
        ),
      ],
    );
  }

  //* Function to add a new subcategory to Firebase Firestore
  Future<void> addSubcategoryToFirebase(
      String subcategoryName, String subcategoryBudget) async {
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
        //* Create the new cycle document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(widget.cycleId)
            .collection('categories')
            .doc(widget.categoryId)
            .collection('subcategories')
            .add({
          'name': subcategoryName,
          'budget': double.parse(subcategoryBudget).toStringAsFixed(2),
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        final docId = widget
            .subcategory['id']; //* Get the ID of the subcategory item to edit
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(widget.cycleId)
            .collection('categories')
            .doc(widget.categoryId)
            .collection('subcategories')
            .doc(docId)
            .update({
          'name': subcategoryName,
          'budget': double.parse(subcategoryBudget).toStringAsFixed(2),
          'updated_at': now,
        });
      }

      //* Notify the parent widget about the subcategory addition
      widget.onSubcategoryChanged();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      // ignore: avoid_print
      print('Error adding subcategory: $e');
    }
  }

  @override
  void dispose() {
    _subcategoryNameController.dispose();
    super.dispose();
  }
}
