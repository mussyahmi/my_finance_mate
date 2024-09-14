import 'package:flutter/material.dart';

import '../models/cycle.dart';
import '../models/person.dart';

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
                FutureBuilder(
                  future: Cycle.fetchCycles(widget.user),
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
                              trailing: widget.cycle!.cycleNo != cycle.cycleNo
                                  ? IconButton.filledTonal(
                                      onPressed: () async {},
                                      icon: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )
                                  : null,
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
}
