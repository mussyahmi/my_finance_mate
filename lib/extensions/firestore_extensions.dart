import 'package:cloud_firestore/cloud_firestore.dart';

extension FirestoreDocumentExtension
    on DocumentReference<Map<String, dynamic>> {
  Future<DocumentSnapshot<Map<String, dynamic>>> getSavy(
      {bool? refresh}) async {
    if (refresh != null && refresh == true) {
      return get(const GetOptions(source: Source.server));
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> ds =
          await get(const GetOptions(source: Source.cache));
      if (!ds.exists) return get(const GetOptions(source: Source.server));
      return ds;
    } catch (_) {
      return get(const GetOptions(source: Source.server));
    }
  }
}

extension FirestoreQueryExtension on Query<Map<String, dynamic>> {
  Future<QuerySnapshot<Map<String, dynamic>>> getSavy({bool? refresh}) async {
    if (refresh != null && refresh == true) {
      return get(const GetOptions(source: Source.server));
    }

    try {
      QuerySnapshot<Map<String, dynamic>> qs =
          await get(const GetOptions(source: Source.cache));
      if (qs.docs.isEmpty) return get(const GetOptions(source: Source.server));
      return qs;
    } catch (_) {
      return get(const GetOptions(source: Source.server));
    }
  }
}
