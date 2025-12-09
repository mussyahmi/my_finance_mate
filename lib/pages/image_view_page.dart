// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

import '../providers/person_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';

class ImageViewPage extends StatefulWidget {
  final List<dynamic> files;
  final int index;

  const ImageViewPage({super.key, required this.files, required this.index});

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  AdMobService? _adMobService;
  AdCacheService? _adCacheService;
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!kIsWeb) {
      _adMobService = context.read<AdMobService>();
      _adCacheService = context.read<AdCacheService>();
    }
  }

  Future<void> _downloadImage() async {
    try {
      final currentFile = widget.files[_currentIndex];

      EasyLoading.show(
        dismissOnTap: false,
        status: 'Checking permissions...',
      );

      bool isAndroid13OrAbove = false;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;
      }

      PermissionStatus permissionStatus;
      if (isAndroid13OrAbove) {
        permissionStatus = await Permission.photos.request();
      } else {
        permissionStatus = await Permission.storage.request();
      }

      if (!permissionStatus.isGranted) {
        EasyLoading.showError(
            'Permission denied. Please allow access to continue.');
        return;
      }

      EasyLoading.show(
        dismissOnTap: false,
        status: 'Preparing download...',
      );

      final dir = await getExternalStorageDirectory();
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpeg";
      final savePath = '${dir!.path}/$fileName';

      final dio = Dio();

      await dio.download(
        currentFile,
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
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Text(e.type.message),
              ),
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
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Text(e.toString()),
            ),
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: Text('Attachments'),
                centerTitle: true,
                scrolledUnderElevation: 9999,
                floating: true,
                snap: true,
                actions: [
                  if (!kIsWeb && widget.files[_currentIndex] is String)
                    IconButton(
                      icon: Icon(Icons.download),
                      onPressed: _downloadImage,
                    ),
                ],
              ),
            ],
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PhotoViewGallery.builder(
                          pageController: _pageController,
                          itemCount: widget.files.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          builder: (context, index) {
                            final file = widget.files[index];
                            final isUrl = file is String;
                            final isWebFile = !isUrl && kIsWeb;

                            return PhotoViewGalleryPageOptions.customChild(
                              child: isUrl
                                  ? CachedNetworkImage(
                                      imageUrl: file,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    )
                                  : isWebFile
                                      ? Image.memory(
                                          file.bytes!, // Web uses bytes
                                          fit: BoxFit.contain,
                                        )
                                      : Image.file(File(file.path)),
                              initialScale: PhotoViewComputedScale.contained,
                              minScale: PhotoViewComputedScale.contained * 0.8,
                              maxScale: PhotoViewComputedScale.covered * 1.8,
                            );
                          },
                        ),
                      ),
                      if (widget.files.length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.files.length} attachments',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_adMobService != null &&
                    !context.read<PersonProvider>().user!.isPremium)
                  AdContainer(
                    adCacheService: _adCacheService!,
                    number: 1,
                    adSize: AdSize.banner,
                    adUnitId: _adMobService!.bannerImageViewAdUnitId!,
                    height: 50.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
