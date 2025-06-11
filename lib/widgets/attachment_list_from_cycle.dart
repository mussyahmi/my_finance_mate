import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/cycle.dart';
import '../models/transaction.dart' as t;

class AttachmentListFromCycle extends StatelessWidget {
  final Cycle cycle;
  final List<t.Transaction> transactions;

  const AttachmentListFromCycle({
    super.key,
    required this.cycle,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desiredItemWidth = 180.0; // You can tweak this
    final crossAxisCount = (screenWidth / desiredItemWidth).floor().clamp(1, 6);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cycle.cycleName,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        SizedBox(
          height: (transactions.length / crossAxisCount).ceil() * 250,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // disables scroll
            itemCount: transactions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8, // Adjust height ratio
            ),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final imageUrl =
                  transaction.files.isNotEmpty ? transaction.files[0] : null;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    //* Show the transaction summary dialog when tapped
                    transaction.showTransactionDetails(context, cycle,
                        showButtons: false);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                key: ValueKey(imageUrl),
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            if (transaction.files.length > 1)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${transaction.files.length} attachments',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            transaction.type == 'transfer'
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0, vertical: 2.0),
                                          child: Text(
                                            transaction.accountName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                          child: Icon(
                                            CupertinoIcons
                                                .arrow_right_arrow_left,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0, vertical: 2.0),
                                          child: Text(
                                            transaction.accountToName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      transaction.categoryName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                            const SizedBox(height: 2),
                            Text(
                              transaction.note.contains('insert')
                                  ? ParchmentDocument.fromJson(
                                          jsonDecode(transaction.note))
                                      .toPlainText()
                                  : transaction.note.split('\\n')[0],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No attachments available',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
