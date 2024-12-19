// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/person_provider.dart';
import '../services/message_services.dart';

class PersonDialog extends StatefulWidget {
  final Person user;

  const PersonDialog({
    super.key,
    required this.user,
  });

  @override
  State<PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<PersonDialog> {
  final MessageService messageService = MessageService();
  final TextEditingController _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.user.displayName;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('Edit Display Name'),
        content: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
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

              EasyLoading.show(status: messageService.getRandomUpdateMessage());

              final displayName = _displayNameController.text;

              if (displayName.isEmpty) {
                EasyLoading.showInfo('Please enter display name.');
                return;
              }

              await context
                  .read<PersonProvider>()
                  .updateDisplayName(displayName);

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
