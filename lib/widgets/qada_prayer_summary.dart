// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/qada_prayer.dart';
import '../providers/qada_prayer_provider.dart';

class QadaPrayerSummary extends StatefulWidget {
  final List<QadaPrayer> qadaPrayers;

  const QadaPrayerSummary({super.key, required this.qadaPrayers});

  @override
  State<QadaPrayerSummary> createState() => _QadaPrayerSummaryState();
}

class _QadaPrayerSummaryState extends State<QadaPrayerSummary> {
  @override
  Widget build(BuildContext context) {
    int dailyTarget = context.read<QadaPrayerProvider>().dailyTarget;

    return Builder(
      builder: (context) {
        final totalPrayers = widget.qadaPrayers.fold<int>(
          0,
          (sum, prayer) => sum + prayer.count,
        );

        if (totalPrayers == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.celebration,
                        color: Theme.of(context).colorScheme.primary, size: 40),
                    SizedBox(height: 12),
                    Text(
                      "🎉 You have no pending qada prayers!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Keep it up! May Allah accept.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final daysNeeded = (totalPrayers / dailyTarget).ceil();
        final completionDate = DateTime.now().add(Duration(days: daysNeeded));

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
                  Text(
                    "Completion Estimation",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total prayers left
                  Text(
                    "You have $totalPrayers qada prayers left.",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Editable daily target
                  GestureDetector(
                    onTap: () async {
                      final controller =
                          TextEditingController(text: dailyTarget.toString());

                      final result = await showDialog<int>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Set Daily Target"),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Prayers per day",
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () {
                                final value = int.tryParse(controller.text);
                                if (value != null && value > 0) {
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
                            .updateDailyTarget(context, result);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Daily target: $dailyTarget prayers",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Days and date estimation
                  Text(
                    "⏳ About $daysNeeded days needed",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "📅 Completion by: ${DateFormat('EEEE, d MMM yyyy').format(completionDate)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
