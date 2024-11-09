// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../providers/cycle_provider.dart';
import '../services/ad_mob_service.dart';
import '../services/message_services.dart';
import '../widgets/ad_container.dart';

class CycleAddPage extends StatefulWidget {
  const CycleAddPage({super.key});

  @override
  CycleAddPageState createState() => CycleAddPageState();
}

class CycleAddPageState extends State<CycleAddPage> {
  final MessageService messageService = MessageService();
  late Cycle? _cycle;
  TextEditingController cycleNameController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  late AdMobService _adMobService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _cycle = context.read<CycleProvider>().cycle;

    if (_cycle != null) {
      //* Set the start date to be 1 day after the end date at 12 AM
      DateTime startDate = _cycle!.endDate.add(const Duration(days: 1));
      startDate =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0);

      DateTime endDate = _cycle!.endDate.add(
          Duration(days: _cycle!.endDate.difference(_cycle!.startDate).inDays));

      setState(() {
        cycleNameController.text = _cycle!.cycleName;
        openingBalanceController.text = _cycle!.amountBalance;
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

    _adMobService = context.read<AdMobService>();
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
                          onPressed: null,
                          child: Text(
                            'Start Date: ${DateFormat('EE, d MMM yyyy h:mm aa').format(_startDate ?? DateTime.now())}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: _startDate ?? DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
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
              if (_adMobService.status)
                AdContainer(
                  adMobService: _adMobService,
                  adSize: AdSize.fullBanner,
                  adUnitId: _adMobService.bannerCycleAddAdUnitId!,
                  height: 60.0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCycle() async {
    EasyLoading.show(status: messageService.getRandomAddMessage());

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
