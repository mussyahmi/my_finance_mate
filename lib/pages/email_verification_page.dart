// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'dashboard_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final User user;

  const EmailVerificationPage({super.key, required this.user});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Text(
              'Verify Email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 30),
            Text(
              'We\'ve sent you a mail to',
              style: TextStyle(fontSize: 16),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(
                      text: widget.user.email,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  TextSpan(text: '. Please'),
                ],
              ),
            ),
            Text(
              'check your inbox to verify your email.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () async {
                await widget.user.reload();

                if (FirebaseAuth.instance.currentUser!.emailVerified) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DashboardPage()),
                    (route) =>
                        false, //* This line removes all previous routes from the stack
                  );
                } else {
                  EasyLoading.showInfo(
                      'Email isn\'t verified. Take a look at your inbox!');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text('I\'ve Verified My Email'),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  await widget.user.sendEmailVerification();
                  EasyLoading.showSuccess('Verification email resent!');
                } catch (e) {
                  EasyLoading.showError(
                      'Failed to resend email. Try again later.');
                }
              },
              icon: Icon(CupertinoIcons.refresh),
              label: Text('Resend'),
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.grey),
              ),
            ),
          ],
        ));
  }
}
