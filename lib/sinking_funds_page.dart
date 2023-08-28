import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sinking_funds_dialog.dart';

class SinkingFundsPage extends StatefulWidget {
  const SinkingFundsPage({super.key});

  @override
  State<SinkingFundsPage> createState() => _SinkingFundsPageState();
}

class _SinkingFundsPageState extends State<SinkingFundsPage> {
  List<Map<String, dynamic>> sinkingFunds = [];

  @override
  void initState() {
    super.initState();
    _fetchSinkingFunds();
  }

  Future<void> _fetchSinkingFunds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final sinkingFundsRef = userRef.collection('sinking_funds');

    final sinkingFundsSnapshot =
        await sinkingFundsRef.where('deleted_at', isNull: true).get();

    final fetchedSinkingFunds = sinkingFundsSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'opening_balance': doc['opening_balance'] as String,
              'goal': doc['goal'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by 'created_at' in ascending order (most recent last)
    fetchedSinkingFunds.sort((a, b) =>
        (a['created_at'] as DateTime).compareTo((b['created_at'] as DateTime)));

    setState(() {
      sinkingFunds = fetchedSinkingFunds;
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
            children: sinkingFunds.map((fund) {
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
                      title: Text(fund['name']),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            //* Handle edit option
                            _showSinkingFundsDialog(context, 'Edit',
                                fund: fund);
                          } else if (value == 'delete') {
                            //* Handle delete option
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this fund?'),
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
                                        final fundId = fund['id'];

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
                                        final sinkingFundsRef =
                                            userRef.collection('sinking_funds');
                                        final fundRef =
                                            sinkingFundsRef.doc(fundId);

                                        //* Update the 'deleted_at' field with the current timestamp
                                        final now = DateTime.now();
                                        fundRef.update({'deleted_at': now});

                                        _fetchSinkingFunds();

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
          _showSinkingFundsDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //* Function to show the add category dialog
  void _showSinkingFundsDialog(BuildContext context, String action,
      {Map? fund}) {
    showDialog(
      context: context,
      builder: (context) {
        return SinkingFundsDialog(
          action: action,
          fund: fund ?? {},
          onSinkingFundsChanged: _fetchSinkingFunds,
        );
      },
    );
  }
}
