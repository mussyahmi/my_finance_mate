// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/person.dart';
import '../models/qada_prayer.dart';
import 'person_provider.dart';

class QadaPrayerProvider with ChangeNotifier {
  List<QadaPrayer>? prayers = [];

  QadaPrayerProvider({this.prayers});

  Future<void> fetchQadaPrayers(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<PersonProvider>().user!;

    final qadaPrayersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('qada_prayer')
        .getSavy(refresh: refresh);

    print('fetchQadaPrayers: ${qadaPrayersSnapshot.docs.length}');

    if (qadaPrayersSnapshot.docs.isEmpty) {
      await initializeQadaPrayers(user.uid);
      // After initializing, fetch again
      return fetchQadaPrayers(context, refresh: true);
    }

    prayers = qadaPrayersSnapshot.docs
        .map((doc) => QadaPrayer.fromMap(doc.data()))
        .toList();

    const prayerOrder = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];

    prayers!.sort((a, b) {
      return prayerOrder
          .indexOf(a.prayerName)
          .compareTo(prayerOrder.indexOf(b.prayerName));
    });

    notifyListeners();
  }

  Future<List<Object>> getQadaPrayers(BuildContext context) async {
    if (prayers == null) return [];

    return prayers!;
  }

  //* Initialize qada prayers for a new user
  Future<void> initializeQadaPrayers(String userId) async {
    final defaultPrayers = [
      "Fajr",
      "Dhuhr",
      "Asr",
      "Maghrib",
      "Isha",
    ];

    final batch = FirebaseFirestore.instance.batch();

    for (var prayerName in defaultPrayers) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('qada_prayer')
          .doc(prayerName.toLowerCase());

      batch.set(docRef, {
        "prayerName": prayerName,
        "count": 0,
      });
    }

    await batch.commit();
    print("✅ Initialized qada_prayer for user: $userId");
  }

  Future<void> updatePrayerCount(
      BuildContext context, String prayerName, int newCount) async {
    final Person user = context.read<PersonProvider>().user!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('qada_prayer')
        .doc(prayerName.toLowerCase())
        .set({
      'prayerName': prayerName,
      'count': newCount,
    });

    await fetchQadaPrayers(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$prayerName count updated to $newCount")),
    );
  }
}
