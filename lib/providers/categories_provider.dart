// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../models/transaction.dart' as t;
import '../services/ad_mob_service.dart';
import 'cycle_provider.dart';
import 'transactions_provider.dart';
import 'user_provider.dart';

class CategoriesProvider extends ChangeNotifier {
  List<Category>? categories;

  CategoriesProvider({this.categories});

  Future<void> fetchCategories(BuildContext context, Cycle cycle,
      {bool? refresh}) async {
    final Person user = context.read<UserProvider>().user!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycle.id);
    final categoriesRef = cyclesRef.collection('categories');

    final categorySnapshot = await categoriesRef
        .where('deleted_at', isNull: true)
        .orderBy('name')
        .getSavy(refresh: refresh);
    print('fetchCategories: ${categorySnapshot.docs.length}');

    final futureCategories = categorySnapshot.docs.map((doc) async {
      final data = doc.data();

      return Category(
        id: doc.id,
        name: data['name'],
        type: data['type'],
        note: data['note'],
        budget: data['budget'],
        totalAmount: data['total_amount'],
        cycleId: cycle.id,
        updatedAt: (data['updated_at'] as Timestamp).toDate(),
      );
    }).toList();

    categories = await Future.wait(futureCategories);
    notifyListeners();
  }

  Future<List<Category>> getBudgets(BudgetFilter currentFilter) async {
    if (categories == null) return [];

    List<Category> budgets = categories!.where((category) {
      if (category.type == 'spent' && category.budget != '0.00') {
        return true;
      } else {
        return false;
      }
    }).toList();

    //* Sort the list by 'updated_at' in descending order (most recent first)
    budgets.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

    //* Filter categories based on the selected filter
    List<Category> filteredBudgets;
    switch (currentFilter) {
      case BudgetFilter.ongoing:
        filteredBudgets = budgets
            .where((budget) => double.parse(budget.amountBalance()) > 0)
            .toList();
        break;
      case BudgetFilter.exceeded:
        filteredBudgets = budgets
            .where((budget) => double.parse(budget.amountBalance()) < 0)
            .toList();
        break;
      case BudgetFilter.completed:
        filteredBudgets = budgets
            .where((budget) => double.parse(budget.amountBalance()) <= 0)
            .toList();
        break;
      case BudgetFilter.all:
      default:
        filteredBudgets = budgets;
        break;
    }

    return filteredBudgets;
  }

  Future<List<Object>> getCategories(
      BuildContext context, String? type, String fromPage) async {
    List<Category> filteredCategories = [];

    if (type != null) {
      filteredCategories =
          categories!.where((category) => category.type == type).toList();

      if (fromPage == 'transaction_form' || fromPage == 'transaction_list') {
        return filteredCategories;
      }
    } else {
      filteredCategories = categories!
          .where((category) => double.parse(category.totalAmount) > 0)
          .toList();
    }

    List<Object> objectList = List<Object>.from(filteredCategories);

    final adMobService = context.read<AdMobService>();

    if (adMobService.status) {
      String adUnitId = '';

      if (fromPage == 'category_list') {
        adUnitId = adMobService.bannerCategoryListAdUnitId!;
      } else if (fromPage == 'category_summary') {
        adUnitId = adMobService.bannerCategorySummaryAdUnitId!;
      }

      adMobService.initialization.then((value) {
        for (var i = 2; i < objectList.length; i += 7) {
          objectList.insert(
              i,
              BannerAd(
                size: AdSize.banner,
                adUnitId: adUnitId,
                listener: adMobService.bannerAdListener,
                request: const AdRequest(),
              )..load());

          if (i >= 16) {
            //* max 3 ads
            break;
          }
        }
      });
    }

    if (fromPage == 'category_summary') {
      objectList.insert(
        objectList.length,
        const SizedBox(height: 20),
      );
    }

    return objectList;
  }

  Future<void> recalculateCategoryAndCycleTotalAmount(
      BuildContext context) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;
    final List<Category> categories =
        context.read<CategoriesProvider>().categories!;
    final List<t.Transaction> transactions =
        context.read<TransactionsProvider>().transactions!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycle.id);
    final categoriesRef = cyclesRef.collection('categories');

    final categoriesSnapshot = await categoriesRef.getSavy();
    print(
        'recalculateCategoryAndCycleTotalAmount - categoriesSnapshot: ${categoriesSnapshot.docs.length}');

    //* Get current timestamp
    final now = DateTime.now();

    print('initiate recalculateCategoryTotalAmount');

    double totalAmountSpent = 0;
    double totalAmountReceived = 0;

    for (var category in categories) {
      double totalAmount = 0;

      final filteredTransactions = transactions
          .where((transaction) => transaction.categoryId == category.id);

      for (var transaction in filteredTransactions) {
        totalAmount += double.parse(transaction.amount);

        if (transaction.type == 'spent') {
          totalAmountSpent += double.parse(transaction.amount);
        } else {
          totalAmountReceived += double.parse(transaction.amount);
        }
      }

      //* Update each cateogry's data
      await categoriesRef.doc(category.id).update({
        'total_amount': totalAmount.toStringAsFixed(2),
        'updated_at': now,
      });
      if (totalAmount > 0) {
        print('${category.name}: ${totalAmount.toStringAsFixed(2)}');
      }
    }

    //* Update the cycle document
    await cyclesRef.update({
      'amount_spent': totalAmountSpent.toStringAsFixed(2),
      'amount_received': totalAmountReceived.toStringAsFixed(2),
      'amount_balance': (double.parse(cycle.openingBalance) +
              totalAmountReceived -
              totalAmountSpent)
          .toStringAsFixed(2),
      'updated_at': now,
    });

    print('done recalculateCategoryTotalAmount');
  }

  Category getACategoryById(categoryId) {
    return categories!.firstWhere((category) => category.id == categoryId);
  }

  Future<void> updateCategory(
      BuildContext context,
      String action,
      String type,
      String categoryName,
      bool isBudgetEnabled,
      String categoryBudget,
      String categoryNote,
      {Category? category}) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    try {
      //* Get current timestamp
      final now = DateTime.now();

      if (action == 'Add') {
        //* Create the new category document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(cycle.id)
            .collection('categories')
            .add({
          'name': categoryName,
          'budget': double.parse(isBudgetEnabled ? categoryBudget : '0.00')
              .toStringAsFixed(2),
          'note': categoryNote,
          'type': type,
          'total_amount': '0.00',
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        });
      } else if (action == 'Edit') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cycles')
            .doc(cycle.id)
            .collection('categories')
            .doc(category!.id)
            .update({
          'name': categoryName,
          'budget': double.parse(isBudgetEnabled ? categoryBudget : '0.00')
              .toStringAsFixed(2),
          'note': categoryNote,
          'updated_at': now,
        });

        //* If the category name is modified, propagate the change to all associated transactions
        if (category.name != categoryName) {
          final transactionsRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions');

          final transactionsSnapshot = await transactionsRef
              .where('category_id', isEqualTo: category.id)
              .where('deleted_at', isNull: true)
              .getSavy();
          print(
              'updateCategory - transactionsSnapshot: ${transactionsSnapshot.docs.length}');

          for (var doc in transactionsSnapshot.docs) {
            await transactionsRef
                .doc(doc.id)
                .update({'category_name': categoryName});
          }

          await context
              .read<TransactionsProvider>()
              .fetchTransactions(context, cycle);
        }
      }

      await context.read<CategoriesProvider>().fetchCategories(context, cycle);
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      print('Error $action category: $e');
    }
  }

  Future<void> updateCategoryFromTransaction(
    BuildContext context,
    String action,
    String type,
    String? categoryId,
    String amount,
    DateTime now,
    t.Transaction? transaction,
  ) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;
    final List<Category> categories =
        context.read<CategoriesProvider>().categories!;

    double prevTotalAmount = 0;
    late Category prevCategory;

    if (action != 'Add' && transaction!.type != 'transfer') {
      //* Update previous category's data
      prevCategory = getACategoryById(transaction.categoryId);

      prevTotalAmount = double.parse(prevCategory.totalAmount) -
          double.parse(transaction.amount);

      //* Update previous category document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc(cycle.id)
          .collection('categories')
          .doc(transaction.categoryId)
          .update({
        'total_amount': prevTotalAmount.toStringAsFixed(2),
        'updated_at': now,
      });
    }

    if (action != 'Delete' && type != 'transfer') {
      //* Update new category's data
      final Category newCategory =
          categories.firstWhere((category) => category.id == categoryId);

      double newTotalAmount = prevTotalAmount + double.parse(amount);

      if (action == 'Add' || prevCategory.id != newCategory.id) {
        newTotalAmount =
            double.parse(newCategory.totalAmount) + double.parse(amount);
      }

      //* Update new category document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc(cycle.id)
          .collection('categories')
          .doc(categoryId)
          .update({
        'total_amount': newTotalAmount.toStringAsFixed(2),
        'updated_at': now,
      });
    }
  }

  Future<void> deleteCategory(
    BuildContext context,
    String categoryId,
  ) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycle.id);
    final categoriesRef = cyclesRef.collection('categories');
    final categoryRef = categoriesRef.doc(categoryId);

    //* Update the 'deleted_at' field with the current timestamp
    final now = DateTime.now();
    categoryRef.update({
      'updated_at': now,
      'deleted_at': now,
    });

    categories!.removeWhere((category) => category.id == categoryId);
    notifyListeners();
  }
}
