import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_dialog.dart';
import 'subcategory_list_page.dart';

class CategoryListPage extends StatefulWidget {
  final String cycleId;

  const CategoryListPage({super.key, required this.cycleId});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
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

    final categoriesSnapshot =
        await categoriesRef.where('deleted_at', isNull: true).get();

    final fetchedCategories = categoriesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by 'created_at' in ascending order (most recent last)
    fetchedCategories.sort((a, b) =>
        (a['created_at'] as DateTime).compareTo((b['created_at'] as DateTime)));

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
            children: categories.map((category) {
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
                      title: Text(category['name']),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            //* Handle edit option
                            _showCategoryDialog(context, 'Edit',
                                category: category);
                          } else if (value == 'delete') {
                            //* Handle delete option
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          'Are you sure you want to delete this category?'),
                                      SizedBox(height: 20),
                                      Text(
                                        'This action will delete all subcategories associated with it as well.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      )
                                    ],
                                  ),
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
                                        final categoryId = category['id'];

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
                                        final categoriesRef =
                                            cyclesRef.collection('categories');
                                        final categoryRef =
                                            categoriesRef.doc(categoryId);

                                        //* Update the 'deleted_at' field with the current timestamp
                                        final now = DateTime.now();
                                        categoryRef.update({'deleted_at': now});

                                        _fetchCategories();

                                        // ignore: use_build_context_synchronously
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubcategoryListPage(
                                  cycleId: widget.cycleId,
                                  categoryId: category['id'],
                                  categoryName: category['name'])),
                        );
                      },
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
          _showCategoryDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //* Function to show the add category dialog
  void _showCategoryDialog(BuildContext context, String action,
      {Map? category}) {
    showDialog(
      context: context,
      builder: (context) {
        return CategoryDialog(
          cycleId: widget.cycleId,
          action: action,
          category: category ?? {},
          onCategoryChanged: (categoryName) {
            _fetchCategories();
          },
        );
      },
    );
  }
}
