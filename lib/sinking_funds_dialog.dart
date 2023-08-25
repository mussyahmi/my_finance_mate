import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SinkingFundsDialog extends StatefulWidget {
  final String action;
  final Map fund;
  final void Function() onSinkingFundsChanged;

  const SinkingFundsDialog(
      {Key? key,
      required this.action,
      required this.fund,
      required this.onSinkingFundsChanged})
      : super(key: key);

  @override
  SinkingFundsDialogState createState() => SinkingFundsDialogState();
}

class SinkingFundsDialogState extends State<SinkingFundsDialog> {
  final TextEditingController _sinkingFundsNameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.fund.isNotEmpty) {
      _sinkingFundsNameController.text = widget.fund['name'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} Sinking Funds'),
      content: TextField(
        controller: _sinkingFundsNameController,
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
            final sinkingFundsName = _sinkingFundsNameController.text;
            if (sinkingFundsName.isNotEmpty) {
              //* Call the function to update to Firebase
              updateSinkingFundsToFirebase(sinkingFundsName);

              //* Close the dialog
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.action),
        ),
      ],
    );
  }

  //* Function to update sinking funds to Firebase Firestore
  Future<void> updateSinkingFundsToFirebase(String sinkingFundsName) async {
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
            .collection('sinking_funds')
            .add({
          'name': sinkingFundsName,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        final docId =
            widget.fund['id']; //* Get the ID of the sinking funds item to edit
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sinking_funds')
            .doc(docId)
            .update({
          'name': sinkingFundsName,
          'updated_at': now,
        });
      }

      //* Notify the parent widget about the sinking funds addition
      widget.onSinkingFundsChanged();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      // ignore: avoid_print
      print('Error updating sinking funds: $e');
    }
  }

  @override
  void dispose() {
    _sinkingFundsNameController.dispose();
    super.dispose();
  }
}
