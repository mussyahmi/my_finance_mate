class Transaction {
  final String id;
  final String cycleId;
  final DateTime dateTime;
  final String type;
  final String categoryId;
  final String categoryName;
  final String amount;
  final String note;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.cycleId,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.note,
  });
}
