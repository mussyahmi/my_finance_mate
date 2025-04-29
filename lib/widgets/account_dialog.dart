// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/cycle.dart';
import '../pages/amount_input_page.dart';
import '../providers/accounts_provider.dart';
import '../services/message_services.dart';

class AccountDialog extends StatefulWidget {
  final Cycle cycle;
  final String action;
  final Account? account;

  const AccountDialog({
    super.key,
    required this.cycle,
    required this.action,
    required this.account,
  });

  @override
  AccountDialogState createState() => AccountDialogState();
}

class AccountDialogState extends State<AccountDialog> {
  final MessageService messageService = MessageService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _openingBalanceController =
      TextEditingController();
  bool _isExcluded = false;
  bool _canEditOpeningBalance = true;

  @override
  void initState() {
    super.initState();

    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _openingBalanceController.text = widget.account!.openingBalance;
      _isExcluded = widget.account!.isExcluded;
      _canEditOpeningBalance =
          widget.account!.createdAt.isAfter(widget.cycle.startDate) &&
              widget.account!.createdAt.isBefore(widget.cycle.endDate);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('${widget.action} Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _canEditOpeningBalance
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AmountInputPage(
                            amount: _openingBalanceController.text,
                          ),
                        ),
                      );

                      if (result != null && result is String) {
                        _openingBalanceController.text = result;
                      }
                    }
                  : null,
              child: AbsorbPointer(
                child: TextField(
                  controller: _openingBalanceController,
                  keyboardType:
                      TextInputType.number, //* Allow only numeric input
                  decoration: InputDecoration(
                    labelText: 'Opening Balance',
                    prefixText: 'RM',
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Exclude from net balance'),
                Checkbox(
                  value: _isExcluded,
                  onChanged: (bool? value) {
                    setState(() {
                      _isExcluded = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              EasyLoading.show(
                  status: widget.action == 'Edit'
                      ? messageService.getRandomUpdateMessage()
                      : messageService.getRandomAddMessage());

              final message = _validate(
                  _nameController.text, _openingBalanceController.text);

              if (message.isNotEmpty) {
                EasyLoading.showInfo(message);
                return;
              }

              await context.read<AccountsProvider>().updateAccount(
                    context,
                    widget.cycle,
                    widget.action,
                    _nameController.text,
                    double.parse(_openingBalanceController.text)
                        .toStringAsFixed(2),
                    _isExcluded,
                    account: widget.account,
                  );

              EasyLoading.showSuccess(widget.action == 'Edit'
                  ? messageService.getRandomDoneUpdateMessage()
                  : messageService.getRandomDoneAddMessage());

              Navigator.of(context).pop(true);
            },
            child: Text(widget.action == 'Edit' ? 'Save' : widget.action),
          ),
        ],
      ),
    );
  }

  String _validate(String name, String amount) {
    if (name.isEmpty) {
      return 'Please enter the account\'s name.';
    }

    if (amount.isEmpty) {
      return 'Please enter the opening balance\'s amount.';
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
    // if (double.parse(cleanedValue) == 0) {
    //   return 'The amount cannot be zero.';
    // }

    //* Custom currency validation (you can modify this based on your requirements)
    //* Here, we are checking if the value has up to 2 decimal places
    List<String> splitValue = cleanedValue.split('.');
    if (splitValue.length > 1 && splitValue[1].length > 2) {
      return 'Please enter a valid currency value with up to 2 decimal places';
    }

    _openingBalanceController.text = cleanedValue;

    return '';
  }
}
