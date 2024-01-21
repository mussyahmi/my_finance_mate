// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_mob_service.dart';
import '../widgets/category_dialog.dart';
import '../models/category.dart';
import 'transaction_list_page.dart';

class CategoryListPage extends StatefulWidget {
  final String cycleId;
  final String? type;
  final bool? isFromTransactionForm;

  const CategoryListPage(
      {super.key,
      required this.cycleId,
      this.type,
      this.isFromTransactionForm});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late String selectedType = widget.type ?? 'spent'; //* Use for initialIndex

  //* Ad related
  late AdMobService _adMobService;
  BannerAd? _bannerAdSpent;
  BannerAd? _bannerAdReceived;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromTransactionForm != null) {
        _showCategoryDialog(context, 'Add');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _adMobService.initialization.then((value) {
      setState(() {
        _bannerAdSpent = BannerAd(
          size: AdSize.fullBanner,
          adUnitId: _adMobService.bannerCategoryListAdUnitId!,
          listener: _adMobService.bannerAdListener,
          request: const AdRequest(),
        )..load();
        _bannerAdReceived = BannerAd(
          size: AdSize.fullBanner,
          adUnitId: _adMobService.bannerCategoryListAdUnitId!,
          listener: _adMobService.bannerAdListener,
          request: const AdRequest(),
        )..load();
      });
    });
  }

  Future<List<Category>> _fetchCategories(String type) async {
    final fetchedCategories =
        await Category.fetchCategories(widget.cycleId, type);

    return fetchedCategories;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: selectedType == 'spent' ? 0 : 1,
        length: 2,
        child: Builder(
          builder: (context) {
            final TabController tabController =
                DefaultTabController.of(context);

            tabController.addListener(() {
              if (!tabController.indexIsChanging) {
                selectedType = tabController.index == 0 ? 'spent' : 'received';
              }
            });

            return Scaffold(
              appBar: AppBar(
                title: const Text('Category List'),
                centerTitle: true,
                bottom: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.file_upload_outlined),
                      text: 'Spent',
                    ),
                    Tab(
                      icon: Icon(Icons.file_download_outlined),
                      text: 'Received',
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _futureBuilder('spent'),
                  _futureBuilder('received'),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  _showCategoryDialog(context, 'Add');
                },
                icon: const Icon(Icons.add),
                label: const Text('Category'),
              ),
            );
          },
        ));
  }

  FutureBuilder<List<Category>> _futureBuilder(String type) {
    return FutureBuilder(
      future: _fetchCategories(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ); //* Display a loading indicator
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SelectableText(
              'Error: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'No categories found.',
              textAlign: TextAlign.center,
            ),
          ); //* Display a message for no categories
        } else {
          return Column(
            children: [
              if (type == 'spent' && _bannerAdSpent != null)
                SizedBox(
                  height: 60.0,
                  child: AdWidget(ad: _bannerAdSpent!),
                ),
              if (type == 'received' && _bannerAdReceived != null)
                SizedBox(
                  height: 60.0,
                  child: AdWidget(ad: _bannerAdReceived!),
                ),
              Expanded(child: _buildCategoryList(context, snapshot.data!)),
            ],
          );
        }
      },
    );
  }

  SingleChildScrollView _buildCategoryList(
      BuildContext context, List<Category> categories) {
    return SingleChildScrollView(
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
                                              .collection('categories');
                                          final categoryRef =
                                              categoriesRef.doc(categoryId);

                                          //* Update the 'deleted_at' field with the current timestamp
                                          final now = DateTime.now();
                                          categoryRef.update({
                                            'updated_at': now,
                                            'deleted_at': now,
                                          });

                                          SharedPreferences prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          await prefs.setBool(
                                              'refresh_dashboard', true);

                                          setState(() {}); //* Refresh

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
                                type: selectedType,
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
          type: selectedType,
          action: action,
          category: category,
          onCategoryChanged: () {
            setState(() {}); //* Refresh
          },
        );
      },
    );
  }
}
