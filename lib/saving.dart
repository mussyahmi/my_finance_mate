class Saving {
  final String id;
  final String name;
  final String goal;
  final String amountReceived;
  final String openingBalance;
  final String note;
  final DateTime updatedAt;

  Saving({
    required this.id,
    required this.name,
    required this.goal,
    required this.amountReceived,
    required this.openingBalance,
    required this.note,
    required this.updatedAt,
  });

  String amountSaved() {
    final double calculatedAmountSaved =
        double.parse(openingBalance) + double.parse(amountReceived);

    return calculatedAmountSaved.toStringAsFixed(2);
  }

  String amountBalance() {
    final double calculatedAmountBalance = double.parse(goal) -
        (double.parse(openingBalance) + double.parse(amountReceived));

    return calculatedAmountBalance.toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(amountReceived) / double.parse(goal);
  }
}
