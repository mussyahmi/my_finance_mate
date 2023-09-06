class Budget {
  final String id;
  final String name;
  final String budget;
  final String amountSpent;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.name,
    required this.budget,
    required this.amountSpent,
    required this.updatedAt,
  });

  String amountBalance() {
    return (double.parse(budget) - double.parse(amountSpent))
        .toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(amountSpent) / double.parse(budget);
  }
}
