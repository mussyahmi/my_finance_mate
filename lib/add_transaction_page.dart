import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  String selectedType = 'spent';
  String selectedCategory = 'Food';
  String selectedSubcategory = 'Groceries';
  TextEditingController transactionAmountController = TextEditingController();
  TextEditingController transactionNoteController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate:
                                DateTime(2000), //todo: cycle's start date
                            lastDate: DateTime(2101), //todo: cycle's end date
                          );
                          if (selectedDate != null) {
                            // ignore: use_build_context_synchronously
                            final selectedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (selectedTime != null) {
                              setState(() {
                                selectedDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Text(
                          'Date Time: ${DateFormat('EEEE, dd MMM yyyy hh:mm aa').format(selectedDateTime)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  onChanged: (newValue) {
                    setState(() {
                      selectedType = newValue!;
                    });
                  },
                  items: ['spent', 'received']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                                '${type[0].toUpperCase()}${type.substring(1)}'),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                  items: ['Food', 'Transport', 'Entertainment']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedSubcategory,
                  onChanged: (newValue) {
                    setState(() {
                      selectedSubcategory = newValue!;
                    });
                  },
                  items: ['Groceries', 'Dining', 'Gas', 'Movies']
                      .map((subcategory) => DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: transactionAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'RM ',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: transactionNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                //* Add your code to save the transaction here
                String type = selectedType;
                String category = selectedCategory;
                String subcategory = selectedSubcategory;
                String amount = transactionAmountController.text;
                String note = transactionNoteController.text;
                DateTime dateTime = selectedDateTime;

                //* You can perform validation and save the transaction data to Firebase or any other storage
                //* For example, you can use Firestore to save the transaction.
                //* Make sure to implement the logic for saving transactions.

                //* After saving the transaction, you can navigate back to the dashboard or any other page.
                Navigator.pop(context); //* Close the transaction adding page.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
