// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../providers/cycle_provider.dart';
import '../providers/person_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../services/message_services.dart';
import '../widgets/ad_container.dart';

class CycleAddPage extends StatefulWidget {
  final Cycle? cycle;

  const CycleAddPage({super.key, required this.cycle});

  @override
  CycleAddPageState createState() => CycleAddPageState();
}

class CycleAddPageState extends State<CycleAddPage> {
  final MessageService messageService = MessageService();
  TextEditingController cycleNameController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  AdMobService? _adMobService;
  AdCacheService? _adCacheService;
  bool _isAcknowledged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.cycle != null) {
      //* Set the start date to be 1 day after the end date at 12 AM
      DateTime startDate = widget.cycle!.endDate.add(const Duration(days: 1));
      startDate =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0);

      DateTime endDate = widget.cycle!.endDate.add(Duration(
          days: widget.cycle!.endDate
              .difference(widget.cycle!.startDate)
              .inDays));

      setState(() {
        cycleNameController.text = widget.cycle!.cycleName;
        openingBalanceController.text = widget.cycle!.amountBalance;
        _startDate = startDate;
        _endDate = endDate;
      });
    } else {
      DateTime startDate = DateTime.now();
      startDate =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0);

      DateTime endDate = startDate.add(const Duration(days: 29));
      endDate = endDate
          .add(const Duration(days: 1))
          .subtract(const Duration(minutes: 1));

      setState(() {
        openingBalanceController.text = '0.00';
        _startDate = startDate;
        _endDate = endDate;
      });
    }

    if (!kIsWeb) {
      _adMobService = context.read<AdMobService>();
      _adCacheService = context.read<AdCacheService>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, //* Hide the back icon button
          title: const Text('Create New Cycle'),
          centerTitle: true,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: null,
                            child: Text(
                              'Start Date: ${DateFormat('EE, d MMM yyyy h:mm aa').format(_startDate ?? DateTime.now())}',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _showEndDateRecommendationDialog(context);

                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );

                              if (selectedDate != null) {
                                setState(() {
                                  _endDate = selectedDate
                                      .add(const Duration(days: 1))
                                      .subtract(const Duration(minutes: 1));
                                });
                              }
                            },
                            child: Text(
                              'End Date: ${DateFormat('EE, d MMM yyyy h:mm aa').format(_endDate ?? DateTime.now())}',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Focus(
                            onFocusChange: (hasFocus) {
                              if (hasFocus && !_isAcknowledged) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cycle Name Info'),
                                    content: ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: 500),
                                      child: const Text(
                                        'Enter a descriptive name for your cycle. Mentioning your salary (e.g., "Nov 2024 Salary") helps you track your finances more clearly and relate each cycle to your income period.',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isAcknowledged = true;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: TextField(
                              controller: cycleNameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                helperText: 'Example: Nov 2024 Salary',
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: openingBalanceController,
                            keyboardType: TextInputType
                                .number, //* Allow only numeric input
                            decoration: InputDecoration(
                              labelText:
                                  '${widget.cycle == null ? 'Opening' : 'Previous'} Balance',
                              prefixText: 'RM',
                            ),
                            enabled: false,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
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
                if (_adMobService != null &&
                    !context.read<PersonProvider>().user!.isPremium)
                  AdContainer(
                    adCacheService: _adCacheService!,
                    number: 1,
                    adSize: AdSize.banner,
                    adUnitId: _adMobService!.bannerCycleAddAdUnitId!,
                    height: 50.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //* Show alert box with recommendation for End Date
  Future<void> _showEndDateRecommendationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Date Recommendation'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: const Text(
              'We recommend selecting the end date as 1 day before your next salary.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCycle() async {
    EasyLoading.show(
      dismissOnTap: false,
      status: messageService.getRandomAddMessage(),
    );

    //* Validate the form data
    final message = _validate(cycleNameController.text);

    if (message.isNotEmpty) {
      EasyLoading.showInfo(message);
      return;
    }

    //* Create the new cycle document
    await context.read<CycleProvider>().addCycle(
          context,
          cycleNameController.text,
          _startDate!,
          _endDate!,
          double.parse(openingBalanceController.text).toStringAsFixed(2),
        );

    EasyLoading.showSuccess(messageService.getRandomDoneAddMessage());
  }

  String _validate(String cycleName) {
    if (cycleName.isEmpty) {
      return 'Please enter the cycle\'s name.';
    }

    return '';
  }
}
