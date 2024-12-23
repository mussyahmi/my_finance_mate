import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';

class SubscriptionOption extends StatelessWidget {
  final ProductDetails product;

  const SubscriptionOption({
    required this.product,
    super.key,
  });

  String _getTitle() {
    if (product.id == 'one_day_access') {
      return '1 Day Access';
    } else if (product.id == 'one_week_access') {
      return '1 Week Access';
    } else if (product.id == 'monthly_access') {
      return 'Monthly Access';
    } else if (product.id == 'yearly_access') {
      return 'Yearly Access';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.read<PersonProvider>().user!;

    return Card(
      surfaceTintColor: Colors.orange,
      child: ListTile(
        title: Text(
          _getTitle(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.orangeAccent,
          ),
        ),
        subtitle: Text(
          product.description,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Text(
          product.price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.orangeAccent,
          ),
        ),
        onTap: () async {
          if (user.isPremium) {
            EasyLoading.showInfo('Your Premium access is still active.');
          } else {
            final PurchaseParam purchaseParam =
                PurchaseParam(productDetails: product);

            if (product.id == 'one_day_access' ||
                product.id == 'one_week_access') {
              await InAppPurchase.instance
                  .buyConsumable(purchaseParam: purchaseParam);
            } else if (product.id == 'monthly_access' ||
                product.id == 'yearly_access') {
              await InAppPurchase.instance
                  .buyNonConsumable(purchaseParam: purchaseParam);
            }
          }
        },
      ),
    );
  }
}
