// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_page.dart';
import 'register_page.dart';
import '../size_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoading2 = false;
  bool _isPasswordVisible = false;
  bool _isRememberMeChecked = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  Widget build(BuildContext context) {
    //* Initialize SizeConfig
    SizeConfig().init(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: SizeConfig.screenHeight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Welcome to My Finance Mate!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColor,
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
                      Row(
                        children: [
                          Checkbox(
                            value: _isRememberMeChecked,
                            onChanged: (value) {
                              setState(() {
                                _isRememberMeChecked = value!;
                              });
                            },
                          ),
                          const Text('Remember Me'),
                        ],
                      ),

                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (_isLoading || _isLoading2) return;

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await _signInWithEmailAndPassword(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.black,
                              height: 36,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Or login with'),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.black,
                              height: 36,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      //* Show a circular progress indicator while loading
                      ElevatedButton(
                        onPressed: () async {
                          if (_isLoading || _isLoading2) return;

                          setState(() {
                            _isLoading2 = true; //* Set loading state to true
                          });

                          try {
                            //* Use the context from the Builder widget
                            await _signInWithGoogle(context);
                          } finally {
                            setState(() {
                              _isLoading2 =
                                  false; //* Set loading state to false
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading2
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Google'),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Dont\'t have an account?'),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text('Register'))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithEmailAndPassword(
      String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return;
    }

    try {
      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userRef = FirebaseFirestore.instance.collection('users');
      final userDoc = await userRef.doc(authResult.user!.uid).get();

      if (userDoc.exists) {
        if (_isRememberMeChecked) {
          _saveLoginCredentials(email, password);
        } else {
          _clearSavedCredentials();
        }

        //* Get device information
        final deviceInfoJson = await _getDeviceInfoJson();

        //* User already exists, you can choose to update any information if needed
        final now = DateTime.now();

        await userRef.doc(authResult.user!.uid).update({
          'updated_at': now,
          'last_login': now,
          'device_info_json': deviceInfoJson,
        });

        //* Navigate to the DashboardPage after sign-in
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } catch (error) {
      print('Email/Password Sign-In Error: $error');
      //todo: Handle sign-in errors as needed, such as displaying an error message
    }
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
        final deviceInfoJson = await _getDeviceInfoJson();

        if (!userDoc.exists) {
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
          });
        } else {
          //* User already exists, update last_login and device_info_json

          await userRef.doc(authResult.user!.uid).update({
            'updated_at': now,
            'last_login': now,
            'device_info_json': deviceInfoJson,
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

  void _saveLoginCredentials(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  void _clearSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        _isRememberMeChecked = true; //* Update the checkbox state
      });
    }
  }
}
