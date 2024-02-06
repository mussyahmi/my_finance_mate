// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_mob_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  AdaptiveThemeMode? savedThemeMode;
  Color themeColor = Colors.deepPurple;

  //* Ad related
  late AdMobService _adMobService;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();

    if (_adMobService.status) {
      _adMobService.initialization.then((value) {
        setState(() {
          _bannerAd = BannerAd(
            size: AdSize.largeBanner,
            adUnitId: _adMobService.bannerSettingAdUnitId!,
            listener: _adMobService.bannerAdListener,
            request: const AdRequest(),
          )..load();
        });
      });
    }
  }

  Future<void> initAsync() async {
    SharedPreferences? sharedPreferences =
        await SharedPreferences.getInstance();
    AdaptiveThemeMode? adaptiveThemeMode = await AdaptiveTheme.getThemeMode();
    final savedThemeColor = sharedPreferences.getInt('theme_color');

    setState(() {
      prefs = sharedPreferences;
      savedThemeMode = adaptiveThemeMode;
      themeColor =
          savedThemeColor != null ? Color(savedThemeColor) : Colors.deepPurple;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Toggle Theme Mode'),
                    trailing: Icon(savedThemeMode == AdaptiveThemeMode.light
                        ? Icons.light_mode
                        : Icons.dark_mode),
                    onTap: () async {
                      print('savedThemeMode $savedThemeMode');
                      if (savedThemeMode == AdaptiveThemeMode.light) {
                        //* sets theme mode to dark
                        AdaptiveTheme.of(context).setDark();
                      } else {
                        //* sets theme mode to dark
                        AdaptiveTheme.of(context).setLight();
                      }

                      AdaptiveThemeMode? result =
                          await AdaptiveTheme.getThemeMode();

                      setState(() {
                        savedThemeMode = result;
                      });
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Theme Colors'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '(Slide left for more options)',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                themeColorSelector(
                                    context: context, color: Colors.amber),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.blue),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.blueGrey),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.brown),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.cyan),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.deepOrange),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.green),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.indigo),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.lightBlue),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.lightGreen),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.lime),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.orange),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.pink),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.purple),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.red),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.teal),
                                const SizedBox(width: 8),
                                themeColorSelector(
                                    context: context, color: Colors.yellow),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (route) =>
                            false, //* This line removes all previous routes from the stack
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
          if (_bannerAd != null)
            Column(
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 100.0,
                  child: AdWidget(ad: _bannerAd!),
                ),
              ],
            ),
        ],
      ),
    );
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

  Widget themeColorSelector({
    required BuildContext context,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: () async {
        AdaptiveTheme.of(context).setTheme(
          light: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: color,
          ),
          dark: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: color,
          ),
        );

        await prefs.setInt('theme_color', color.value);

        setState(() {
          themeColor = color;
        });
      },
      child: Container(
        width: themeColor.value == color.value ? 26 : 20,
        height: themeColor.value == color.value ? 26 : 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: themeColor.value == color.value
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: themeColor.value == color.value ? 5.0 : 2.0,
          ),
        ),
      ),
    );
  }
}
