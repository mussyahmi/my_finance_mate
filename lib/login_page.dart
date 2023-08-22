// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false; //* Track the loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to My Finance Mate!',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            //* Show a circular progress indicator while loading
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading)
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true; //* Set loading state to true
                  });

                  try {
                    //* Use the context from the Builder widget
                    await _signInWithGoogle(context);
                  } finally {
                    setState(() {
                      _isLoading = false; //* Set loading state to false
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign In with Google'),
              ),
            // const ElevatedButton(
            //   onPressed: _signOut,
            //   child: Text('Sign Out'),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await GoogleSignIn().signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuth =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuth.accessToken,
          idToken: googleSignInAuth.idToken,
        );
        final UserCredential authResult =
            await FirebaseAuth.instance.signInWithCredential(credential);

        //* Check if the user already exists in the Firestore collection
        final userRef = FirebaseFirestore.instance.collection('users');
        final userDoc = await userRef.doc(authResult.user!.uid).get();

        //* Get current timestamp
        final now = DateTime.now();

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

        if (!userDoc.exists) {
          //* Add the user to the collection with UID as the document ID
          await userRef.doc(authResult.user!.uid).set({
            'created_at': now,
            'email': authResult.user!.email,
            'full_name': authResult.user!.displayName,
            'last_login': now,
            'nickname': authResult.additionalUserInfo!.profile!['given_name'],
            'photo_url': authResult.user!.photoURL,
            'device_info_json': deviceInfoJson,
          });
        } else {
          //* User already exists, update last_login and device_info_json

          await userRef.doc(authResult.user!.uid).update({
            'last_login': now,
            'device_info_json': jsonEncode(deviceInfoMap),
          });
        }

        print('Google Sign-In Successful');

        //* Navigate to the DashboardPage after sign-in
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        print('Google Sign-In Cancelled');
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
    }
  }

  Future<void> _signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      print('Sign Out Successful');
    } catch (error) {
      print('Sign Out Error: $error');
    }
  }
}
