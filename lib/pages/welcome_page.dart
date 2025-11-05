// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/person_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _onIntroEnd(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);

    EasyLoading.show(status: 'Starting up...');

    // Once intro seen, re-run fetchData
    await context.read<PersonProvider>().fetchData(context);

    EasyLoading.showSuccess('Welcome aboard!');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<PersonProvider>().user!;
    final theme = Theme.of(context);

    const bodyStyle = TextStyle(fontSize: 18.0);
    final pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      bodyTextStyle: bodyStyle,
      imagePadding: const EdgeInsets.only(top: 24.0),
      pageMargin: const EdgeInsets.only(top: 60.0),
      bodyAlignment: Alignment.center,
      imageAlignment: Alignment.center,
      pageColor: theme.colorScheme.surface,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: theme.colorScheme.surface,
      pages: [
        // 🟢 PAGE 1 - Personalized Greeting
        PageViewModel(
          title: "Welcome, ${user.displayName}!",
          body:
              "We're glad to have you here. Let's take a quick tour to help you make the most of My Finance Mate.",
          image: Lottie.asset(
            'assets/lottie/welcome.json',
            width: 300,
          ),
          decoration: pageDecoration,
        ),

        // 💰 PAGE 2
        PageViewModel(
          title: "Track Your Finances Easily",
          body:
              "Monitor your expenses, income, and budgets all in one place. Stay organized effortlessly.",
          image: Lottie.asset(
            'assets/lottie/money-tracking.json',
            width: 300,
          ),
          decoration: pageDecoration,
        ),

        // 🎯 PAGE 3
        PageViewModel(
          title: "Plan Your Goals",
          body:
              "Set financial targets and visualize your progress with insightful analytics and reports.",
          image: Lottie.asset(
            'assets/lottie/financial-goals.json',
            width: 300,
          ),
          decoration: pageDecoration,
        ),

        // 🔒 PAGE 4
        PageViewModel(
          title: "Secure & Private",
          body:
              "Your data stays yours — encrypted, local-first, and never shared without permission.",
          image: Lottie.asset(
            'assets/lottie/security.json',
            width: 300,
          ),
          decoration: pageDecoration,
        ),

        // 🌟 PAGE 5 - Closing & Start
        PageViewModel(
          title: "You're All Set, ${user.displayName}!",
          body:
              "Start managing your finances smarter today. Tap below to explore your personalized dashboard.",
          image: Lottie.asset(
            'assets/lottie/success-celebration.json',
            width: 300,
          ),
          decoration: pageDecoration,
          footer: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _onIntroEnd(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: Text('Skip', style: TextStyle(color: theme.colorScheme.primary)),
      next: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
      done: Text(
        'Done',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: theme.colorScheme.primary.withAlpha(77),
        activeSize: const Size(22.0, 10.0),
        activeColor: theme.colorScheme.primary,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsFlex: 2,
      nextFlex: 1,
    );
  }
}
