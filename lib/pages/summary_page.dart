import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/cycle.dart';
import '../services/ad_mob_service.dart';
import 'transaction_list_page.dart';

class SummaryPage extends StatefulWidget {
  final Cycle cycle;

  const SummaryPage({super.key, required this.cycle});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  List<Object> categories = [];
  bool _isLoading = false;

  //* Ad related
  late AdMobService _adMobService;
  InterstitialAd? _interstitialAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final List<Category> fetchCategories =
        await Category.fetchCategories(widget.cycle.id, null);

    setState(() {
      categories = List.from(fetchCategories
          .where((element) => double.parse(element.totalAmount) > 0)
          .toList());

      _adMobService = context.read<AdMobService>();

      if (_adMobService.status) {
        _adMobService.initialization.then(
          (value) {
            _createInterstitialAd();

            for (var i = 2; i < categories.length; i += 7) {
              categories.insert(
                  i,
                  BannerAd(
                    size: AdSize.banner,
                    adUnitId: _adMobService.bannerCategorySummaryAdUnitId!,
                    listener: _adMobService.bannerAdListener,
                    request: const AdRequest(),
                  )..load());

              if (i >= 16) {
                //* max 3 ads
                break;
              }
            }
          },
        );
      }
    });
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

                    await Category.recalculateCategoryAndCycleTotalAmount(
                        widget.cycle.id);

                    setState(() {
                      _isLoading = false;
                    });
                  },
                ),
              ],
            ),
          ],
          body: ListView.builder(
            shrinkWrap: true,
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
                                cycle: widget.cycle,
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
