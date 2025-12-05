// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/qada_prayer.dart';
import '../providers/qada_prayer_provider.dart';
import '../widgets/qada_prayer_card.dart';
import '../widgets/qada_prayer_summary.dart';

class QadaPrayerTrackerPage extends StatefulWidget {
  const QadaPrayerTrackerPage({super.key});

  @override
  State<QadaPrayerTrackerPage> createState() => _QadaPrayerTrackerPageState();
}

class _QadaPrayerTrackerPageState extends State<QadaPrayerTrackerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              const SliverAppBar(
                title: Text('Qada Prayer Tracker'),
                centerTitle: true,
                scrolledUnderElevation: 9999,
                floating: true,
                snap: true,
              ),
            ],
            body: Consumer<QadaPrayerProvider>(
              builder: (context, provider, _) {
                final qadaPrayers = provider.prayers ?? [];
          
                if (qadaPrayers.isEmpty) {
                  return const Center(child: Text('No qada prayers found.'));
                }
          
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "💡 Tip: Tap the highlighted box to update the count",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
          
                      // Summary
                      Selector<QadaPrayerProvider, List<QadaPrayer>?>(
                        selector: (_, provider) => provider.prayers,
                        builder: (context, prayers, _) =>
                            QadaPrayerSummary(qadaPrayers: prayers ?? []),
                      ),
          
                      // Individual cards
                      Column(
                        children: qadaPrayers
                            .map((p) => QadaPrayerCard(prayerName: p.prayerName))
                            .toList(),
                      ),
          
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
