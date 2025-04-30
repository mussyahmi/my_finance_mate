import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/maintenance_page.dart';
import 'providers/accounts_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/cycle_provider.dart';
import 'providers/cycles_provider.dart';
import 'providers/transactions_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/ad_cache_service.dart';
import 'services/ad_mob_service.dart';
import 'providers/person_provider.dart';
import 'services/app_settings_service.dart';

void main() async {
  final List<Color> themeColors = [
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

  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  final savedThemeColorIndex = prefs.getInt('theme_color_index');
  final themeColor = savedThemeColorIndex != null
      ? themeColors[savedThemeColorIndex]
      : Colors.teal;

  final savedSystemUiMode = prefs.getString('system_ui_mode');
  SystemUiMode systemUiMode = savedSystemUiMode != null
      ? SystemUiMode.values
          .firstWhere((mode) => mode.toString() == savedSystemUiMode)
      : SystemUiMode.edgeToEdge;
  await SystemChrome.setEnabledSystemUIMode(systemUiMode);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final initAdFuture = MobileAds.instance.initialize();
  final adMobService = AdMobService(initAdFuture);
  final adCacheService = AdCacheService();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: adMobService),
      Provider.value(value: adCacheService),
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
  bool _isUnderMaintenance = false;
  String _maintenanceTitle = "Maintenance Mode";
  String _maintenanceSubtitle = "We'll be back soon!";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMaintenanceStatus();
  }

  Future<void> _checkMaintenanceStatus() async {
    final appSettings = await AppSettingsService().fetchAppSettings();
    setState(() {
      _isUnderMaintenance = appSettings['status'];
      _maintenanceTitle = appSettings['status'] ? appSettings['title'] : '';
      _maintenanceSubtitle =
          appSettings['status'] ? appSettings['subtitle'] : '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AdaptiveTheme(
        light: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          colorSchemeSeed: widget.themeColor,
          listTileTheme: ListTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        dark: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: widget.themeColor,
          listTileTheme: ListTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'My Finance Mate',
          theme: theme,
          darkTheme: darkTheme,
          home: const Center(child: CircularProgressIndicator()),
          builder: EasyLoading.init(),
        ),
      );
    }

    if (_isUnderMaintenance) {
      return AdaptiveTheme(
        light: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          colorSchemeSeed: widget.themeColor,
          listTileTheme: ListTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        dark: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: widget.themeColor,
          listTileTheme: ListTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'My Finance Mate',
          theme: theme,
          darkTheme: darkTheme,
          home: MaintenancePage(
            title: _maintenanceTitle,
            subtitle: _maintenanceSubtitle,
          ),
          builder: EasyLoading.init(),
        ),
      );
    }

    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: widget.themeColor,
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: widget.themeColor,
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
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
