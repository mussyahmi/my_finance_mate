// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/category_dialog.dart';
import '../models/category.dart';
import 'transaction_list_page.dart';

class CategoryListPage extends StatefulWidget {
  final String cycleId;
  final String type;
  final bool? isFromTransactionForm;

  const CategoryListPage(
      {super.key,
      required this.cycleId,
      required this.type,
      this.isFromTransactionForm});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    await _fetchCategories();

    if (widget.isFromTransactionForm != null) {
      _showCategoryDialog(context, 'Add');
    }
  }

  Future<void> _fetchCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    final categoriesSnapshot = await categoriesRef
        .where('deleted_at', isNull: true)
        .where('type', isEqualTo: widget.type)
        .get();

    final fetchedCategories = categoriesSnapshot.docs
        .map((doc) => Category(
              id: doc.id,
              name: doc['name'],
              type: doc['type'],
              note: doc['note'],
              budget: doc['budget'],
              amountSpent: doc['amount_spent'],
              createdAt: (doc['created_at'] as Timestamp).toDate(),
              updatedAt: (doc['updated_at'] as Timestamp).toDate(),
            ))
        .toList();

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedCategories.sort((a, b) => (a.name).compareTo(b.name));

    setState(() {
      categories = fetchedCategories;
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
            children: [
              ...categories.map((category) {
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
                        title: Text(category.name),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                          ),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              //* Handle edit option
                              _showCategoryDialog(context, 'Edit',
                                  category: category);
                            } else if (value == 'delete') {
                              //* Check if there are transactions associated with this category
                              final hasTransactions =
                                  await category.hasTransactions();

                              if (hasTransactions) {
                                //* If there are transactions, show an error message or handle it accordingly.
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('Cannot Delete Category'),
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
                                          'Are you sure you want to delete this category?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); //* Close the dialog
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            //* Delete the item from Firestore here
                                            final categoryId = category.id;

                                            //* Reference to the Firestore document to delete
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user == null) {
                                              //todo: Handle the case where the user is not authenticated
                                              return;
                                            }

                                            final userRef = FirebaseFirestore
                                                .instance
                                                .collection('users')
                                                .doc(user.uid);
                                            final cyclesRef = userRef
                                                .collection('cycles')
                                                .doc(widget.cycleId);
                                            final categoriesRef = cyclesRef
                                                .collection('categories');
                                            final categoryRef =
                                                categoriesRef.doc(categoryId);

                                            //* Update the 'deleted_at' field with the current timestamp
                                            final now = DateTime.now();
                                            categoryRef.update({
                                              'updated_at': now,
                                              'deleted_at': now,
                                            });

                                            _fetchCategories();

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
                        onTap: () {
                          category.showCategorySummaryDialog(context);
                        },
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionListPage(
                                  cycleId: widget.cycleId,
                                  type: widget.type,
                                  categoryName: category.name),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCategoryDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //* Function to show the add category dialog
  void _showCategoryDialog(BuildContext context, String action,
      {Category? category}) {
    showDialog(
      context: context,
      builder: (context) {
        return CategoryDialog(
          cycleId: widget.cycleId,
          type: widget.type,
          action: action,
          category: category,
          onCategoryChanged: _fetchCategories,
        );
      },
    );
  }
}
