import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cycle.dart';
import '../widgets/cycle_summary.dart';
import 'cycle_list_page.dart';
import '../extensions/firestore_extensions.dart';

class CyclePage extends StatefulWidget {
  final Cycle? cycle;

  const CyclePage({super.key, required this.cycle});

  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Cycle'),
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
                const SizedBox(height: 20),
                CycleSummary(cycle: widget.cycle),
                const SizedBox(height: 20),
                _card('Cycle Name', widget.cycle?.cycleName),
                _card(
                    'Start Date',
                    widget.cycle != null
                        ? DateFormat('EE, d MMM yyyy h:mm aa')
                            .format(widget.cycle!.startDate)
                        : ''),
                _card(
                    'End Date',
                    widget.cycle != null
                        ? DateFormat('EE, d MMM yyyy h:mm aa')
                            .format(widget.cycle!.endDate)
                        : ''),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Past Cycle List',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CycleListPage(
                                  cycle: widget.cycle,
                                ),
                              ),
                            );
                          },
                          child: const Text('View All'))
                    ],
                  ),
                ),
                FutureBuilder(
                  future: _fetchCycles(),
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
                      final cycles = snapshot.data!;
                      return Column(
                        children: cycles.map<Widget>((cycle) {
                          return Card(
                            child: ListTile(
                              title: Text(
                                cycle.cycleName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Received RM${cycle.amountReceived}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.greenAccent),
                                  ),
                                  Text(
                                    'Spent RM${cycle.amountSpent}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                              trailing: IconButton.filledTonal(
                                onPressed: () async {},
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card _card(String title, String? data) {
    return Card(
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          data ?? '',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: IconButton.filledTonal(
          onPressed: () async {},
          icon: Icon(
            Icons.edit,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<List<Cycle>> _fetchCycles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated.
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    final cyclesQuery = await cyclesRef
        .where('deleted_at', isNull: true)
        .orderBy('cycle_no', descending: true)
        .limit(5) //* Limit to 5 items
        .getSavy();

    final cycles = cyclesQuery.docs.map((doc) async {
      final data = doc.data();

      //* Create a Transaction object with the category name
      return Cycle(
        id: doc.id,
        cycleNo: data['cycle_no'],
        cycleName: data['cycle_name'],
        openingBalance: data['opening_balance'],
        amountBalance: data['amount_balance'],
        amountReceived: data['amount_received'],
        amountSpent: data['amount_spent'],
        startDate: (data['start_date'] as Timestamp).toDate(),
        endDate: (data['end_date'] as Timestamp).toDate(),
      );
    }).toList();

    var result = await Future.wait(cycles);

    return result;
  }
}
