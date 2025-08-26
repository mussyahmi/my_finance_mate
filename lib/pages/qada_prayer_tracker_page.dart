// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/qada_prayer.dart';
import '../providers/qada_prayer_provider.dart';

class QadaPrayerTrackerPage extends StatefulWidget {
  const QadaPrayerTrackerPage({super.key});

  @override
  State<QadaPrayerTrackerPage> createState() => _QadaPrayerTrackerPageState();
}

class _QadaPrayerTrackerPageState extends State<QadaPrayerTrackerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Qada Prayer Tracker"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<QadaPrayerProvider>()
              .fetchQadaPrayers(context, refresh: true);
        },
        child: Center(
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
                final qadaPrayers = snapshot.data!;

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "💡 Tip: Tap the number to edit directly",
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: qadaPrayers.length,
                        itemBuilder: (context, index) {
                          QadaPrayer prayer = qadaPrayers[index] as QadaPrayer;

                          return Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Card(
                                  child: ListTile(
                                    title: Text(prayer.prayerName),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove),
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
                                        GestureDetector(
                                          onTap: () async {
                                            final controller =
                                                TextEditingController(
                                                    text: prayer.count
                                                        .toString());

                                            final result =
                                                await showDialog<int>(
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
                                                        Navigator.pop(
                                                            context), // cancel
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
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
                                                      final value =
                                                          int.tryParse(
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
                                          child: Text(
                                            prayer.count.toString(),
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add),
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
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
