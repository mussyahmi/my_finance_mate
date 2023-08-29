import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'savings_dialog.dart';
import 'saving.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Saving> savings = [];

  @override
  void initState() {
    super.initState();
    _fetchSavings();
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
              createdAt: (doc['created_at'] as Timestamp).toDate(),
            ))
        .toList();

    //* Sort the list by 'created_at' in ascending order (most recent first)
    fetchedSavings.sort((a, b) => (b.createdAt).compareTo((a.createdAt)));

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
                        onSelected: (value) {
                          if (value == 'edit') {
                            //* Handle edit option
                            _showSavingsDialog(context, 'Edit', saving: saving);
                          } else if (value == 'delete') {
                            //* Handle delete option
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
}
