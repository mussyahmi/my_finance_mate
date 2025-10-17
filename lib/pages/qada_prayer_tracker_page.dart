// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:my_finance_mate/extensions/date_time_extensions.dart';
import 'package:provider/provider.dart';

import '../models/qada_prayer.dart';
import '../providers/qada_prayer_provider.dart';
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text('Qada Prayer Tracker'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: SingleChildScrollView(
          child: FutureBuilder(
            future: context.watch<QadaPrayerProvider>().getQadaPrayers(context),
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
                    'No qada prayers found.',
                    textAlign: TextAlign.center,
                  ),
                ); //* Display a message for no qada prayers
              } else {
                //* Display the list of qada prayers
                final qadaPrayers = snapshot.data! as List<QadaPrayer>;

                return Column(
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
                    QadaPrayerSummary(qadaPrayers: qadaPrayers),
                    Column(
                      children:
                          qadaPrayers.asMap().entries.map<Widget>((entry) {
                        QadaPrayer prayer = entry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            elevation: 3,
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Prayer title
                                  Text(
                                    prayer.prayerName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Last updated text
                                  Text(
                                    "Last updated\n${prayer.updatedAt.getDateText()}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  const Divider(height: 24),

                                  // Counter row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Minus button
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: () {
                                          if (prayer.count > 0) {
                                            context
                                                .read<QadaPrayerProvider>()
                                                .updatePrayerCount(
                                                  context,
                                                  prayer.prayerName,
                                                  prayer.count - 1,
                                                );
                                          }
                                        },
                                      ),

                                      // Editable count
                                      GestureDetector(
                                        onTap: () async {
                                          final controller =
                                              TextEditingController(
                                            text: prayer.count.toString(),
                                          );

                                          final result = await showDialog<int>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                  "Set ${prayer.prayerName} count"),
                                              content: TextField(
                                                controller: controller,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "Enter count",
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text("Cancel"),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    foregroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary,
                                                  ),
                                                  onPressed: () {
                                                    final value = int.tryParse(
                                                        controller.text);
                                                    if (value != null &&
                                                        value >= 0) {
                                                      Navigator.pop(
                                                          context, value);
                                                    }
                                                  },
                                                  child: const Text("Save"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (result != null) {
                                            context
                                                .read<QadaPrayerProvider>()
                                                .updatePrayerCount(
                                                  context,
                                                  prayer.prayerName,
                                                  result,
                                                );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            prayer.count.toString(),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Plus button
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: () {
                                          context
                                              .read<QadaPrayerProvider>()
                                              .updatePrayerCount(
                                                context,
                                                prayer.prayerName,
                                                prayer.count + 1,
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
