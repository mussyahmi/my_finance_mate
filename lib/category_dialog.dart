import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDialog extends StatefulWidget {
  final String cycleId;
  final String action;
  final Map category;
  final Function onCategoryChanged;

  const CategoryDialog(
      {Key? key,
      required this.cycleId,
      required this.action,
      required this.category,
      required this.onCategoryChanged})
      : super(key: key);

  @override
  CategoryDialogState createState() => CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialog> {
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.category.isNotEmpty) {
      _categoryNameController.text = widget.category['name'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} Category'),
      content: TextField(
        controller: _categoryNameController,
        decoration: const InputDecoration(
          labelText: 'Name',
        ),
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
            final categoryName = _categoryNameController.text;
            if (categoryName.isNotEmpty) {
              //* Call the function to update to Firebase
              updateCategoryToFirebase(categoryName);

              //* Close the dialog
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.action),
        ),
      ],
    );
  }

  //* Function to update category to Firebase Firestore
  Future<void> updateCategoryToFirebase(String categoryName) async {
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
            .add({
          'name': categoryName,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        final docId =
            widget.category['id']; //* Get the ID of the category item to edit
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(widget.cycleId)
            .collection('categories')
            .doc(docId)
            .update({
          'name': categoryName,
          'updated_at': now,
        });
      }

      //* Notify the parent widget about the category addition
      widget.onCategoryChanged();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      // ignore: avoid_print
      print('Error adding category: $e');
    }
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }
}
