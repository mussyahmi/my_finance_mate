import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoSummary extends StatefulWidget {
  final bool canPress;

  const PackageInfoSummary({super.key, required this.canPress});

  @override
  State<PackageInfoSummary> createState() => _PackageInfoSummaryState();
}

class _PackageInfoSummaryState extends State<PackageInfoSummary> {
  bool _showPackageInfo = false;

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Widget _infoTile(String title, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle.isEmpty ? 'Not set' : subtitle,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canPress) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          'My Finance Mate v ${_packageInfo.version}',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              _showPackageInfo = !_showPackageInfo;
            });
          },
          child: Text(
            'My Finance Mate v ${_packageInfo.version}',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        if (_showPackageInfo)
          Column(
            children: [
              _infoTile('App name', _packageInfo.appName),
              _infoTile('Package name', _packageInfo.packageName),
              _infoTile('App version', _packageInfo.version),
              _infoTile('Build number', _packageInfo.buildNumber),
              _infoTile('Build signature', _packageInfo.buildSignature),
              _infoTile(
                'Installer store',
                _packageInfo.installerStore ?? 'not available',
              ),
            ],
          )
      ],
    );
  }
}
