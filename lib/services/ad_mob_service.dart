import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  Future<InitializationStatus> initialization;

  AdMobService(this.initialization);

  String? get bannerDasboardAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/5125345305';
      } else {
        return 'ca-app-pub-2773996115717784/1369933128';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }
  }

  final BannerAdListener bannerAdListener = BannerAdListener(
    onAdLoaded: (ad) => print('Ad loaded'),
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
      print('Ad failed to load: $error');
    },
    onAdOpened: (ad) => print('Ad opened'),
    onAdClosed: (ad) => print('Ad closed'),
  );

  String? get interstitialTransactionFormAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/4410179371';
      } else {
        return 'ca-app-pub-2773996115717784/6872691188';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }
  }
}
