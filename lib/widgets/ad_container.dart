import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_mob_service.dart';

class AdContainer extends StatefulWidget {
  final AdMobService adMobService;
  final AdSize adSize;
  final String adUnitId;
  final double height;

  const AdContainer({
    super.key,
    required this.adMobService,
    required this.adSize,
    required this.adUnitId,
    required this.height,
  });

  @override
  State<AdContainer> createState() => _AdContainerState();
}

class _AdContainerState extends State<AdContainer> {
  BannerAd? _bannerAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      _bannerAd = BannerAd(
        size: widget.adSize,
        adUnitId: widget.adUnitId,
        listener: widget.adMobService.bannerAdListener,
        request: const AdRequest(),
      )..load();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      height: widget.height,
      child: _bannerAd != null
          ? AdWidget(
              ad: _bannerAd!,
            )
          : Container(),
    );
  }
}
