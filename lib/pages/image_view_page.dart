// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _downloadImage() async {
    if (widget.type != 'url') return;

    try {
      // Show loading indicator
      EasyLoading.show(status: 'Checking permissions...');

      // Determine Android SDK version
      bool isAndroid13OrAbove = false;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;
      }

      // TODO: iOS permission handling

      // Request appropriate permission
      PermissionStatus permissionStatus;
      if (isAndroid13OrAbove) {
        permissionStatus = await Permission.photos.request();
      } else {
        permissionStatus = await Permission.storage.request();
      }

      // Handle permission denied
      if (!permissionStatus.isGranted) {
        EasyLoading.showError(
            'Permission denied. Please allow access to continue.');
        return;
      }

      // Proceed with download
      EasyLoading.show(status: 'Preparing download...');

      final dir = await getExternalStorageDirectory();
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpeg";
      final savePath = '${dir!.path}/$fileName';

      final dio = Dio();

      await dio.download(
        widget.imageSource,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            EasyLoading.showProgress(
              progress,
              status: 'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      try {
        await Gal.putImage(savePath, album: "My Finance Mate");
        EasyLoading.showSuccess('Image saved to gallery!');
        return;
      } on GalException catch (e) {
        EasyLoading.dismiss();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Download Failed!'),
              content: Text(e.type.message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    } catch (e) {
      EasyLoading.dismiss();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Download Failed!'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.type == 'url')
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _downloadImage,
            ),
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
