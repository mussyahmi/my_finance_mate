// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'savings_dialog.dart';
import 'saving.dart';

class SavingsPage extends StatefulWidget {
  final bool? isFromTransactionForm;
  const SavingsPage({super.key, this.isFromTransactionForm});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Saving> savings = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    await _fetchSavings();

    if (widget.isFromTransactionForm != null) {
      _showSavingsDialog(context, 'Add');
    }
  }

  Future<void> _fetchSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final savingsRef = userRef.collection('savings');

    final savingsSnapshot =
        await savingsRef.where('deleted_at', isNull: true).get();

    final fetchedSavings = savingsSnapshot.docs
        .map((doc) => Saving(
              id: doc.id,
              name: doc['name'],
              goal: doc['goal'],
              amountReceived: doc['amount_received'],
              openingBalance: doc['opening_balance'],
              note: doc['note'],
              updatedAt: (doc['updated_at'] as Timestamp).toDate(),
            ))
        .toList();

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedSavings.sort((a, b) => (a.name).compareTo(b.name));

    setState(() {
      savings = fetchedSavings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category List'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: savings.map((saving) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text(saving.name),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            //* Handle edit option
                            _showSavingsDialog(context, 'Edit', saving: saving);
                          } else if (value == 'delete') {
                            //* Check if there are transactions associated with this category
                            final savingId = saving.id;
                            final hasTransactions =
                                await _hasTransactions(savingId);

                            if (hasTransactions) {
                              //* If there are transactions, show an error message or handle it accordingly.
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Cannot Delete Category'),
                                    content: const Text(
                                        'There are transactions associated with this category. You cannot delete it.'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); //* Close the dialog
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              //* If there are no transactions, proceed with the deletion.
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                        'Are you sure you want to delete this saving?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); //* Close the dialog
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          //* Delete the item from Firestore here
                                          final savingId = saving.id;

                                          //* Reference to the Firestore document to delete
                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) {
                                            //todo: Handle the case where the user is not authenticated
                                            return;
                                          }

                                          final userRef = FirebaseFirestore
                                              .instance
                                              .collection('users')
                                              .doc(user.uid);
                                          final savingsRef =
                                              userRef.collection('savings');
                                          final savingRef =
                                              savingsRef.doc(savingId);

                                          //* Update the 'deleted_at' field with the current timestamp
                                          final now = DateTime.now();
                                          savingRef.update({'deleted_at': now});

                                          _fetchSavings();

                                          Navigator.of(context)
                                              .pop(); //* Close the dialog
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSavingsDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //* Function to show the add category dialog
  void _showSavingsDialog(BuildContext context, String action,
      {Saving? saving}) {
    showDialog(
      context: context,
      builder: (context) {
        return SavingsDialog(
          action: action,
          saving: saving,
          onSavingsChanged: _fetchSavings,
        );
      },
    );
  }

  Future<bool> _hasTransactions(String savingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return false;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionsSnapshot = await transactionsRef
        .where('categoryId', isEqualTo: savingId)
        .where('deleted_at', isNull: true)
        .get();

    return transactionsSnapshot.docs.isNotEmpty;
  }
}
