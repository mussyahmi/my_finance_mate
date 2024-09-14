import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../services/ad_mob_service.dart';
import 'dashboard_page.dart';
import '../extensions/firestore_extensions.dart';
import '../models/person.dart';

class CycleAddPage extends StatefulWidget {
  final Person user;
  final bool isFirstCycle;
  final Cycle? lastCycle;

  const CycleAddPage({
    super.key,
    required this.user,
    required this.isFirstCycle,
    this.lastCycle,
  });

  @override
  CycleAddPageState createState() => CycleAddPageState();
}

class CycleAddPageState extends State<CycleAddPage> {
  TextEditingController cycleNameController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController();
  DateTimeRange? selectedDateRange;
  int lastCycleNo = 0;
  bool _isLoading = false;

  //* Ad related
  late AdMobService _adMobService;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstCycle) {
      //* Set the start date to be 1 day after the end date at 12 AM
      DateTime startDate =
          widget.lastCycle!.endDate.add(const Duration(days: 1));
      startDate =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0);

      DateTime endDate = widget.lastCycle!.endDate.add(Duration(
          days: widget.lastCycle!.endDate
                  .difference(widget.lastCycle!.startDate)
                  .inDays -
              1));
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 0, 0);

      setState(() {
        lastCycleNo = widget.lastCycle!.cycleNo;
        cycleNameController.text = widget.lastCycle!.cycleName;
        openingBalanceController.text = widget.lastCycle!.amountBalance;
        selectedDateRange = DateTimeRange(
          start: startDate,
          end: endDate,
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();

    if (_adMobService.status) {
      _adMobService.initialization.then((value) {
        setState(() {
          _bannerAd = BannerAd(
            size: AdSize.fullBanner,
            adUnitId: _adMobService.bannerCycleAddAdUnitId!,
            listener: _adMobService.bannerAdListener,
            request: const AdRequest(),
          )..load();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false, //* Hide the back icon button
            title: const Text('Create New Cycle'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pickedDateRange = await showDateRangePicker(
                              context: context,
                              firstDate: widget.isFirstCycle
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 365))
                                  : widget.lastCycle!.endDate
                                      .add(const Duration(days: 1)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              initialDateRange: selectedDateRange,
                            );

                            if (pickedDateRange != null) {
                              setState(() {
                                selectedDateRange = pickedDateRange;
                              });
                            }
                          },
                          child: Text(
                            selectedDateRange != null
                                ? 'Date Range:\n${DateFormat('EE, d MMM yyyy').format(selectedDateRange!.start)} - ${DateFormat('EE, d MMM yyyy').format(selectedDateRange!.end)}'
                                : 'Select Date Range',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cycleNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: openingBalanceController,
                          keyboardType:
                              TextInputType.number, //* Allow only numeric input
                          decoration: InputDecoration(
                            labelText:
                                '${widget.isFirstCycle ? 'Opening' : 'Previous'} Balance',
                            prefixText: 'RM ',
                          ),
                          enabled: widget.isFirstCycle,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            FocusManager.instance.primaryFocus?.unfocus();

                            if (_isLoading) return;

                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              await _updateTransactionToFirebase(widget.user);
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_bannerAd != null)
                SizedBox(
                  height: 60.0,
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateTransactionToFirebase(Person user) async {
    //* Validate the form data
    final message = _validate(selectedDateRange, cycleNameController.text,
        openingBalanceController.text);

    if (message.isNotEmpty) {
      final snackBar = SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onError,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      return;
    }

    final adjustedEndDate = selectedDateRange!.end
        .add(const Duration(days: 1))
        .subtract(const Duration(minutes: 1));

    //* Get current timestamp
    final now = DateTime.now();

    //* Create the new cycle document
    final newCycleDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .add({
      'cycle_no': lastCycleNo + 1,
      'cycle_name': cycleNameController.text,
      'start_date': selectedDateRange!.start,
      'end_date': adjustedEndDate,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'opening_balance':
          double.parse(openingBalanceController.text).toStringAsFixed(2),
      'amount_balance':
          double.parse(openingBalanceController.text).toStringAsFixed(2),
      'amount_received': '0.00',
      'amount_spent': '0.00',
    });

    if (!widget.isFirstCycle) {
      await copyCategoriesFromLastCycle(
          user, widget.lastCycle!.id, newCycleDoc.id);
    }

    // ignore: use_build_context_synchronously
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage(user: widget.user)),
      (route) => false, //* This line removes all previous routes from the stack
    );
  }

  String _validate(
      DateTimeRange? selectedDateRange, String cycleName, String amount) {
    if (selectedDateRange == null) {
      return 'Please select date range.';
    }

    if (cycleName.isEmpty) {
      return 'Please enter cycle\'s name.';
    }

    if (amount.isEmpty) {
      return 'Please enter opening balance\'s amount.';
    }

    //* Remove any commas from the string
    String cleanedValue = amount.replaceAll(',', '');

    //* Check if the cleaned value is a valid double
    if (double.tryParse(cleanedValue) == null) {
      return 'Please enter a valid number.';
    }

    //* Check if the value is a positive number
    if (double.parse(cleanedValue) <= 0) {
      return 'Please enter a positive value.';
    }

    //* Custom currency validation (you can modify this based on your requirements)
    //* Here, we are checking if the value has up to 2 decimal places
    List<String> splitValue = cleanedValue.split('.');
    if (splitValue.length > 1 && splitValue[1].length > 2) {
      return 'Please enter a valid currency value with up to 2 decimal places';
    }

    openingBalanceController.text = cleanedValue;

    return '';
  }

  Future<void> copyCategoriesFromLastCycle(
      Person user, String lastCycleId, String newCycleId) async {
    final categoriesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(lastCycleId)
        .collection('categories');

    final newCycleRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(newCycleId);

    final categoriesSnapshot = await categoriesRef.getSavy();

    for (var doc in categoriesSnapshot.docs) {
      final categoryData = doc.data();
      categoryData['total_amount'] = '0.00'; //* Set total_amount to '0.00'
      await newCycleRef.collection('categories').add(categoryData);
    }
  }
}
