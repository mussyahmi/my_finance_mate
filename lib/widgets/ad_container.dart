// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_cache_service.dart';

class AdContainer extends StatefulWidget {
  final AdCacheService adCacheService;
  final int number;
  final String adUnitId;
  final AdSize adSize;
  final double height;

  const AdContainer({
    super.key,
    required this.adCacheService,
    required this.number,
    required this.adUnitId,
    required this.adSize,
    required this.height,
  });

  @override
  State<AdContainer> createState() => _AdContainerState();
}

class _AdContainerState extends State<AdContainer> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAsync();
  }

  Future<void> _initAsync() async {
    final ad = await widget.adCacheService.getCachedAd(
      number: widget.number,
      adUnitId: widget.adUnitId,
      adSize: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!kReleaseMode) print('Ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          if (!kReleaseMode) print('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    setState(() {
      _bannerAd = ad;
      _isAdLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(height: widget.height);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      height: widget.height,
      child: AdWidget(
        key: Key(
            '${widget.adUnitId}-${widget.adSize.width}x${widget.adSize.height}-${widget.number}'),
        ad: _bannerAd!,
      ),
    );
  }
}
