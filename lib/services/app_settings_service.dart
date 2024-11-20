// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchAppSettings() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('app_settings').doc('maintenance').get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return {'status': false}; //* Default fallback
      }
    } catch (e) {
      print('Error fetching app settings: $e');
      return {'status': false}; //* Fallback in case of errors
    }
  }
}
