import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'subcategory_dialog.dart';

class SubcategoryListPage extends StatefulWidget {
  final String cycleId;
  final String categoryId;
  final String categoryName;

  const SubcategoryListPage({
    super.key,
    required this.cycleId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubcategoryListPage> createState() => _SubcategoryListPageState();
}

class _SubcategoryListPageState extends State<SubcategoryListPage> {
  List<Map<String, dynamic>> subcategories = [];

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
  }

  Future<void> _fetchSubcategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
    final categoriesRef =
        cyclesRef.collection('categories').doc(widget.categoryId);
    final subcategoriesRef = categoriesRef.collection('subcategories');

    final subcategoriesSnapshot =
        await subcategoriesRef.where('deleted_at', isNull: true).get();

    final fetchedSubcategories = subcategoriesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'budget': doc['budget'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by 'created_at' in ascending order (most recent last)
    fetchedSubcategories.sort((a, b) =>
        (a['created_at'] as DateTime).compareTo((b['created_at'] as DateTime)));

    setState(() {
      subcategories = fetchedSubcategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: subcategories.map((subcategory) {
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
                      title: Text(subcategory['name']),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            //* Handle edit option
                            _showSubcategoryDialog(context, 'Edit',
                                subcategory: subcategory);
                          } else if (value == 'delete') {
                            //* Handle delete option
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text(
                                      'Are you sure you want to delete "${subcategory['name']}"?'),
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
                                        final subcategoryId = subcategory['id'];

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
                                        final cyclesRef = userRef
                                            .collection('cycles')
                                            .doc(widget.cycleId);
                                        final categoriesRef = cyclesRef
                                            .collection('categories')
                                            .doc(widget.categoryId);
                                        final subcategoriesRef = categoriesRef
                                            .collection('subcategories')
                                            .doc(subcategoryId);

                                        //* Update the 'deleted_at' field with the current timestamp
                                        final now = DateTime.now();
                                        subcategoriesRef
                                            .update({'deleted_at': now});

                                        _fetchSubcategories();

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
          _showSubcategoryDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //* Function to show the add category dialog
  void _showSubcategoryDialog(BuildContext context, String action,
      {Map? subcategory}) {
    showDialog(
      context: context,
      builder: (context) {
        return SubcategoryDialog(
          cycleId: widget.cycleId,
          categoryId: widget.categoryId,
          action: action,
          subcategory: subcategory ?? {},
          onSubcategoryChanged: _fetchSubcategories,
        );
      },
    );
  }
}
