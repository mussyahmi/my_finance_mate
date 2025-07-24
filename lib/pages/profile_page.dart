// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../services/message_services.dart';
import '../widgets/ad_container.dart';
import '../widgets/package_info_summary.dart';
import '../widgets/profile_image.dart';
import 'attachment_list_page.dart';
import 'cumulative_trends_page.dart';
import 'purchase_history_page.dart';
import 'transaction_summary_page.dart';
import 'login_page.dart';
import 'premium_access_page.dart';
import 'wishlist_page.dart';

class ProfilePage extends StatefulWidget {
  final Function askToStartTutorial;

  const ProfilePage({
    super.key,
    required this.askToStartTutorial,
  });

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final List<Color> _themeColors = [
    Colors.amber,
    Colors.blue,
    Colors.blueGrey,
    Colors.brown,
    Colors.cyan,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.green,
    Colors.indigo,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.lime,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.yellow,
  ];
  final MessageService messageService = MessageService();
  late SharedPreferences prefs;
  AdaptiveThemeMode? savedThemeMode;
  Color themeColor = Colors.teal;
  bool showNetBalance = false;
  bool showPinnedWishlist = false;
  late AdMobService _adMobService;
  late AdCacheService _adCacheService;
  RewardedAd? _rewardedAd;
  int customizeThemeColor = 0;
  SystemUiMode systemUiMode = SystemUiMode.edgeToEdge;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _adCacheService = context.read<AdCacheService>();

    final Person user = context.read<PersonProvider>().user!;

