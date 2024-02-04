// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_mob_service.dart';
import '../models/category.dart';
import 'summary_page.dart';
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
  List<Object> spentCategories = [];
  List<Object> receivedCategories = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromTransactionForm != null) {
        Category.showCategoryFormDialog(
            context, widget.cycleId, selectedType, 'Add', _fetchCategories);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      spentCategories = [];
      receivedCategories = [];
    });

    final fetchedSpentCategories =
        await Category.fetchCategories(widget.cycleId, 'spent');
    final fetchedReceivedCategories =
        await Category.fetchCategories(widget.cycleId, 'received');

    setState(() {
      spentCategories = List.from(fetchedSpentCategories);
      receivedCategories = List.from(fetchedReceivedCategories);

      final adMobService = context.read<AdMobService>();
      adMobService.initialization.then((value) {
        for (var i = 2; i < spentCategories.length; i += 7) {
          spentCategories.insert(
              i,
              BannerAd(
                size: AdSize.banner,
                adUnitId: adMobService.bannerCategoryListAdUnitId!,
                listener: adMobService.bannerAdListener,
                request: const AdRequest(),
              )..load());

          if (i >= 16) {
            //* max 3 ads
            break;
          }
        }

        for (var i = 2; i < receivedCategories.length; i += 7) {
          receivedCategories.insert(
              i,
              BannerAd(
                size: AdSize.banner,
                adUnitId: adMobService.bannerCategoryListAdUnitId!,
                listener: adMobService.bannerAdListener,
                request: const AdRequest(),
              )..load());

          if (i >= 16) {
            //* max 3 ads
            break;
          }
        }
      });
    });
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
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    title: const Text('Category List'),
                    centerTitle: true,
                    scrolledUnderElevation: 9999,
                    floating: true,
                    snap: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.analytics),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    SummaryPage(cycleId: widget.cycleId)),
                          );
                        },
                      ),
                    ],
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
                ],
                body: TabBarView(
                  children: [
                    _buildCategoryList(context, spentCategories),
                    _buildCategoryList(context, receivedCategories),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Category.showCategoryFormDialog(context, widget.cycleId,
                      selectedType, 'Add', _fetchCategories);
                },
                icon: const Icon(Icons.add),
                label: const Text('Category'),
              ),
            );
          },
        ));
  }

  ListView _buildCategoryList(BuildContext context, List<Object> categories) {
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
                trailing: IconButton(
                    onPressed: () => category.showCategorySummaryDialog(
                        context, selectedType, _fetchCategories),
                    icon: const Icon(Icons.info)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionListPage(
                        cycleId: widget.cycleId,
                        type: selectedType,
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
