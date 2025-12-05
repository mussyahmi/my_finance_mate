// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';

class PremiumStatusCard extends StatelessWidget {
  final Person user;

  const PremiumStatusCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    Widget? card;

    if (user.isPremium && user.premiumEndDate == null) {
      // 🟢 Lifetime Premium
      card = Card(
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        child: const ListTile(
          title: Text(
            'You have Lifetime Premium Access!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Enjoy unlimited access - no expiry!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    } else if (user.isPremium &&
        user.premiumEndDate != null &&
        user.premiumEndDate!.isAfter(DateTime.now())) {
      // 🟢 Active Premium with expiry date
      card = Card(
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        child: ListTile(
          title: Text(
            'Your Premium access is active until '
            '${DateFormat('EEEE, d MMMM yyyy h:mm aa').format(user.premiumEndDate!)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: const Text(
            'Enjoy the benefits while it lasts!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    } else if (!kIsWeb && !user.isPremium && user.premiumStartDate == null) {
      // 🟠 Free Trial Available
      card = Card(
        color: Theme.of(context).colorScheme.primary,
        child: ListTile(
          title: Text(
            'Start Free 1 Week Trial',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          onTap: () async {
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Activation'),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: const Text(
                      'Are you sure you want to start your free trial?',
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Later'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Activate'),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              EasyLoading.show(
                dismissOnTap: false,
                status: 'Activating your free trial...',
              );

              await context.read<PersonProvider>().activateFreeTrial();

              EasyLoading.showSuccess(
                'Trial activated! Enjoy your premium access',
              );
            }
          },
        ),
      );
    }

    // ✅ If no card, return nothing
    if (card == null) return const SizedBox.shrink();

    // ✅ Add spacing only when the card exists
    return Column(
      children: [
        card,
        const SizedBox(height: 10),
      ],
    );
  }
}
