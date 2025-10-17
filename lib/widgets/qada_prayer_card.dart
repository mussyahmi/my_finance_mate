// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/qada_prayer.dart';
import '../providers/qada_prayer_provider.dart';
import '../extensions/date_time_extensions.dart';

class QadaPrayerCard extends StatelessWidget {
  final String prayerName;
  const QadaPrayerCard({super.key, required this.prayerName});

  @override
  Widget build(BuildContext context) {
    return Selector<QadaPrayerProvider, QadaPrayer?>(
      selector: (_, provider) => provider.getPrayerByName(prayerName),
      shouldRebuild: (prev, next) =>
          prev?.count != next?.count || prev?.updatedAt != next?.updatedAt,
      builder: (context, prayer, _) {
        if (prayer == null) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Card(
            margin: const EdgeInsets.all(8),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    prayer.prayerName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Last updated\n${prayer.updatedAt.getDateText()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: prayer.count > 0
                            ? () => context
                                .read<QadaPrayerProvider>()
                                .updatePrayerCount(
                                  context,
                                  prayer.prayerName,
                                  prayer.count - 1,
                                )
                            : null,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final controller = TextEditingController(
                              text: prayer.count.toString());
                          final result = await showDialog<int>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Set ${prayer.prayerName} count"),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: "Enter count"),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel")),
                                ElevatedButton(
                                  onPressed: () {
                                    final value = int.tryParse(controller.text);
                                    if (value != null && value >= 0) {
                                      Navigator.pop(context, value);
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            prayer.count.toString(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => context
                            .read<QadaPrayerProvider>()
                            .updatePrayerCount(
                              context,
                              prayer.prayerName,
                              prayer.count + 1,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
