// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../services/ad_mob_service.dart';
import '../services/message_services.dart';
import '../widgets/ad_container.dart';
import '../widgets/package_info_summary.dart';
import '../widgets/profile_image.dart';
import 'chart_page.dart';
import 'login_page.dart';
import 'category_summary_page.dart';
import 'wishlist_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late SharedPreferences prefs;
  AdaptiveThemeMode? savedThemeMode;
  Color themeColor = Colors.teal;
  late AdMobService _adMobService;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
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
          savedThemeColor != null ? Color(savedThemeColor) : Colors.teal;
    });
  }

  Card card(Person user, String title) {
    var data = '';

    if (title == 'Display Name') {
      data = user.displayName;
    } else if (title == 'Email') {
      data = user.email;
    }

    return Card(
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          data,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: title == 'Display Name'
            ? IconButton.filledTonal(
                onPressed: () async {
                  await user.showEditDisplayNameDialog(context);
                },
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<PersonProvider>().user!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text('Profile'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    ProfileImage(),
                    const SizedBox(height: 20),
                    card(user, 'Display Name'),
                    card(user, 'Email'),
                    const SizedBox(height: 30),
                    if (!user.isPremium)
                      Column(
                        children: [
                          AdContainer(
                            adMobService: _adMobService,
                            adSize: AdSize.largeBanner,
                            adUnitId: _adMobService.bannerProfileAdUnitId!,
                            height: 100.0,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'Analysis & Insights',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Chart'),
                        trailing: const Icon(Icons.pie_chart),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChartPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Category Summary'),
                        trailing: const Icon(Icons.analytics),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategorySummaryPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'Wishlist',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Wishlist'),
                        trailing: const Icon(Icons.favorite),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WishlistPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'User Customization',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    themeColorSelector(
                                        context: context, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context,
                                        color: Colors.blueGrey),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context, color: Colors.brown),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context, color: Colors.cyan),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context,
                                        color: Colors.deepOrange),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context,
                                        color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context, color: Colors.green),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context, color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context,
                                        color: Colors.lightBlue),
                                    const SizedBox(width: 8),
                                    themeColorSelector(
                                        context: context,
                                        color: Colors.lightGreen),
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
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'Account Management',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    if (FirebaseAuth
                            .instance.currentUser!.providerData[0].providerId ==
                        'password')
                      Card(
                        child: ListTile(
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.lock_reset),
                          onTap: () => user.showChangePasswordDialog(context),
                        ),
                      ),
                    Card(
                      surfaceTintColor: Colors.red,
                      child: ListTile(
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.delete_forever,
                          color: Colors.redAccent,
                        ),
                        onTap: () async {
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                  'Are you sure you want to delete your account? This action is permanent.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'Delete',
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            try {
                              final MessageService messageService =
                                  MessageService();

                              EasyLoading.show(
                                  status:
                                      messageService.getRandomDeleteMessage());

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({'deleted_at': DateTime.now()});

                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('last_login_with');

                              await FirebaseAuth.instance.currentUser?.delete();

                              EasyLoading.showSuccess(
                                  'Account deleted successfully');

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()),
                                (route) =>
                                    false, //* This line removes all previous routes from the stack
                              );
                            } catch (e) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({'deleted_at': null});

                              EasyLoading.showError(
                                  'Failed to delete account. Error: $e');
                            }
                          }
                        },
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ),
                    PackageInfoSummary(
                      canPress: user.uid == 'nysYsoZpMQXujJmIJRjbkhHo6ft2',
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_login_with');

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
        if (!context.read<PersonProvider>().user!.isPremium) {
          return EasyLoading.showInfo(
              'Upgrade to Premium to customize your theme color.');
        }

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
