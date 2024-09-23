// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/cycle_provider.dart';
import '../providers/cycles_provider.dart';

class CycleListPage extends StatefulWidget {
  final Person user;
  final Cycle? cycle;

  const CycleListPage({
    super.key,
    required this.user,
    required this.cycle,
  });

  @override
  State<CycleListPage> createState() => _CycleListPageState();
}

class _CycleListPageState extends State<CycleListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Cycle List'),
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
                Column(
                  children: context
                      .read<CyclesProvider>()
                      .cycles!
                      .map<Widget>((cycle) {
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
                                  fontSize: 14, color: Colors.greenAccent),
                            ),
                            Text(
                              'Spent RM${cycle.amountSpent}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.redAccent),
                            ),
                          ],
                        ),
                        trailing: widget.cycle!.cycleNo != cycle.cycleNo
                            ? IconButton.filledTonal(
                                onPressed: () async {
                                  await context
                                      .read<CycleProvider>()
                                      .switchCycle(context, cycle);

                                  Navigator.of(context).pop();
                                },
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
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
