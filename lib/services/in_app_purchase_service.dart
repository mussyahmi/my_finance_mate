// import 'package:in_app_purchase/in_app_purchase.dart';

// class InAppPurchaseService {
//   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
//   bool _available = false;
//   List<ProductDetails> products = [];
//   List<PurchaseDetails> purchases = [];

//   Future<void> initStoreInfo() async {
//     _available = await _inAppPurchase.isAvailable();
//     if (!_available) return;

//     const Set<String> productIds = {
//       'premium_1_day',
//       'premium_1_week',
//       'premium_1_month',
//       'premium_1_year',
//     };

//     final ProductDetailsResponse response =
//         await _inAppPurchase.queryProductDetails(productIds);
//     if (response.notFoundIDs.isNotEmpty) {
//       //* Handle missing products
//     }
//     products = response.productDetails;
//   }

//   void buyProduct(ProductDetails productDetails) {
//     final PurchaseParam purchaseParam =
//         PurchaseParam(productDetails: productDetails);
//     _inAppPurchase.buyConsumable(
//         purchaseParam: purchaseParam, autoConsume: true);
//   }

//   void listenToPurchases() {
//     _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> p) {
//       purchases = p;
//       //* Handle purchase updates here
//     });
//   }
// }
