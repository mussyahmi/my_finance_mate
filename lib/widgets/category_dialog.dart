// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';

class CategoryDialog extends StatefulWidget {
  final String type;
  final String action;
  final Category? category;

  const CategoryDialog({
    Key? key,
    required this.type,
    required this.action,
    required this.category,
  }) : super(key: key);

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
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
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
                      return 'Please enter category\'s name.';
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
            onPressed: () async {
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

              await context.read<CategoriesProvider>().updateCategory(
                    context,
                    widget.action,
                    widget.type,
                    categoryName,
                    _isBudgetEnabled,
                    categoryBudget,
                    categoryNote,
                    category: widget.category,
                  );

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
}
