// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../models/cycle.dart';
import '../models/person.dart';

class CycleDialog extends StatefulWidget {
  final Person user;
  final Cycle cycle;
  final String title;
  final Function onCycleChanged;

  const CycleDialog({
    super.key,
    required this.user,
    required this.cycle,
    required this.title,
    required this.onCycleChanged,
  });

  @override
  State<CycleDialog> createState() => _CycleDialogState();
}

class _CycleDialogState extends State<CycleDialog> {
  final TextEditingController _cycleNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cycleNameController.text = widget.cycle.cycleName;
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter cycle\'s name.';
                        }
                        return null;
                      },
                    ),
                ],
              )),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); //* Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              if (widget.title == 'Cycle Name') {
                final cycleName = _cycleNameController.text;

                if (cycleName.isEmpty) {
                  final snackBar = SnackBar(
                    content: Text(
                      'Please enter cycle\'s name.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onError),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    showCloseIcon: true,
                    closeIconColor: Theme.of(context).colorScheme.onError,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  return;
                }

                await Cycle.updateCycle(
                  widget.user,
                  widget.cycle.id,
                  'cycle_name',
                  cycleName,
                );
              }

              //* Notify the parent widget about the cycle changes
              widget.onCycleChanged();

              //* Close the dialog
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
