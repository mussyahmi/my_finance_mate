import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/person.dart';
import 'dashboard_page.dart';
import '../extensions/firestore_extensions.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    //* Toggle the password visibility when the button is pressed
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                if (_isLoading) return;

                setState(() {
                  _isLoading = true;
                });

                try {
                  await _register(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getDeviceInfoJson() async {
    //* Get device information
    String deviceInfoJson = '';
    Map<String, dynamic> deviceInfoMap = {};

    if (Platform.isAndroid) {
      AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;

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
        'displayMetrics': {
          'widthPx': deviceInfo.displayMetrics.widthPx,
          'heightPx': deviceInfo.displayMetrics.heightPx,
          'xDpi': deviceInfo.displayMetrics.xDpi,
          'yDpi': deviceInfo.displayMetrics.yDpi,
        },
        'serialNumber': deviceInfo.serialNumber,
      };

      //* Convert device info to JSON
      deviceInfoJson = jsonEncode(deviceInfoMap);
    } else if (Platform.isIOS) {
      IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;

      deviceInfoMap = {
        'name': deviceInfo.name,
        'systemName': deviceInfo.systemName,
        'systemVersion': deviceInfo.systemVersion,
        'model': deviceInfo.model,
        'localizedModel': deviceInfo.localizedModel,
        'identifierForVendor': deviceInfo.identifierForVendor,
        'isPhysicalDevice': deviceInfo.isPhysicalDevice,
        'utsname': {
          'sysname': deviceInfo.utsname.sysname,
          'nodename': deviceInfo.utsname.nodename,
          'release': deviceInfo.utsname.release,
          'version': deviceInfo.utsname.version,
          'machine': deviceInfo.utsname.machine,
        },
      };

      //* Convert device info to JSON
      deviceInfoJson = jsonEncode(deviceInfoMap);
    }

    return deviceInfoJson;
  }

  Future<void> _register(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return;
      }

      final UserCredential authResult =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        //* Check if the user already exists in the Firestore collection
        final userRef = FirebaseFirestore.instance.collection('users');

        //* Get current timestamp
        final now = DateTime.now();

        //* Get device information
        final deviceInfoJson = await _getDeviceInfoJson();

        //* Add the user to the collection with UID as the document ID
        await userRef.doc(authResult.user!.uid).set({
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
          'email': authResult.user!.email,
          'full_name': authResult.user!.displayName,
          'last_login': now,
          'nickname': authResult.additionalUserInfo!.profile!['given_name'],
          'photo_url': authResult.user!.photoURL,
          'device_info_json': deviceInfoJson,
          'password': password,
          'daily_transactions_made': 0,
        });

        final userDoc = await userRef.doc(authResult.user!.uid).getSavy();

        Person person = Person(
          uid: userDoc.id,
          fullName: userDoc['full_name'] ?? '',
          nickname: userDoc['nickname'] ?? '',
          email: userDoc['email'],
          photoUrl: userDoc['photo_url'] ?? '',
          lastLogin: (userDoc['last_login'] as Timestamp).toDate(),
          dailyTransactionsMade: userDoc['daily_transactions_made'],
        );

        //* Navigate to the dashboard or home page upon successful register
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardPage(user: person)),
          (route) =>
              false, //* This line removes all previous routes from the stack
        );
      }
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('Email/Password Sign-In Error: $e');
    }
  }
}
