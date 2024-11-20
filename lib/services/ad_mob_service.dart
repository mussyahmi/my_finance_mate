// ignore_for_file: avoid_print

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
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/1369933128';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerProfileAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/7085332225';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/9958019527';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerCategoryListAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/3473390270';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/3042145435';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerImageViewAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/3167102668';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/4755516500';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerWishlistAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/1905991881';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/1152109571';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerCycleAddAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/1942485058';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/9960537885';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerCategorySummaryAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/8368007197';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/6009437164';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerChartAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/3677672588';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/3545810642';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerTransactionLatestAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/3543609517';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/2230527847';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerTransactionFilteredAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/1818903226';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/9505821551';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerTransactionFormAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/9342731103';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/7103019491';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerCycleAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/5095803253';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/8404492876';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerCycleListAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/5196005484';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/5307686125';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerCycleLatestAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/1811164362';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/3016434822';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
  }

  String? get bannerAccountListAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/2929537430';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/1616455769';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    return null;
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
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/6872691188';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }

    return null;
  }

  String? get interstitialRecalculateAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/9413742970';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/3602216938';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }

    return null;
  }

  String? get appOpenAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784/1185605452';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784/3699200107';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/9257395921';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/5575463023';
      }
    }

    return null;
  }

  String? get rewardedAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2773996115717784~4330288324';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2773996115717784~4499192177';
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    }

    return null;
  }
}
