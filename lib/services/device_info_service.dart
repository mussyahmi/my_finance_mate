import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

Future<String> getDeviceInfoJson() async {
  String deviceInfoJson = '';
  Map<String, dynamic> deviceInfoMap = {};

  final deviceInfoPlugin = DeviceInfoPlugin();

  if (kIsWeb) {
    final deviceInfo = await deviceInfoPlugin.webBrowserInfo;
    deviceInfoMap = {
      'appCodeName': deviceInfo.appCodeName,
      'appName': deviceInfo.appName,
      'appVersion': deviceInfo.appVersion,
      'deviceMemory': deviceInfo.deviceMemory,
      'language': deviceInfo.language,
      'platform': deviceInfo.platform,
      'product': deviceInfo.product,
      'productSub': deviceInfo.productSub,
      'userAgent': deviceInfo.userAgent,
      'vendor': deviceInfo.vendor,
      'vendorSub': deviceInfo.vendorSub,
      'maxTouchPoints': deviceInfo.maxTouchPoints,
      'hardwareConcurrency': deviceInfo.hardwareConcurrency,
    };
  } else {
    if (Platform.isAndroid) {
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      deviceInfoMap = {
        'version': {
          'baseOS': deviceInfo.version.baseOS,
          'codename': deviceInfo.version.codename,
          'incremental': deviceInfo.version.incremental,
          'previewSdkInt': deviceInfo.version.previewSdkInt,
          'release': deviceInfo.version.release,
          'sdkInt': deviceInfo.version.sdkInt,
          'securityPatch': deviceInfo.version.securityPatch,
        },
        'brand': deviceInfo.brand,
        'device': deviceInfo.device,
        'model': deviceInfo.model,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
      };
    } else if (Platform.isIOS) {
      final deviceInfo = await deviceInfoPlugin.iosInfo;
      deviceInfoMap = {
        'name': deviceInfo.name,
        'systemName': deviceInfo.systemName,
        'systemVersion': deviceInfo.systemVersion,
        'model': deviceInfo.model,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
      };
    }
  }

  deviceInfoJson = jsonEncode(deviceInfoMap);
  return deviceInfoJson;
}
