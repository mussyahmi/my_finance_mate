class QadaPrayer {
  final String prayerName;
  int count;

  QadaPrayer({
    required this.prayerName,
    required this.count,
  });

  factory QadaPrayer.fromMap(Map<String, dynamic> data) {
    return QadaPrayer(
      prayerName: data['prayerName'] ?? '',
      count: data['count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayerName': prayerName,
      'count': count,
    };
  }
}
