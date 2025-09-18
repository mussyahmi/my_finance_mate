import 'package:cloud_firestore/cloud_firestore.dart';

class QadaPrayer {
  final String prayerName;
  int count;
  DateTime updatedAt;

  QadaPrayer({
    required this.prayerName,
    required this.count,
    required this.updatedAt,
  });

  factory QadaPrayer.fromMap(Map<String, dynamic> data) {
    return QadaPrayer(
      prayerName: data['prayer_name'] ?? '',
      count: data['count'] ?? 0,
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayer_name': prayerName,
      'count': count,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
