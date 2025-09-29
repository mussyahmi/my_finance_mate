// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../extensions/firestore_extensions.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
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
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill,
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
            const SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    //* Toggle the password visibility when the button is pressed
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
                    _displayNameController.text.trim(),
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                    _confirmPasswordController.text.trim(),
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
        'serialNumber': deviceInfo.serialNumber,
        'isLowRamDevice': deviceInfo.isLowRamDevice,
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

  Future<void> _register(
    String displayName,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      //* Validate the form data
      final message = _validate(displayName, email, password, confirmPassword);

      if (message.isNotEmpty) {
        EasyLoading.showInfo(message);
        return;
      }

      final UserCredential authResult =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_login_with');

        //* Get current timestamp
        final now = DateTime.now();

        //* Get device information
        final deviceInfoJson = await _getDeviceInfoJson();

        //* Add the user to the collection with UID as the document ID
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .set({
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'email': authResult.user!.email,
          'display_name': displayName,
          'last_login': now,
          'image_url': authResult.user!.photoURL,
          'device_info_json': deviceInfoJson,
          'password': password,
          'daily_transactions_made': 0,
          'force_refresh': true,
          'is_premium': false,
          'premium_start_date': null,
          'premium_end_date': null,
        });

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .getSavy(refresh: true);
        print('register - userDoc: 1');

        Person person = Person(
          uid: userDoc.id,
          displayName: userDoc['display_name'] ?? '',
          email: userDoc['email'],
          imageUrl: userDoc['image_url'] ?? '',
          lastLogin: (userDoc['last_login'] as Timestamp).toDate(),
          dailyTransactionsMade: userDoc['daily_transactions_made'],
          forceRefresh: userDoc['force_refresh'],
          isPremium: userDoc['is_premium'],
          premiumStartDate: userDoc['premium_start_date'] != null
              ? (userDoc['premium_start_date'] as Timestamp).toDate()
              : null,
          premiumEndDate: userDoc['premium_end_date'] != null
              ? (userDoc['premium_end_date'] as Timestamp).toDate()
              : null,
          deviceInfoJson: deviceInfoJson,
        );

        context.read<PersonProvider>().setUser(newUser: person);

        if (!authResult.user!.emailVerified) {
          await authResult.user!.sendEmailVerification();

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmailVerificationPage(user: authResult.user!),
            ),
          );
        }

        await context.read<PersonProvider>().fetchData(context);
      }
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Registration Failed!'),
            content: Text(e.message ?? 'An unknown error occurred.'),
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

  String _validate(
    String displayName,
    String email,
    String password,
    String confirmPassword,
  ) {
    //* Check if displayName is empty
    if (displayName.isEmpty) {
      return 'Display name cannot be empty.';
    }

    //* Check if email is empty
    if (email.isEmpty) {
      return 'Email cannot be empty.';
    }

    //* Validate email format
    if (!EmailValidator.validate(email)) {
      return 'Please enter a valid email address.';
    }

    //* Check if password is empty
    if (password.isEmpty) {
      return 'Password cannot be empty.';
    }

    //* Validate password length and content
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one digit.';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) {
      return 'Password must contain at least one special character.';
    }

    //* Check if confirmPassword is empty
    if (confirmPassword.isEmpty) {
      return 'Confirm password cannot be empty.';
    }

    //* Check if password and confirmPassword match
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    //* If all validations pass, return an empty string (indicating no errors)
    return '';
  }
}
