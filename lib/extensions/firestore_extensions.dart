// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

bool forceRefresh = false;

extension FirestoreDocumentExtension
    on DocumentReference<Map<String, dynamic>> {
  Future<DocumentSnapshot<Map<String, dynamic>>> getSavy(
      {bool? refresh}) async {
    if (refresh != null && refresh == true || forceRefresh) {
      if (!kReleaseMode) print('get from server');
      return get(const GetOptions(source: Source.server));
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> ds =
          await get(const GetOptions(source: Source.cache));

      if (!ds.exists) {
        if (!kReleaseMode) print('get from server');
        return get(const GetOptions(source: Source.server));
      }

      if (!kReleaseMode) print('get from cache');
      return ds;
    } catch (_) {
      if (!kReleaseMode) print('get from server');
      return get(const GetOptions(source: Source.server));
    }
  }
}

extension FirestoreQueryExtension on Query<Map<String, dynamic>> {
  Future<QuerySnapshot<Map<String, dynamic>>> getSavy({bool? refresh}) async {
    if (refresh != null && refresh == true || forceRefresh) {
      if (!kReleaseMode) print('get from server');
      return get(const GetOptions(source: Source.server));
    }

    try {
      QuerySnapshot<Map<String, dynamic>> qs =
          await get(const GetOptions(source: Source.cache));

      if (qs.docs.isEmpty) {
        if (!kReleaseMode) print('get from server');
        return get(const GetOptions(source: Source.server));
      }

      if (!kReleaseMode) print('get from cache');
      return qs;
    } catch (_) {
      if (!kReleaseMode) print('get from server');
      return get(const GetOptions(source: Source.server));
    }
  }
}
