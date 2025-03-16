// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import '../extensions/string_extension.dart';
import '../models/category.dart';
import '../pages/amount_input_page.dart';
import '../pages/note_input_page.dart';
import '../providers/categories_provider.dart';
import '../services/message_services.dart';

class CategoryDialog extends StatefulWidget {
  final String type;
  final String action;
  final Category? category;

  const CategoryDialog({
    super.key,
    required this.type,
    required this.action,
    required this.category,
  });

  @override
  CategoryDialogState createState() => CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryBudgetController =
      TextEditingController();
  final TextEditingController _categoryNoteController = TextEditingController();
  String _selectedSubType = 'others';
  bool _isBudgetEnabled = false;

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      _categoryNameController.text = widget.category!.name;
      _categoryBudgetController.text = widget.category!.budget;
      _categoryNoteController.text = widget.category!.note;
      _selectedSubType = widget.category!.subType != null
          ? widget.category!.subType!
          : 'others';
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
        title: Text('${widget.action} Category (${widget.type.capitalize()})'),
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
                ),
                if (widget.type == 'spent')
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        dropdownColor:
                            Theme.of(context).colorScheme.onSecondary,
                        value: _selectedSubType,
                        decoration: const InputDecoration(
                          labelText: 'Sub Type',
                        ),
                        items: ['needs', 'wants', 'savings', 'others']
                            .map((String subType) => DropdownMenuItem(
                                  value: subType,
                                  child: Text(subType.capitalize()),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSubType = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                if (_isBudgetEnabled) //* Show budget field only when the checkbox is checked
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmountInputPage(
                                amount: _categoryBudgetController.text,
                              ),
                            ),
                          );

                          if (result != null && result is String) {
                            _categoryBudgetController.text = result;
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _categoryBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Budget',
                              prefixText: 'RM',
                            ),
                          ),
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
                Card(
                  child: ListTile(
                    onTap: () async {
                      String note = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteInputPage(
                            note: _categoryNoteController.text,
                          ),
                        ),
                      );

                      if (note == 'empty') {
                        setState(() {
                          _categoryNoteController.text = '';
                        });
                      } else if (note.isNotEmpty) {
                        setState(() {
                          _categoryNoteController.text = note;
                        });
                      }
                    },
                    leading: Icon(Icons.notes),
                    title: Text(
                      _categoryNoteController.text.isEmpty
                          ? 'Add Note'
                          : _categoryNoteController.text.contains('insert')
                              ? ParchmentDocument.fromJson(
                                      jsonDecode(_categoryNoteController.text))
                                  .toPlainText()
                              : _categoryNoteController.text.split('\\n')[0],
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

              final MessageService messageService = MessageService();

              EasyLoading.show(
                  status: widget.action == 'Edit'
                      ? messageService.getRandomUpdateMessage()
                      : messageService.getRandomAddMessage());

              final categoryName = _categoryNameController.text;
              final categoryBudget = _categoryBudgetController.text;
              final categoryNote = _categoryNoteController.text;

              final message = _validate(categoryName, categoryBudget);

              if (message.isNotEmpty) {
                EasyLoading.showInfo(message);
                return;
              }

              await context.read<CategoriesProvider>().updateCategory(
                    context,
                    widget.action,
                    widget.type,
                    _selectedSubType,
                    categoryName,
                    _isBudgetEnabled,
                    categoryBudget,
                    categoryNote,
                    category: widget.category,
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

  String _validate(String name, String budget) {
    if (name.isEmpty) {
      return 'Please enter the category\'s name.';
    }

    if (_isBudgetEnabled) {
      if (budget.isEmpty) {
        return 'Please enter the category\'s budget.';
      }

      //* Remove any commas from the string
      String cleanedValue = budget.replaceAll(',', '');

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

      _categoryBudgetController.text = cleanedValue;
    }

    return '';
  }
}
