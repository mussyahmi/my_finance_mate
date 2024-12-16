import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/person_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';
import 'transaction_list_page.dart';

class CategorySummaryPage extends StatefulWidget {
  const CategorySummaryPage({super.key});

  @override
  State<CategorySummaryPage> createState() => _CategorySummaryPageState();
}

class _CategorySummaryPageState extends State<CategorySummaryPage> {
  bool _isLoading = false;
  late AdMobService _adMobService;
  late AdCacheService _adCacheService;
  InterstitialAd? _interstitialAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _adCacheService = context.read<AdCacheService>();

    if (!context.read<PersonProvider>().user!.isPremium) {
      _createInterstitialAd();
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const Text('Category Summary'),
              centerTitle: true,
              scrolledUnderElevation: 9999,
              floating: true,
              snap: true,
              actions: [
                if (false)
                  // ignore: dead_code
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ))
                        : const Icon(CupertinoIcons.refresh),
                    onPressed: () async {
                      if (_isLoading) return;

                      setState(() {
                        _isLoading = true;
                      });

                      if (!context.read<PersonProvider>().user!.isPremium) {
                        _showInterstitialAd();
                      }

                      await context
                          .read<CategoriesProvider>()
                          .recalculateCategoryAndCycleTotalAmount(context);

                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
              ],
            ),
          ],
          body: Center(
            child: FutureBuilder(
              future: context
                  .watch<CategoriesProvider>()
                  .getCategories(context, null, 'category_summary'),
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
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      Category category = categories[index] as Category;

                      return Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Card(
                              child: ListTile(
                                title: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                trailing: Text(
                                  '${category.type == 'spent' ? '-' : ''}RM${category.totalAmount}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: category.type == 'spent'
                                          ? Colors.red
                                          : Colors.green),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransactionListPage(
                                          type: category.type,
                                          categoryId: category.id),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (!context.read<PersonProvider>().user!.isPremium &&
                              (index == 1 || index == 7 || index == 13))
                            AdContainer(
                              adCacheService: _adCacheService,
                              number: index,
                              adSize: AdSize.banner,
                              adUnitId:
                                  _adMobService.bannerCategorySummaryAdUnitId!,
                              height: 50.0,
                            ),
                          if (index == categories.length - 1)
                            const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adMobService.interstitialRecalculateAdUnitId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );

      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }
}
