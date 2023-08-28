import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SinkingFundsDialog extends StatefulWidget {
  final String action;
  final Map fund;
  final Function onSinkingFundsChanged;

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
  final TextEditingController _sinkingFundsOpeningBalanceController =
      TextEditingController();
  final TextEditingController _sinkingFundsGoalController =
      TextEditingController();
  bool _isGoalEnabled = false;

  @override
  void initState() {
    super.initState();

    if (widget.fund.isNotEmpty) {
      _sinkingFundsNameController.text = widget.fund['name'] ?? '';
      _sinkingFundsOpeningBalanceController.text =
          widget.fund['opening_balance'] ?? '';
      _sinkingFundsGoalController.text = widget.fund['goal'] ?? '';
      _isGoalEnabled = _sinkingFundsGoalController.text.isNotEmpty &&
          _sinkingFundsGoalController.text != '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sinkingFundsNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _sinkingFundsOpeningBalanceController,
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
                  controller: _sinkingFundsGoalController,
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
            final sinkingFundsName = _sinkingFundsNameController.text;
            final sinkingFundsOpeningBalance =
                _sinkingFundsOpeningBalanceController.text;
            final sinkingFundsGoal = _sinkingFundsGoalController.text;

            if (sinkingFundsName.isEmpty ||
                sinkingFundsOpeningBalance.isEmpty ||
                (_isGoalEnabled && sinkingFundsGoal.isEmpty)) {
              return;
            }

            if (sinkingFundsName.isNotEmpty) {
              //* Call the function to update to Firebase
              updateSinkingFundsToFirebase(sinkingFundsName,
                  sinkingFundsOpeningBalance, sinkingFundsGoal);

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
  Future<void> updateSinkingFundsToFirebase(String sinkingFundsName,
      String sinkingFundsOpeningBalance, String sinkingFundsGoal) async {
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
          'opening_balance':
              double.parse(sinkingFundsOpeningBalance).toStringAsFixed(2),
          'goal': double.parse(_isGoalEnabled ? sinkingFundsGoal : '0.00')
              .toStringAsFixed(2),
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
          'opening_balance':
              double.parse(sinkingFundsOpeningBalance).toStringAsFixed(2),
          'goal': double.parse(_isGoalEnabled ? sinkingFundsGoal : '0.00')
              .toStringAsFixed(2),
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