    if (!user.isPremium) {
      _createRewardedAd();
    }
  }

  Future<void> initAsync() async {
    SharedPreferences? sharedPreferences =
        await SharedPreferences.getInstance();
    AdaptiveThemeMode? adaptiveThemeMode = await AdaptiveTheme.getThemeMode();
    final savedThemeColorIndex = sharedPreferences.getInt('theme_color_index');
    final savedShowNetBalance = sharedPreferences.getBool('show_net_balance');
    final savedShowPinnedWishlist =
        sharedPreferences.getBool('show_pinned_wishlist');
    final savedCustomizeThemeColor =
        sharedPreferences.getInt('customize_theme_color');
    final savedSystemUiMode = sharedPreferences.getString('system_ui_mode');

    setState(() {
      prefs = sharedPreferences;
      savedThemeMode = adaptiveThemeMode;
      themeColor = savedThemeColorIndex != null
          ? _themeColors[savedThemeColorIndex]
          : Colors.teal;
      showNetBalance = savedShowNetBalance ?? false;
      showPinnedWishlist = savedShowPinnedWishlist ?? false;
      customizeThemeColor = savedCustomizeThemeColor ?? 0;
      systemUiMode = savedSystemUiMode != null
          ? SystemUiMode.values
              .firstWhere((mode) => mode.toString() == savedSystemUiMode)
          : SystemUiMode.edgeToEdge;
    });
  }

  Card card(Person user, String title) {
    var data = '';

    if (title == 'User ID') {
      data = user.uid;
    } else if (title == 'Display Name') {
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
        trailing: title == 'User ID'
            ? IconButton.filledTonal(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: data));

                  EasyLoading.showSuccess('Copied to clipboard');
                },
                icon: Icon(
                  Icons.copy,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : title == 'Display Name'
                ? IconButton.filledTonal(
                    onPressed: () async {
                      await user.showEditDisplayNameDialog(context);
                    },
                    icon: Icon(
                      CupertinoIcons.pencil,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
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
                    card(user, 'User ID'),
                    card(user, 'Display Name'),
                    card(user, 'Email'),
                    const SizedBox(height: 30),
                    if (!user.isPremium)
                      Column(
                        children: [
                          AdContainer(
                            adCacheService: _adCacheService,
                            number: 1,
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
                        'Premium Access',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Card(
                      surfaceTintColor: Colors.orange,
                      child: ListTile(
                        title: const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          CupertinoIcons.star_circle_fill,
                          color: Colors.orangeAccent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PremiumSubscriptionPage()),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('My Purchases'),
                        trailing: const Icon(Icons.receipt_long),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PurchaseHistoryPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Order History'),
                        trailing: const Icon(Icons.history),
                        onTap: () {
                          if (Platform.isAndroid) {
                            launchUrl(Uri.parse(
                                'https://play.google.com/store/account/orderhistory'));
                          } else {
                            // TODO: Implement iOS order history
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Manage Subscriptions'),
                        trailing: const Icon(CupertinoIcons.creditcard),
                        onTap: () {
                          if (Platform.isAndroid) {
                            launchUrl(Uri.parse(
                                'https://play.google.com/store/account/subscriptions'));
                          } else {
                            // TODO: Implement iOS subscriptions
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
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
                        title: const Text('Cumulative Trends'),
                        trailing: const Icon(Icons.area_chart),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CumulativeTrendsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Transaction Summary'),
                        trailing: const Icon(CupertinoIcons.chart_pie_fill),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionSummaryPage(),
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
                        trailing: const Icon(CupertinoIcons.heart_fill),
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
                        'Tools',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('KWSP Growth Calculator'),
                        trailing: const Icon(CupertinoIcons.right_chevron),
                        onTap: () async {
                          await launchUrl(Uri.parse(
                              'https://my-finance-mate.com/kwsp-growth-calculator'));
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('KWSP Withdrawal Planner'),
                        trailing: const Icon(CupertinoIcons.right_chevron),
                        onTap: () async {
                          await launchUrl(Uri.parse(
                              'https://my-finance-mate.com/kwsp-withdrawal-planner'));
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
                        title: const Text('Show Net Balance'),
                        subtitle: const Text(
                          'On Monthly Expenses',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        trailing: Switch(
                          value: showNetBalance,
                          onChanged: (bool value) async {
                            await prefs.setBool(
                                'show_net_balance', !showNetBalance);

                            setState(() {
                              showNetBalance = !showNetBalance;
                            });
                          },
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Show Pinned Wishlist'),
                        subtitle: const Text(
                          'On Dashboard',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        trailing: Switch(
                          value: showPinnedWishlist,
                          onChanged: (bool value) async {
                            await prefs.setBool(
                                'show_pinned_wishlist', !showPinnedWishlist);

                            setState(() {
                              showPinnedWishlist = !showPinnedWishlist;
                            });
                          },
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Toggle Theme Mode'),
                        trailing: Switch(
                          value: savedThemeMode == AdaptiveThemeMode.dark,
                          onChanged: (bool value) async {
                            if (value) {
                              //* sets theme mode to dark
                              AdaptiveTheme.of(context).setDark();
                            } else {
                              //* sets theme mode to light
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
                    ),
                    Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Theme Colors'),
                            if (!user.isPremium && customizeThemeColor > 0)
                              Text(
                                '$customizeThemeColor customization${customizeThemeColor > 1 ? 's' : ''} remaining',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Slide left for more options',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children:
                                      _themeColors.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    Color color = entry.value;

                                    return Row(
                                      children: [
                                        themeColorSelector(
                                          user: user,
                                          context: context,
                                          color: color,
                                          index: index,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: Text('System UI Mode'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Control status bar & navigation visibility',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    ...{
                                      SystemUiMode.edgeToEdge:
                                          'Default (Visible)',
                                      SystemUiMode.immersiveSticky:
                                          'Fullscreen (Sticky)',
                                    }.entries.map((entry) {
                                      final mode = entry.key;
                                      final label = entry.value;

                                      return Row(
                                        children: [
                                          ChoiceChip(
                                            label: Text(label),
                                            selected: systemUiMode == mode,
                                            onSelected: (bool selected) async {
                                              if (selected) {
                                                setState(() {
                                                  systemUiMode = mode;
                                                });
                                                await SystemChrome
                                                    .setEnabledSystemUIMode(
                                                        mode);
                                                await prefs.setString(
                                                    'system_ui_mode',
                                                    mode.toString());
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      );
                                    }),
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
                    Card(
                      child: ListTile(
                        title: const Text('Take a Tour'),
                        trailing: const Icon(Icons.tour),
                        onTap: () {
                          widget.askToStartTutorial();
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Attachment List'),
                        trailing: const Icon(Icons.attach_file),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AttachmentListPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    if (FirebaseAuth
                            .instance.currentUser!.providerData[0].providerId ==
                        'password')
                      Card(
                        child: ListTile(
                          title: const Text('Change Password'),
                          trailing: const Icon(CupertinoIcons.lock_rotation),
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
                                    surfaceTintColor: Colors.red,
                                    foregroundColor: Colors.redAccent,
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
                              EasyLoading.show(
                                  status:
                                      messageService.getRandomDeleteMessage());

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({'deleted_at': DateTime.now()});

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
      await prefs.remove('last_login_with');

      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      print('Sign Out Successful');
    } catch (error) {
      print('Sign Out Error: $error');
    }
  }

  Widget themeColorSelector({
    required Person user,
    required BuildContext context,
    required Color color,
    required int index,
  }) {
    return GestureDetector(
      onTap: () async {
        if (!user.isPremium && customizeThemeColor == 0) {
          return showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: const Text('Change Your Look!'),
                content: const Text(
                    'Want to customize your theme color? You can try it up to 3 times by watching a quick ad, or unlock unlimited access by upgrading to Premium!'),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      if (!user.isPremium) _showRewardedAd();

                      Navigator.of(context).pop();
                    },
                    child: const Text('Watch Ad'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      surfaceTintColor: Colors.orange,
                      foregroundColor: Colors.orangeAccent,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PremiumSubscriptionPage(),
                        ),
                      );
                    },
                    child: const Text('Upgrade to Premium'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Later'),
                  ),
                ],
              );
            },
          );
        }

        EasyLoading.show(status: messageService.getRandomUpdateMessage());

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

        await Future.delayed(const Duration(milliseconds: 250));

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

        await prefs.setInt('theme_color_index', index);

        if (!user.isPremium && customizeThemeColor != 0) {
          await prefs.setInt('customize_theme_color', customizeThemeColor - 1);
          customizeThemeColor =
              customizeThemeColor != 0 ? customizeThemeColor - 1 : 0;
        }

        setState(() {
          themeColor = color;
          customizeThemeColor = customizeThemeColor;
        });

        EasyLoading.showInfo('Your theme color have been changed.');
      },
      child: Container(
        width: themeColor.withValues() == color.withValues() ? 26 : 20,
        height: themeColor.withValues() == color.withValues() ? 26 : 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: themeColor.withValues() == color.withValues()
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: themeColor.withValues() == color.withValues() ? 5.0 : 2.0,
          ),
        ),
      ),
    );
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: _adMobService.rewardedCustomizeThemeColorAdUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (error) {
          setState(() {
            _rewardedAd = null;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          EasyLoading.showInfo('Failed to show ad. Please try again later.');
          ad.dispose();
          _createRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) async {
          await prefs.setInt('customize_theme_color', 3);

          setState(() {
            customizeThemeColor = 3;
          });

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Reward Granted!'),
                content: const Text(
                    'You\'re good to go! Choose any color you like and give your look a fresh update! 🚀'),
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
        },
      );
    }
  }
}
