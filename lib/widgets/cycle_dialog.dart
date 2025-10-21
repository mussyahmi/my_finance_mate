// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/cycle_provider.dart';
import '../services/message_services.dart';

class CycleDialog extends StatefulWidget {
  final Person user;
  final Cycle cycle;
  final String title;

  const CycleDialog({
    super.key,
    required this.user,
    required this.cycle,
    required this.title,
  });

  @override
  State<CycleDialog> createState() => _CycleDialogState();
}

class _CycleDialogState extends State<CycleDialog> {
  final MessageService messageService = MessageService();
  final TextEditingController _cycleNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late DateTime _cycleEndDate;

  @override
  void initState() {
    super.initState();
    _cycleNameController.text = widget.cycle.cycleName;
    _cycleEndDate = widget.cycle.endDate;
  }

  @override
  void dispose() {
    _cycleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('Edit ${widget.title}'),
        content: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title == 'Cycle Name')
                    TextFormField(
                      controller: _cycleNameController,
                      decoration: InputDecoration(
                        labelText: widget.title,
                      ),
                    ),
                  if (widget.title == 'End Date')
                    ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _cycleEndDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            _cycleEndDate = selectedDate
                                .add(const Duration(days: 1))
                                .subtract(const Duration(minutes: 1));
                          });
                        }
                      },
                      child: Text(
                        DateFormat('EE, d MMM yyyy h:mm aa')
                            .format(_cycleEndDate),
                      ),
                    ),
                ],
              )),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              EasyLoading.show(
                dismissOnTap: false,
                status: messageService.getRandomUpdateMessage(),
              );

              if (widget.title == 'Cycle Name') {
                final cycleName = _cycleNameController.text;

                if (cycleName.isEmpty) {
                  EasyLoading.showInfo('Please enter cycle\'s name.');
                  return;
                }

                await context
                    .read<CycleProvider>()
                    .updateCycleByAttribute(context, 'cycle_name', cycleName);
              } else if (widget.title == 'End Date') {
                await context
                    .read<CycleProvider>()
                    .updateCycleByAttribute(context, 'end_date', _cycleEndDate);
              }

              EasyLoading.showSuccess(
                  messageService.getRandomDoneUpdateMessage());

              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
