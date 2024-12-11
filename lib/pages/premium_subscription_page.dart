// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';

class PremiumSubscriptionPage extends StatelessWidget {
  const PremiumSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<PersonProvider>().user!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Premium Subscription',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Upgrade to Premium and unlock additional tools and customizations to elevate your financial management experience:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                PremiumFeatureTile(
                  title: 'Switch Between Financial Cycles',
                  description:
                      'Access past and future financial cycles seamlessly for a comprehensive financial overview.',
                  icon: Icons.loop,
                ),
                PremiumFeatureTile(
                  title: 'Enhanced Customization',
                  description:
                      'Unlock the ability to customize the app\'s theme color for a truly personalized experience.',
                  icon: Icons.color_lens,
                ),
                PremiumFeatureTile(
                  title: 'Additional Attachment Slots',
                  description:
                      'Attach more images to transactions for thorough and organized record-keeping.',
                  icon: Icons.attachment,
                ),
                PremiumFeatureTile(
                  title: 'Ad-Free Experience',
                  description:
                      'Enjoy an uninterrupted experience with no ads while using the app.',
                  icon: Icons.block,
                ),
                const SizedBox(height: 30),
                Text(
                  'Choose a Plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Select a plan that fits your needs:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                SubscriptionOption(
                  plan: '1-Day Access',
                  price: 'RM 0.90',
                  description: 'Perfect for a quick preview.',
                ),
                SubscriptionOption(
                  plan: '1-Week Access',
                  price: 'RM 3.90',
                  description: 'One-time access for a week.',
                ),
                SubscriptionOption(
                  plan: 'Monthly',
                  price: 'RM 9.90/month',
                  description: 'Cancel anytime for flexibility.',
                ),
                SubscriptionOption(
                  plan: 'Yearly',
                  price: 'RM 99.90/year',
                  description: 'Save 20% compared to monthly.',
                ),
                const SizedBox(height: 30),
                if (user.isPremium &&
                    user.premiumEndDate != null &&
                    user.premiumEndDate!.isAfter(DateTime.now()))
                  Card(
                    surfaceTintColor: Theme.of(context).colorScheme.primary,
                    child: ListTile(
                      title: Text(
                        'Your Premium access is active until ${DateFormat('EEEE, d MMMM yyyy h:mm aa').format(user.premiumEndDate!)}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        'Enjoy the benefits while it lasts!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                if (!user.isPremium && user.premiumStartDate == null)
                  Card(
                    color: Theme.of(context).colorScheme.primary,
                    child: ListTile(
                      title: Text(
                        'Start Free 1-Week Trial',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      onTap: () async {
                        EasyLoading.show(
                            status: 'Activating your free trial...');

                        await context
                            .read<PersonProvider>()
                            .activateFreeTrial();

                        EasyLoading.showSuccess(
                            "Trial activated! Enjoy Premium features.");
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumFeatureTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PremiumFeatureTile({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class SubscriptionOption extends StatelessWidget {
  final String plan;
  final String price;
  final String description;

  const SubscriptionOption({
    required this.plan,
    required this.price,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Person user = context.read<PersonProvider>().user!;

    return Card(
      surfaceTintColor: Colors.orange,
      child: ListTile(
        title: Text(
          plan,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.orangeAccent,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.orangeAccent,
          ),
        ),
        onTap: () {
          if (user.isPremium) {
            EasyLoading.showInfo('Your Premium access is still active.');
          } else {
            EasyLoading.showInfo('Coming Soon!');
          }
        },
      ),
    );
  }
}
