import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'providers/accounts_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/cycle_provider.dart';
import 'providers/cycles_provider.dart';
import 'providers/transactions_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/ad_mob_service.dart';
import 'providers/person_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  final savedThemeColor = prefs.getInt('theme_color');
  final themeColor =
      savedThemeColor != null ? Color(savedThemeColor) : Colors.teal;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final initAdFuture = MobileAds.instance.initialize();
  final adMobService = AdMobService(initAdFuture);

  runApp(MultiProvider(
    providers: [
      Provider.value(value: adMobService),
      ChangeNotifierProvider(
        create: (context) => PersonProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => CycleProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => CyclesProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => TransactionsProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => AccountsProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => CategoriesProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => WishlistProvider(),
      ),
    ],
    child: MyApp(savedThemeMode: savedThemeMode, themeColor: themeColor),
  ));
}

class MyApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final Color? themeColor;

  const MyApp(
      {super.key, required this.savedThemeMode, required this.themeColor});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: widget.themeColor,
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: widget.themeColor,
      ),
      initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Finance Mate',
        theme: theme,
        darkTheme: darkTheme,
        home: const LoginPage(),
        builder: EasyLoading.init(),
      ),
    );
  }
}
