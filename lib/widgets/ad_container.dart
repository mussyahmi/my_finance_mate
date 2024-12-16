// ignore_for_file: avoid_print

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
  late BannerAd _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = widget.adCacheService.getCachedAd(
      number: widget.number,
      adUnitId: widget.adUnitId,
      adSize: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      height: widget.height,
      child: AdWidget(
        key: Key(
            '${widget.adUnitId}-${widget.adSize.width}x${widget.adSize.height}-${widget.number}'),
        ad: _bannerAd,
      ),
    );
  }
}
