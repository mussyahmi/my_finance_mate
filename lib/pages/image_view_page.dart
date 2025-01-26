import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../providers/person_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';

class ImageViewPage extends StatefulWidget {
  final dynamic imageSource;
  final String type;

  const ImageViewPage(
      {super.key, required this.imageSource, required this.type});

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  late AdMobService _adMobService;
  late AdCacheService _adCacheService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _adCacheService = context.read<AdCacheService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // TODO: add download image button for type = url
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PhotoView.customChild(
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 1.8,
              child: widget.type == 'url'
                  ? CachedNetworkImage(
                      imageUrl: widget.imageSource,
                      placeholder: (context, url) => Center(
                        child:
                            CircularProgressIndicator(), // Placeholder while loading
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error), // Error widget
                    )
                  : Image.file(File(widget.imageSource)),
            ),
          ),
          if (!context.read<PersonProvider>().user!.isPremium)
            AdContainer(
              adCacheService: _adCacheService,
              number: 1,
              adSize: AdSize.banner,
              adUnitId: _adMobService.bannerImageViewAdUnitId!,
              height: 50.0,
            ),
        ],
      ),
    );
  }
}
