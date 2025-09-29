import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../extensions/string_extension.dart';
import '../models/purchase.dart';
import '../providers/purchases_provider.dart';
import '../widgets/tag.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Purchase History'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: Center(
          child: FutureBuilder(
            future: context.watch<PurchasesProvider>().getPurchases(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: CircularProgressIndicator(),
                ); //* Display a loading indicator
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SelectableText(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'No purchases found.',
                    textAlign: TextAlign.center,
                  ),
                ); //* Display a message for no purchases
              } else {
                final purchases = snapshot.data!;

                return ListView.builder(
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    Purchase purchase = purchases[index] as Purchase;

                    final isActive =
                        DateTime.now().isBefore(purchase.premiumEndDate);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                  purchase.productId
                                      .split('_')
                                      .map((word) => word.capitalize())
                                      .join(' '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                              const SizedBox(width: 8),
                              Tag(title: isActive ? "active" : "expired"),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('EE, d MMM yyyy h:mm aa')
                                  .format(purchase.premiumStartDate)),
                              Text(
                                purchase.platform == 'Android'
                                    ? 'Google Play'
                                    : purchase.platform == 'iOS'
                                        ? 'Apple App Store'
                                        : purchase.platform.capitalize(),
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${purchase.currencySymbol.trim()}${purchase.rawPrice}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
