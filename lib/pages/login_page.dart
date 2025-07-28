// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../services/ad_mob_service.dart';
import '../widgets/package_info_summary.dart';
import 'dashboard_page.dart';
import 'email_verification_page.dart';
import 'register_page.dart';
import '../size_config.dart';
import '../extensions/firestore_extensions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotPasswordEmailController =
      TextEditingController();
  bool _isLoading = false;
  bool _isLoading2 = false;
  bool _isPasswordVisible = false;
  bool _isRememberMeChecked = false;
  late AdMobService _adMobService;
  bool _adMobServiceInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //* Initialize AdMobService only once
    if (!_adMobServiceInit) {
      _adMobService = context.read<AdMobService>();

      _adMobService.initialization.then((value) {
        setState(() {
          _adMobServiceInit = true;
        });

        //* Load saved credentials after AdMobService initialization
        if (_adMobServiceInit) {
          _loadSavedCredentials();
        }
      }).catchError((e) {
        EasyLoading.showError('Failed to initialize AdMob. Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = Theme.of(context).colorScheme.secondary
      ..indicatorType = EasyLoadingIndicatorType.ripple
      ..indicatorColor = Theme.of(context).colorScheme.onSecondary
      ..textColor = Theme.of(context).colorScheme.onSecondary
      ..progressColor = Colors.blue
      ..maskColor = Colors.green.withAlpha(128)
      ..userInteractions = false
      ..dismissOnTap = false;

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
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            image: DecorationImage(
                              image: AssetImage('assets/icon/icon.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Welcome to My Finance Mate!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                              const Text('Remember me'),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey,
                              height: 36,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Or login with'),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey,
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: _isLoading2
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Google'),
                      ),
                    ],
                  ),
                ),
                PackageInfoSummary(canPress: false),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
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
                ),
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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authResult.user!.uid)
          .getSavy(refresh: true);
      print('_signInWithEmailAndPassword - userDoc: 1');

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

        await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .update({
          'updated_at': now,
          'last_login': now,
          'device_info_json': deviceInfoJson,
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_login_with', 'email');

        Person person = Person(
          uid: userDoc.id,
          displayName: userDoc['display_name'] ?? '',
          email: userDoc['email'],
          imageUrl: userDoc['image_url'] ?? '',
          lastLogin: (userDoc['last_login'] as Timestamp).toDate(),
          dailyTransactionsMade: userDoc['daily_transactions_made'],
          forceRefresh: userDoc['force_refresh'] ||
              prefs.getString('last_login_with') == null ||
              userDoc['device_info_json'] != deviceInfoJson,
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

        print('Email/Password Sign-In Successful');

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

        //* Navigate to the DashboardPage after sign-in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ShowCaseWidget(
              builder: (context) => const DashboardPage(),
              globalFloatingActionWidget: (showcaseContext) =>
                  FloatingActionWidget(
                right: 16,
                top: 16,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: ShowCaseWidget.of(showcaseContext).dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    child: const Text(
                      'Skip Tour',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again later.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Text('Failed to login. Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .getSavy(refresh: true);
        print('_signInWithGoogle - userDoc: 1');

        //* Get current timestamp
        final now = DateTime.now();

        //* Get device information
        final deviceInfoJson = await _getDeviceInfoJson();
        bool isDiffDevice = false;

        if (!userDoc.exists) {
          //* Add the user to the collection with UID as the document ID
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authResult.user!.uid)
              .set({
            'created_at': now,
            'updated_at': now,
            'deleted_at': null,
            'email': authResult.user!.email,
            'display_name': authResult.user!.displayName,
            'last_login': now,
            'image_url': authResult.user!.photoURL,
            'device_info_json': deviceInfoJson,
            'daily_transactions_made': 0,
            'force_refresh': true,
            'is_premium': false,
            'premium_start_date': null,
            'premium_end_date': null,
          });
        } else {
          final String prevDeviceInfoJson = userDoc['device_info_json'];

          //* User already exists, update last_login and device_info_json
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authResult.user!.uid)
              .update({
            'updated_at': now,
            'last_login': now,
            'device_info_json': deviceInfoJson,
          });

          isDiffDevice = prevDeviceInfoJson != deviceInfoJson;
        }

        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .getSavy(refresh: true);
        print('_signInWithGoogle - userDoc: 1');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_login_with', 'google');

        Person person = Person(
          uid: userDoc.id,
          displayName: userDoc['display_name'] ?? '',
          email: userDoc['email'],
          imageUrl: userDoc['image_url'] ?? '',
          lastLogin: (userDoc['last_login'] as Timestamp).toDate(),
          dailyTransactionsMade: userDoc['daily_transactions_made'],
          forceRefresh: userDoc['force_refresh'] ||
              prefs.getString('last_login_with') == null ||
              isDiffDevice,
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

        print('Google Sign-In Successful');

        await context.read<PersonProvider>().fetchData(context);

        //* Navigate to the DashboardPage after sign-in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ShowCaseWidget(
              builder: (context) => const DashboardPage(),
              globalFloatingActionWidget: (showcaseContext) =>
                  FloatingActionWidget(
                right: 16,
                top: 16,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: ShowCaseWidget.of(showcaseContext).dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    child: const Text(
                      'Skip Tour',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        print('Google Sign-In Cancelled');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Text('Failed to login. Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _isRememberMeChecked = true; //* Update the checkbox state
      });
    }

    await _checkCurrentVersion();

    _autoLogin();
  }

  int _getExtendedVersionNumber(String version) {
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 100000 + versionCells[1] * 1000 + versionCells[2];
  }

  Future<void> _checkCurrentVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;

    final DocumentSnapshot versionsDoc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('versions')
        .get();

    if (versionsDoc.exists) {
      final String latestVersion = versionsDoc['latest'];
      final String minimumVersion = versionsDoc['minimum'];

      if (currentVersion != latestVersion) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Update Available'),
              content: const Text(
                  'A new version is available. Please update the app.'),
              actions: [
                if (_getExtendedVersionNumber(currentVersion) >=
                    _getExtendedVersionNumber(minimumVersion))
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Later'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    if (Platform.isAndroid) {
                      launchUrl(Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.mustafasyahmi.myfinancemate'));
                    } else {
                      // TODO: Add iOS App Store link
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update Now'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _autoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastLoginWith = prefs.getString('last_login_with');

    if (lastLoginWith == 'email' &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (lastLoginWith == 'google') {
      setState(() {
        _isLoading2 = true; //* Set loading state to true
      });

      try {
        //* Use the context from the Builder widget
        await _signInWithGoogle(context);
      } finally {
        setState(() {
          _isLoading2 = false; //* Set loading state to false
        });
      }
    }
  }

  //* Function to show the forgot password dialog
  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: _forgotPasswordEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () async {
                String email = _forgotPasswordEmailController.text.trim();

                //* Check if email is empty
                if (email.isEmpty) {
                  return EasyLoading.showInfo('Email cannot be empty.');
                }

                //* Validate email format
                if (!EmailValidator.validate(email)) {
                  return EasyLoading.showInfo(
                      'Please enter a valid email address.');
                }

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  EasyLoading.showSuccess('Password reset email sent!');
                  Navigator.of(context).pop();
                } catch (e) {
                  EasyLoading.showError('Failed to send email. Error: $e');
                }
              },
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }
}
