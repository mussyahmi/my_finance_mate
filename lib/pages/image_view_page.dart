import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewPage extends StatelessWidget {
  final dynamic imageSource;
  final String type;

  const ImageViewPage(
      {super.key, required this.imageSource, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: PhotoView(
          imageProvider: _getImageProvider(),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 1.8,
        ),
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (type == 'url') {
      //* If imageSource is a String, treat it as a URL
      return NetworkImage(imageSource);
    } else if (type == 'local') {
      //* If imageSource is a File, treat it as a local file path
      return FileImage(File(imageSource));
    }

    throw ArgumentError('Invalid image source type');
  }
}
