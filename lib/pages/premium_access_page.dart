// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../services/purchase_service.dart';
import '../widgets/premium_feature_tile.dart';
import '../widgets/subscription_option.dart';

class PremiumSubscriptionPage extends StatefulWidget {
  const PremiumSubscriptionPage({super.key});

  @override
  State<PremiumSubscriptionPage> createState() =>
      _PremiumSubscriptionPageState();
}

class _PremiumSubscriptionPageState extends State<PremiumSubscriptionPage> {
  final PurchaseService _purchaseService = PurchaseService();
  List products = [];

  @override
  void initState() {
    super.initState();
    _initializePurchaseService();
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize(context);

    setState(() {
      products = _purchaseService.products;
    });
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

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
                'Premium Access',
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
                  title: 'Unlimited Daily Transactions',
                  description:
                      'Perform unlimited daily transactions, breaking the limit of 5 transactions in the free version.',
                  icon: CupertinoIcons.infinite,
                ),
                PremiumFeatureTile(
                  title: 'Ad-Free Experience',
                  description:
                      'Enjoy an uninterrupted experience with no ads while using the app.',
                  icon: Icons.block,
                ),
                PremiumFeatureTile(
                  title: 'Switch Between Financial Cycles',
                  description:
                      'Access past and future financial cycles seamlessly for a comprehensive financial overview.',
                  icon: CupertinoIcons.repeat,
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
                  icon: CupertinoIcons.paperclip,
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
                products.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Column(
                        children: products
                            .map((product) => SubscriptionOption(
                                  product: product,
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 30),
                if (user.isPremium && user.premiumEndDate == null)
                  Card(
                    surfaceTintColor: Theme.of(context).colorScheme.primary,
                    child: ListTile(
                      title: Text(
                        'You have Lifetime Premium Access!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        'Enjoy unlimited access - no expiry!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
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
                              title: Text('Confirm Activation'),
                              content: Text(
                                  'Are you sure you want to start your free trial?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Text('Later'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Text('Activate'),
                                ),
                              ],
                            );
                          },
                        );

                        //* Proceed only if the user confirmed
                        if (confirm == true) {
                          EasyLoading.show(
                              status: 'Activating your free trial...');

                          await context
                              .read<PersonProvider>()
                              .activateFreeTrial();

                          EasyLoading.showSuccess(
                              "Trial activated! Enjoy your premium access");
                        }
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
