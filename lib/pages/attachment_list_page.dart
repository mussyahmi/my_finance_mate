import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/transaction.dart' as t;
import '../providers/cycles_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/attachment_list_from_cycle.dart';

class AttachmentListPage extends StatefulWidget {
  const AttachmentListPage({super.key});

  @override
  State<AttachmentListPage> createState() => _AttachmentListPageState();
}

class _AttachmentListPageState extends State<AttachmentListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;
  List<Widget> cyclesWithAttachments = [];
  List<Cycle> cycles = [];
  int cyclesLoaded = 0;
  final int cyclesPerPage = 3;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >= 300 && !_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = true;
        });
      } else if (_scrollController.offset < 300 && _showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchInitialCycles();
  }

  Future<void> _fetchInitialCycles() async {
    final List<Cycle> fetchedCycles =
        await context.read<CyclesProvider>().getCycles(context);

    setState(() {
      cycles = fetchedCycles;
    });

    _loadMore(); // Load initial batch
  }

  Future<void> _loadMore() async {
    if (isLoading || cyclesLoaded >= cycles.length) return;

    setState(() {
      isLoading = true;
    });

    final List<Cycle> nextCycles =
        cycles.skip(cyclesLoaded).take(cyclesPerPage).toList();

    List<Widget> newItems = [];

    for (final cycle in nextCycles) {
      final List<t.Transaction> transactions = await context
          .read<TransactionsProvider>()
          .fetchTransactionsWithAttachmentsFromCycle(context, cycle);

      newItems.add(
        AttachmentListFromCycle(cycle: cycle, transactions: transactions),
      );
    }

    setState(() {
      cyclesWithAttachments.addAll(newItems);
      cyclesLoaded += nextCycles.length;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        body: cyclesWithAttachments.isEmpty
            ? Center(
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'No attachments found.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: cyclesWithAttachments.length + 1,
                  itemBuilder: (_, index) {
                    if (index < cyclesWithAttachments.length) {
                      return cyclesWithAttachments[index];
                    } else if (cyclesLoaded > 0 &&
                        cyclesLoaded < cycles.length) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ElevatedButton(
                              onPressed: _loadMore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : const Text("Load More Cycles"),
                            ),
                          ),
                        ],
                      );
                    }
                    return null;
                  },
                ),
              ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
