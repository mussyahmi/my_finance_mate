import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../providers/cycles_provider.dart';
import '../providers/transactions_provider.dart';

class AttachmentListPage extends StatefulWidget {
  const AttachmentListPage({super.key});

  @override
  State<AttachmentListPage> createState() => _AttachmentListPageState();
}

class _AttachmentListPageState extends State<AttachmentListPage> {
  final ScrollController _scrollController = ScrollController();
  int cyclesToShow = 3; // Start by showing 3 cycles

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const desiredItemWidth = 180.0; // You can tweak this
    final crossAxisCount = (screenWidth / desiredItemWidth).floor().clamp(1, 6);

    return Scaffold(
      floatingActionButton: _scrollController.hasClients &&
              _scrollController.offset > 300 // Show only after scrolling down
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Attachments'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: FutureBuilder(
              future: context.watch<CyclesProvider>().getCycles(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                      ],
                    ),
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
                      'No cycles found.',
                      textAlign: TextAlign.center,
                    ),
                  ); //* Display a message for no cycles
                } else {
                  //* Display the list of cycles
                  final allCycles = snapshot.data!;
                  final visibleCycles = allCycles.take(cyclesToShow).toList();
                  final hasMoreCycles = allCycles.length > visibleCycles.length;

                  return Column(
                    children: [
                      ListView.builder(
                        physics:
                            const NeverScrollableScrollPhysics(), // disables scroll
                        shrinkWrap: true,
                        itemCount: visibleCycles.length,
                        itemBuilder: (context, index) {
                          Cycle cycle = visibleCycles[index];

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  cycle.cycleName,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ),
                              FutureBuilder(
                                future: context
                                    .watch<TransactionsProvider>()
                                    .fetchTransactionsWithAttachmentsFromCycle(
                                        context, cycle),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: SizedBox(
                                        height: 250,
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                    ); //* Display a loading indicator
                                  } else if (snapshot.hasError) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: SelectableText(
                                        'Error: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 16.0),
                                      child: Text(
                                        'No attachments found.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ); //* Display a message for no attachments
                                  } else {
                                    //* Display the list of attachments
                                    final transactions = snapshot.data!;

                                    return SizedBox(
                                      height:
                                          (transactions.length / crossAxisCount)
                                                  .ceil() *
                                              250,
                                      child: GridView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(), // disables scroll
                                        itemCount: transactions.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio:
                                              0.8, // Adjust height ratio
                                        ),
                                        itemBuilder: (context, index) {
                                          final transaction =
                                              transactions[index];
                                          final imageUrl =
                                              transaction.files.isNotEmpty
                                                  ? transaction.files[0]
                                                  : null;

                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            clipBehavior: Clip.antiAlias,
                                            child: InkWell(
                                              onTap: () {
                                                //* Show the transaction summary dialog when tapped
                                                transaction
                                                    .showTransactionDetails(
                                                        context, cycle);
                                              },
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Expanded(
                                                    child: Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child:
                                                              CachedNetworkImage(
                                                            key: ValueKey(
                                                                imageUrl),
                                                            imageUrl: imageUrl,
                                                            fit: BoxFit.cover,
                                                            placeholder: (context,
                                                                    url) =>
                                                                const Center(
                                                                    child:
                                                                        CircularProgressIndicator()),
                                                            errorWidget: (context,
                                                                    url,
                                                                    error) =>
                                                                const Icon(Icons
                                                                    .error),
                                                          ),
                                                        ),
                                                        if (transaction
                                                                .files.length >
                                                            1)
                                                          Positioned(
                                                            top: 8,
                                                            right: 8,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black54,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: Text(
                                                                '${transaction.files.length} attachments',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        10),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 6),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        transaction.type ==
                                                                'transfer'
                                                            ? FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              Colors.grey,
                                                                          width:
                                                                              1.0,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              4.0,
                                                                          vertical:
                                                                              2.0),
                                                                      child:
                                                                          Text(
                                                                        transaction
                                                                            .accountName,
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              4.0),
                                                                      child:
                                                                          Icon(
                                                                        CupertinoIcons
                                                                            .arrow_right_arrow_left,
                                                                        color: Colors
                                                                            .grey,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              Colors.grey,
                                                                          width:
                                                                              1.0,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              4.0,
                                                                          vertical:
                                                                              2.0),
                                                                      child:
                                                                          Text(
                                                                        transaction
                                                                            .accountToName,
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            : FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Text(
                                                                  transaction
                                                                      .categoryName,
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          16),
                                                                ),
                                                              ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          transaction.note
                                                                  .contains(
                                                                      'insert')
                                                              ? ParchmentDocument.fromJson(
                                                                      jsonDecode(
                                                                          transaction
                                                                              .note))
                                                                  .toPlainText()
                                                              : transaction.note
                                                                  .split(
                                                                      '\\n')[0],
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color:
                                                                  Colors.grey),
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
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      if (hasMoreCycles)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Save current scroll position
                                final scrollBefore =
                                    _scrollController.position.maxScrollExtent;

                                setState(() {
                                  cyclesToShow += 3;
                                });

                                // After UI updates, animate to new content
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  final scrollAfter = _scrollController
                                      .position.maxScrollExtent;
                                  final scrollTarget =
                                      scrollAfter > scrollBefore
                                          ? scrollAfter
                                          : scrollBefore;

                                  _scrollController.animateTo(
                                    scrollTarget,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: const Text("Load More Cycles"),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
