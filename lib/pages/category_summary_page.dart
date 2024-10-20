import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../services/ad_mob_service.dart';
import 'transaction_list_page.dart';

class CategorySummaryPage extends StatefulWidget {
  const CategorySummaryPage({super.key});

  @override
  State<CategorySummaryPage> createState() => _CategorySummaryPageState();
}

class _CategorySummaryPageState extends State<CategorySummaryPage> {
  bool _isLoading = false;

  //* Ad related
  late AdMobService _adMobService;
  InterstitialAd? _interstitialAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _createInterstitialAd();
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
                        : const Icon(Icons.refresh),
                    onPressed: () async {
                      if (_isLoading) return;

                      setState(() {
                        _isLoading = true;
                      });

                      if (_adMobService.status) _showInterstitialAd();

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
                      if (categories[index] is SizedBox) {
                        return categories[index] as SizedBox;
                      } else if (categories[index] is BannerAd) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          height: 50.0,
                          child: AdWidget(ad: categories[index] as BannerAd),
                        );
                      } else {
                        Category category = categories[index] as Category;
            
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                category.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
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
                                        categoryName: category.name),
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
