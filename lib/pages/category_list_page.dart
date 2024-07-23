// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../services/ad_mob_service.dart';
import '../models/category.dart';

class CategoryListPage extends StatefulWidget {
  final Cycle cycle;
  final String? type;
  final bool? isFromTransactionForm;

  const CategoryListPage(
      {super.key, required this.cycle, this.type, this.isFromTransactionForm});

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
            context, widget.cycle.id, selectedType, 'Add', _fetchCategories);
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
        await Category.fetchCategories(widget.cycle.id, 'spent');
    final fetchedReceivedCategories =
        await Category.fetchCategories(widget.cycle.id, 'received');

    setState(() {
      spentCategories = List.from(fetchedSpentCategories);
      receivedCategories = List.from(fetchedReceivedCategories);

      final adMobService = context.read<AdMobService>();

      if (adMobService.status) {
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
      }
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
                    _buildCategoryList(context, spentCategories),
                    _buildCategoryList(context, receivedCategories),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Category.showCategoryFormDialog(context, widget.cycle.id,
                      selectedType, 'Add', _fetchCategories);
                },
                child: const Icon(Icons.add),
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
                onTap: () {
                  category.showCategoryDetails(
                      context, widget.cycle, selectedType, _fetchCategories);
                },
              ),
            ),
          );
        }
      },
    );
  }
}
