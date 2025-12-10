import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

Future<Map<String, dynamic>> getDeviceInfoJson() async {
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
        'board': deviceInfo.board,
        'bootloader': deviceInfo.bootloader,
        'brand': deviceInfo.brand,
        'device': deviceInfo.device,
        'display': deviceInfo.display,
        'fingerprint': deviceInfo.fingerprint,
        'hardware': deviceInfo.hardware,
        'host': deviceInfo.host,
        'id': deviceInfo.id,
        'manufacturer': deviceInfo.manufacturer,
        'model': deviceInfo.model,
        'product': deviceInfo.product,
        'tags': deviceInfo.tags,
        'type': deviceInfo.type,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
        'serialNumber': deviceInfo.serialNumber,
        'isLowRamDevice': deviceInfo.isLowRamDevice,
      };
    } else if (Platform.isIOS) {
      final deviceInfo = await deviceInfoPlugin.iosInfo;
      deviceInfoMap = {
        'name': deviceInfo.name,
        'systemName': deviceInfo.systemName,
        'systemVersion': deviceInfo.systemVersion,
        'model': deviceInfo.model,
        'modelName': deviceInfo.modelName,
        'localizedModel': deviceInfo.localizedModel,
        'identifierForVendor': deviceInfo.identifierForVendor,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
        'isiOSAppOnMac': deviceInfo.isiOSAppOnMac,
        'utsname': {
          'sysname': deviceInfo.utsname.sysname,
          'nodename': deviceInfo.utsname.nodename,
          'release': deviceInfo.utsname.release,
          'version': deviceInfo.utsname.version,
          'machine': deviceInfo.utsname.machine,
        },
      };
    }
  }

  return deviceInfoMap;
}
