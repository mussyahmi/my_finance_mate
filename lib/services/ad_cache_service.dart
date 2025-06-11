import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdCacheService {
  final Map<String, BannerAd> _adCache = {};

  BannerAd getCachedAd({
    required int number,
    required String adUnitId,
    required AdSize adSize,
    required BannerAdListener listener,
  }) {
    //* Use a unique key for each ad based on its properties
    final String cacheKey =
        '$adUnitId-${adSize.width}x${adSize.height}-$number';

    if (_adCache.containsKey(cacheKey) && !kDebugMode) {
      return _adCache[cacheKey]!;
    }

    //* Create a new ad and cache it
    final BannerAd newAd = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      listener: listener,
      request: const AdRequest(),
    )..load();

    _adCache[cacheKey] = newAd;
    return newAd;
  }

  void disposeAllAds() {
    for (var ad in _adCache.values) {
      ad.dispose();
    }
    _adCache.clear();
  }

  void disposeAd(String adUnitId, AdSize adSize) {
    final String cacheKey = '$adUnitId-${adSize.width}x${adSize.height}';
    _adCache[cacheKey]?.dispose();
    _adCache.remove(cacheKey);
  }
}
