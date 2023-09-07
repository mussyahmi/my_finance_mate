class Cycle {
  String id;
  String cycleNo;
  String cycleName;
  String openingBalance;
  String amountBalance;
  String amountReceived;
  String amountSpent;
  DateTime startDate;
  DateTime endDate;

  Cycle({
    required this.id,
    required this.cycleNo,
    required this.cycleName,
    required this.openingBalance,
    required this.amountBalance,
    required this.amountReceived,
    required this.amountSpent,
    required this.startDate,
    required this.endDate,
  });
}
