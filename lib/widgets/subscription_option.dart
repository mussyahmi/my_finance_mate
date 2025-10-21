import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../extensions/string_extension.dart';
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
    return product.id.split('_').map((word) => word.capitalize()).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.read<PersonProvider>().user!;

    return Card(
      surfaceTintColor:
          (product.id == 'monthly_access' || product.id == 'yearly_access')
              ? Colors.blue
              : Colors.orange,
      child: ListTile(
        title: Text(
          _getTitle(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: (product.id == 'monthly_access' ||
                    product.id == 'yearly_access')
                ? Colors.blueAccent
                : Colors.orangeAccent,
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
            color: (product.id == 'monthly_access' ||
                    product.id == 'yearly_access')
                ? Colors.blueAccent
                : Colors.orangeAccent,
          ),
        ),
        onTap: () async {
          if (user.isPremium) {
            EasyLoading.showInfo('Your Premium access is still active.');
          } else {
            final PurchaseParam purchaseParam =
                PurchaseParam(productDetails: product);

            if (product.id == '1_day_access' ||
                product.id == '1_week_access' ||
                product.id == '1_month_access' ||
                product.id == '1_year_access') {
              await InAppPurchase.instance
                  .buyConsumable(purchaseParam: purchaseParam);
            } else if (product.id == 'monthly_access' ||
                product.id == 'yearly_access') {
              // await InAppPurchase.instance
              //     .buyNonConsumable(purchaseParam: purchaseParam);

              // coming soon
              EasyLoading.showInfo(
                'This feature is coming soon. Please check back later.',
                duration: const Duration(seconds: 2),
              );
            }
          }
        },
      ),
    );
  }
}
