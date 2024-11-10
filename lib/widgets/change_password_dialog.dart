// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../providers/person_provider.dart';
import '../services/message_services.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final MessageService messageService = MessageService();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              EasyLoading.show(status: messageService.getRandomUpdateMessage());

              final String currentPassword =
                  _currentPasswordController.text.trim();
              final String newPassword = _newPasswordController.text.trim();
              final String confirmPassword =
                  _confirmPasswordController.text.trim();

              final String message =
                  _validate(currentPassword, newPassword, confirmPassword);

              if (message.isNotEmpty) {
                EasyLoading.showInfo(message);
                return;
              }

              await context
                  .read<PersonProvider>()
                  .changePassword(context, currentPassword, newPassword);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _validate(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) {
    //* Check if currentPassword is empty
    if (currentPassword.isEmpty) {
      return 'Current password cannot be empty.';
    }

    //* Check if newPassword is empty
    if (newPassword.isEmpty) {
      return 'New password cannot be empty.';
    }

    //* Validate newPassword length and content
    if (newPassword.length < 8) {
      return 'New password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      return 'New password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
      return 'New password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      return 'New password must contain at least one digit.';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(newPassword)) {
      return 'New password must contain at least one special character.';
    }

    //* Check if confirmPassword is empty
    if (confirmPassword.isEmpty) {
      return 'Confirm password cannot be empty.';
    }

    //* Check if newPassword and confirmPassword match
    if (newPassword != confirmPassword) {
      return 'Passwords do not match.';
    }

    return '';
  }
}
