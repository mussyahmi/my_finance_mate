import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
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
            child: PhotoView(
              imageProvider: _getImageProvider(),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 1.8,
            ),
          ),
          if (_adMobService.status)
            AdContainer(
              adMobService: _adMobService,
              adSize: AdSize.fullBanner,
              adUnitId: _adMobService.bannerImageViewAdUnitId!,
              height: 60.0,
            ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (widget.type == 'url') {
      //* If imageSource is a String, treat it as a URL
      return NetworkImage(widget.imageSource);
    } else if (widget.type == 'local') {
      //* If imageSource is a File, treat it as a local file path
      return FileImage(File(widget.imageSource));
    }

    throw ArgumentError('Invalid image source type');
  }
}
