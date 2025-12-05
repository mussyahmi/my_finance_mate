import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../pages/amount_input_page.dart';
import '../pages/note_input_page.dart';
import '../providers/debt_provider.dart';
import '../services/message_services.dart';

class DebtDialog extends StatefulWidget {
  final BuildContext parentContext;
  final String action;
  final Debt? debt;

  const DebtDialog({
    super.key,
    required this.parentContext,
    required this.action,
    this.debt,
  });

  @override
  State<DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends State<DebtDialog> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  DebtType selectedType = DebtType.iOwe;

  @override
  void initState() {
    super.initState();

    if (widget.debt != null) {
      nameController.text = widget.debt!.personName;
      amountController.text = widget.debt!.amount.toString();
      noteController.text = widget.debt!.note;
      selectedType = widget.debt!.type;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext dialogContext) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text("${widget.action} Debt"),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Person's Name"),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AmountInputPage(
                        amount: amountController.text,
                      ),
                    ),
                  );

                  if (result != null && result is String) {
                    amountController.text = result;
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: amountController,
                    keyboardType:
                        TextInputType.number, //* Allow only numeric input
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'RM',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                dropdownColor: Theme.of(context).colorScheme.onSecondary,
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: DebtType.iOwe,
                    child: Text("I Owe"),
                  ),
                  DropdownMenuItem(
                    value: DebtType.theyOweMe,
                    child: Text("They Owe Me"),
                  ),
                ],
                onChanged: (DebtType? newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  onTap: () async {
                    final String? note = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteInputPage(
                          note: noteController.text,
                        ),
                      ),
                    );

                    if (note == null) {
                      return;
                    }

                    if (note == 'empty') {
                      setState(() {
                        noteController.text = '';
                      });
                    } else if (note.isNotEmpty) {
                      setState(() {
                        noteController.text = note;
                      });
                    }
                  },
                  leading: Icon(Icons.notes),
                  title: Text(
                    noteController.text.isEmpty
                        ? 'Add Note'
                        : noteController.text.contains('insert')
                            ? ParchmentDocument.fromJson(
                                    jsonDecode(noteController.text))
                                .toPlainText()
                            : noteController.text.split('\\n')[0],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();

              final MessageService messageService = MessageService();

              EasyLoading.show(
                dismissOnTap: false,
                status: widget.action == 'Edit'
                    ? messageService.getRandomUpdateMessage()
                    : messageService.getRandomAddMessage(),
              );

              final name = nameController.text;
              final amount = amountController.text;
              final note = noteController.text;

              final message = _validate(name, amount);

              if (message.isNotEmpty) {
                EasyLoading.showInfo(message);
                return;
              }

              widget.parentContext.read<DebtProvider>().updateDebt(
                    widget.parentContext,
                    widget.action,
                    name,
                    amount,
                    selectedType,
                    note,
                    debt: widget.debt,
                  );

              EasyLoading.showSuccess(widget.action == 'Edit'
                  ? messageService.getRandomDoneUpdateMessage()
                  : messageService.getRandomDoneAddMessage());

              Navigator.pop(dialogContext, true);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  String _validate(String name, String amount) {
    if (name.isEmpty) {
      return 'Please enter the person\'s name.';
    }

    if (amount.isEmpty) {
      return 'Please enter the category\'s budget.';
    }

    //* Remove any commas from the string
    String cleanedValue = amount.replaceAll(',', '');

    //* Check if the cleaned value is a valid double
    if (double.tryParse(cleanedValue) == null) {
      return 'Please enter a valid number.';
    }

    //* Check if the value is a positive number
    if (double.parse(cleanedValue) < 0) {
      return 'Please enter a positive value.';
    }

    //* Check if the value is 0
    if (double.parse(cleanedValue) == 0) {
      return 'The amount cannot be zero.';
    }

    //* Custom currency validation (you can modify this based on your requirements)
    //* Here, we are checking if the value has up to 2 decimal places
    List<String> splitValue = cleanedValue.split('.');
    if (splitValue.length > 1 && splitValue[1].length > 2) {
      return 'Please enter a valid currency value with up to 2 decimal places';
    }

    amountController.text = cleanedValue;

    return '';
  }
}
