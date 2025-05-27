class Purchase {
  String productId;
  DateTime premiumStartDate;
  DateTime premiumEndDate;
  String platform;
  String currencySymbol;
  String rawPrice;

  Purchase({
    required this.productId,
    required this.premiumStartDate,
    required this.premiumEndDate,
    required this.platform,
    required this.currencySymbol,
    required this.rawPrice,
  });
}