import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../services/ad_mob_service.dart';
import 'transaction_list_page.dart';

class SummaryPage extends StatefulWidget {
  final String cycleId;

  const SummaryPage({super.key, required this.cycleId});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isLoading = false;

  //* Ad related
  late AdMobService _adMobService;
  InterstitialAd? _interstitialAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _adMobService.initialization.then((value) {
      setState(() {
        _createInterstitialAd();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Summary'),
        centerTitle: true,
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

              _showInterstitialAd();

              await Category.recalculateCategoryAndCycleTotalAmount(
                  widget.cycleId);

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('refresh_dashboard', true);

              setState(() {
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: Category.fetchCategories(widget.cycleId, null),
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
                  final categories = snapshot.data!
                      .where((category) => category.totalAmount != '0.00')
                      .toList();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];

                            return ListTile(
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
                                        cycleId: widget.cycleId,
                                        type: category.type,
                                        categoryName: category.name),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  );
                }
              },
            ),
          ),
        ],
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
