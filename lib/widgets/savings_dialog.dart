import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saving.dart';

class SavingsDialog extends StatefulWidget {
  final String action;
  final Saving? saving;
  final Function onSavingsChanged;

  const SavingsDialog(
      {Key? key,
      required this.action,
      this.saving,
      required this.onSavingsChanged})
      : super(key: key);

  @override
  SavingsDialogState createState() => SavingsDialogState();
}

class SavingsDialogState extends State<SavingsDialog> {
  final TextEditingController _savingsNameController = TextEditingController();
  final TextEditingController _savingsOpeningBalanceController =
      TextEditingController();
  final TextEditingController _savingsGoalController = TextEditingController();
  final TextEditingController _savingsNoteController = TextEditingController();
  bool _isGoalEnabled = false;

  @override
  void initState() {
    super.initState();

    if (widget.saving != null) {
      _savingsNameController.text = widget.saving!.name;
      _savingsOpeningBalanceController.text = widget.saving!.openingBalance;
      _savingsGoalController.text = widget.saving!.goal;
      _savingsNoteController.text = widget.saving!.note;
      _isGoalEnabled = _savingsGoalController.text.isNotEmpty &&
          _savingsGoalController.text != '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _savingsNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: _savingsOpeningBalanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    prefixText: 'RM ',
                  ),
                ),
              ],
            ),
            if (_isGoalEnabled) //* Show goal field only when the checkbox is checked
              Column(
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: _savingsGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Goal',
                      prefixText: 'RM ',
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                Checkbox(
                  value: _isGoalEnabled,
                  onChanged: (bool? value) {
                    setState(() {
                      _isGoalEnabled = value ?? false;
                    });
                  },
                ),
                const Text('Set a Goal'),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _savingsNoteController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
            final savingsName = _savingsNameController.text;
            final savingsOpeningBalance = _savingsOpeningBalanceController.text;
            final savingsGoal = _savingsGoalController.text;
            final savingsNote = _savingsNoteController.text;

            if (savingsName.isEmpty ||
                savingsOpeningBalance.isEmpty ||
                (_isGoalEnabled && savingsGoal.isEmpty)) {
              return;
            }

            if (savingsName.isNotEmpty) {
              //* Call the function to update to Firebase
              updateSavingsToFirebase(
                  savingsName, savingsOpeningBalance, savingsGoal, savingsNote);

              //* Close the dialog
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.action == 'Edit' ? 'Save' : widget.action),
        ),
      ],
    );
  }

  //* Function to update savings to Firebase Firestore
  Future<void> updateSavingsToFirebase(
      String savingsName,
      String savingsOpeningBalance,
      String savingsGoal,
      String savingsNote) async {
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
        //* Create the new saving document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savings')
            .add({
          'name': savingsName,
          'opening_balance':
              double.parse(savingsOpeningBalance).toStringAsFixed(2),
          'goal': double.parse(_isGoalEnabled ? savingsGoal : '0.00')
              .toStringAsFixed(2),
          'note': savingsNote,
          'amount_received': '0.00',
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        final docId =
            widget.saving!.id; //* Get the ID of the savings item to edit
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savings')
            .doc(docId)
            .update({
          'name': savingsName,
          'opening_balance':
              double.parse(savingsOpeningBalance).toStringAsFixed(2),
          'goal': double.parse(_isGoalEnabled ? savingsGoal : '0.00')
              .toStringAsFixed(2),
          'note': savingsNote,
          'updated_at': now,
        });
      }

      //* Notify the parent widget about the savings addition
      widget.onSavingsChanged();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      // ignore: avoid_print
      print('Error updating savings: $e');
    }
  }

  @override
  void dispose() {
    _savingsNameController.dispose();
    super.dispose();
  }
}
