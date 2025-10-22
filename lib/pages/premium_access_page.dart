// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../services/purchase_service.dart';
import '../widgets/premium_feature_tile.dart';
import '../widgets/premium_status_card.dart';
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
    _purchaseService.dispose();
    await _purchaseService.initialize(context);

    List<String> productOrder = [
      '1_day_access',
      '1_week_access',
      '1_month_access',
      '1_year_access',
      'monthly_access',
      'yearly_access'
    ];

    setState(() {
      products = _purchaseService.products
        ..sort((a, b) =>
            productOrder.indexOf(a.id).compareTo(productOrder.indexOf(b.id)));
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
                PremiumStatusCard(user: user),
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
                      'Enjoy an uninterrupted experience with no ads while using My Finance Mate.',
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
                // ElevatedButton(
                //   onPressed: () async {
                //     await InAppPurchase.instance.restorePurchases();
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Theme.of(context).colorScheme.primary,
                //     foregroundColor: Theme.of(context).colorScheme.onPrimary,
                //   ),
                //   child: Text('Restore Purchases'),
                // ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
