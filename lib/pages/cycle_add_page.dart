// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../providers/cycle_provider.dart';
import '../services/ad_mob_service.dart';

class CycleAddPage extends StatefulWidget {
  const CycleAddPage({super.key});

  @override
  CycleAddPageState createState() => CycleAddPageState();
}

class CycleAddPageState extends State<CycleAddPage> {
  late Cycle? _cycle;
  TextEditingController cycleNameController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController();
  DateTimeRange? selectedDateRange;
  bool _isLoading = false;

  //* Ad related
  late AdMobService _adMobService;
  BannerAd? _bannerAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _cycle = context.read<CycleProvider>().cycle;

    if (_cycle != null) {
      //* Set the start date to be 1 day after the end date at 12 AM
      DateTime startDate = _cycle!.endDate.add(const Duration(days: 1));
      startDate =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0);

      DateTime endDate = _cycle!.endDate.add(Duration(
          days: _cycle!.endDate.difference(_cycle!.startDate).inDays - 1));
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 0, 0);

      setState(() {
        cycleNameController.text = _cycle!.cycleName;
        openingBalanceController.text = _cycle!.amountBalance;
        selectedDateRange = DateTimeRange(
          start: startDate,
          end: endDate,
        );
      });
    }

    //* Ads realted
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
                              firstDate: _cycle == null
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 365))
                                  : _cycle!.endDate
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
                                '${_cycle == null ? 'Opening' : 'Previous'} Balance',
                            prefixText: 'RM ',
                          ),
                          enabled: _cycle == null,
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
                              await _addCycle();
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

  Future<void> _addCycle() async {
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

    //* Create the new cycle document
    await context.read<CycleProvider>().addCycle(
          context,
          cycleNameController.text,
          selectedDateRange!.start,
          adjustedEndDate,
          double.parse(openingBalanceController.text).toStringAsFixed(2),
        );
  }

  String _validate(
      DateTimeRange? selectedDateRange, String cycleName, String amount) {
    if (selectedDateRange == null) {
      return 'Please select date range.';
    }

    if (selectedDateRange.end.isBefore(DateTime.now())) {
      return 'End date cannot be in the past.';
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
}
