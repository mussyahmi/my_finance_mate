import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';

import '../size_config.dart';

class AmountInputPage extends StatefulWidget {
  final String amount;

  const AmountInputPage({
    super.key,
    required this.amount,
  });

  @override
  State<AmountInputPage> createState() => _AmountInputPageState();
}

class _AmountInputPageState extends State<AmountInputPage> {
  String _amount = '0.00';

  @override
  void initState() {
    super.initState();

    if (widget.amount.isNotEmpty) {
      _amount = widget.amount;
    }
  }

  void _addDigit(int digit) {
    setState(() {
      //* Get the current text, replacing anything that isn't a number or a decimal point.
      String currentText = _amount.replaceAll(RegExp(r'[^0-9]'), '');
      currentText = currentText.isEmpty ? '0' : currentText;

      //* Add the new digit to the current text
      currentText = currentText + digit.toString();

      //* Format it back as a decimal string
      double value = int.parse(currentText) / 100.0;
      _amount = value.toStringAsFixed(2);
    });
  }

  void _backspace() {
    setState(() {
      //* Get the current text, replacing anything that isn't a number or a decimal point.
      String currentText = _amount.replaceAll(RegExp(r'[^0-9]'), '');
      currentText = currentText.isEmpty ? '0' : currentText;

      //* Remove the last digit
      if (currentText.length > 1) {
        currentText = currentText.substring(0, currentText.length - 1);
      } else {
        currentText = '0';
      }

      //* Format it back as a decimal string
      double value = int.parse(currentText) / 100.0;
      _amount = value.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Amount'),
        centerTitle: true,
      ),
      body: SizedBox(
        height: SizeConfig.screenHeight,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'RM $_amount',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            NumberPadKeyboard(
              addDigit: _addDigit,
              backspace: _backspace,
              enterButtonText: 'DONE',
              onEnter: () {
                Navigator.of(context).pop(_amount);
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              numberStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              deleteIcon: Icon(
                CupertinoIcons.delete_left_fill,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              enterButtonTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
