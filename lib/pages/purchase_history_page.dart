import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../extensions/string_extension.dart';
import '../widgets/tag.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('purchases')
                .where('user_id', isEqualTo: _userId)
                .orderBy('premium_start_date', descending: true)
                .snapshots(),
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
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'No purchases found.',
                    textAlign: TextAlign.center,
                  ),
                ); //* Display a message for no wishlist
              } else {
                final purchases = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final data =
                        purchases[index].data() as Map<String, dynamic>;
                    final start =
                        (data['premium_start_date'] as Timestamp).toDate();
                    final end =
                        (data['premium_end_date'] as Timestamp).toDate();
                    final now = DateTime.now();
                    final isActive = now.isBefore(end);

                    final currencySymbol =
                        data['currency_symbol']?.toString() ?? '-';
                    final rawPrice = data['raw_price']?.toString() ?? '-';
                    final String productId =
                        data['product_id'] ?? 'Unknown Plan';
                    final platform = data['platform'] ?? 'Unknown';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                  productId
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
                                  .format(start)),
                              Text(
                                platform,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${currencySymbol.trim()}$rawPrice',
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
