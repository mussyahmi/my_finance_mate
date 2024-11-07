// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

bool forceRefresh = false;

extension FirestoreDocumentExtension
    on DocumentReference<Map<String, dynamic>> {
  Future<DocumentSnapshot<Map<String, dynamic>>> getSavy(
      {bool? refresh}) async {
    if (refresh != null && refresh == true || forceRefresh) {
      print('get from server');
      return get(const GetOptions(source: Source.server));
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> ds =
          await get(const GetOptions(source: Source.cache));

      if (!ds.exists) {
        print('get from server');
        return get(const GetOptions(source: Source.server));
      }

      print('get from cache');
      return ds;
    } catch (_) {
      print('get from server');
      return get(const GetOptions(source: Source.server));
    }
  }
}

extension FirestoreQueryExtension on Query<Map<String, dynamic>> {
  Future<QuerySnapshot<Map<String, dynamic>>> getSavy({bool? refresh}) async {
    if (refresh != null && refresh == true || forceRefresh) {
      print('get from server');
      return get(const GetOptions(source: Source.server));
    }

    try {
      QuerySnapshot<Map<String, dynamic>> qs =
          await get(const GetOptions(source: Source.cache));

      if (qs.docs.isEmpty) {
        print('get from server');
        return get(const GetOptions(source: Source.server));
      }

      print('get from cache');
      return qs;
    } catch (_) {
      print('get from server');
      return get(const GetOptions(source: Source.server));
    }
  }
}
