// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../providers/categories_provider.dart';
import '../models/category.dart';
import '../providers/cycle_provider.dart';

class CategoryListPage extends StatefulWidget {
  final String? type;
  final bool? isFromTransactionForm;

  const CategoryListPage({
    super.key,
    this.type,
    this.isFromTransactionForm,
  });

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late String selectedType = widget.type ?? 'spent'; //* Use for initialIndex

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromTransactionForm != null) {
        Category.showCategoryFormDialog(context, selectedType, 'Add');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Cycle cycle = context.watch<CycleProvider>().cycle!;

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
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  const SliverAppBar(
                    title: Text('Category List'),
                    centerTitle: true,
                    scrolledUnderElevation: 9999,
                    floating: true,
                    snap: true,
                    bottom: TabBar(
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
                ],
                body: TabBarView(
                  children: [
                    _buildCategoryList(context, cycle, 'spent'),
                    _buildCategoryList(context, cycle, 'received'),
                  ],
                ),
              ),
            );
          },
        ));
  }

  Widget _buildCategoryList(BuildContext context, Cycle cycle, String type) {
    return Center(
      child: FutureBuilder(
        future: context
            .watch<CategoriesProvider>()
            .getCategories(context, type, 'category_list'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
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
            //* Display the list of categories
            final categories = snapshot.data!;
      
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                if (categories[index] is BannerAd) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    height: 50.0,
                    child: AdWidget(ad: categories[index] as BannerAd),
                  );
                } else {
                  Category category = categories[index] as Category;
      
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    margin: index == categories.length - 1
                        ? const EdgeInsets.only(bottom: 80)
                        : null,
                    child: Card(
                      child: ListTile(
                        title: Text(category.name),
                        onTap: () {
                          category.showCategoryDetails(
                              context, cycle, selectedType);
                        },
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
