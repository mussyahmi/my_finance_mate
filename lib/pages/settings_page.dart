// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import 'login_page.dart';
import 'type_page.dart';
import 'wishlist_page.dart';
import 'summary_page.dart';

class SettingsPage extends StatefulWidget {
  final String cycleId;

  const SettingsPage({Key? key, required this.cycleId}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  AdaptiveThemeMode? savedThemeMode;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    AdaptiveThemeMode? result = await AdaptiveTheme.getThemeMode();

    setState(() {
      savedThemeMode = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Category List'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              TypePage(cycleId: widget.cycleId)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Category Summary'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SummaryPage(
                                cycleId: widget.cycleId,
                              )),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: const Text('Wishlist'),
                  leading: const Icon(Icons.favorite),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WishlistPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: const Text('Toggle Theme Mode'),
                  leading: Icon(savedThemeMode == AdaptiveThemeMode.light
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
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const ListTile(
                  title: Row(
                    children: [
                      Text('Theme Colors'),
                      SizedBox(width: 8),
                      Text(
                        '(Slide left for more option)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ],
                  ),
                  leading: Icon(Icons.palette),
                  subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          ThemeColorSelector(color: Colors.amber),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.blue),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.blueGrey),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.brown),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.cyan),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.deepOrange),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.deepPurple),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.green),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.indigo),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.lightBlue),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.lightGreen),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.lime),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.orange),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.pink),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.purple),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.red),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.teal),
                          SizedBox(width: 8),
                          ThemeColorSelector(color: Colors.yellow),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  _signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
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
            ],
          ),
        ),
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
}

class ThemeColorSelector extends StatelessWidget {
  final MaterialColor color;

  const ThemeColorSelector({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
