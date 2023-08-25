class Transaction {
  final String id;
  final String cycleId;
  final DateTime dateTime;
  final String type;
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final String amount;
  final String note;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.cycleId,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.amount,
    required this.note,
  });
}
