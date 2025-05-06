// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/wishlist_provider.dart';
import '../services/message_services.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import '../widgets/wishlist_dialog.dart';
import 'cycle.dart';

class Wishlist {
  String id;
  String name;
  String note;
  bool isPinned;
  DateTime createdAt;

  Wishlist({
    required this.id,
    required this.name,
    required this.note,
    required this.isPinned,
    required this.createdAt,
  });

  void showWishlistDetails(BuildContext context, Cycle cycle) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CustomDraggableScrollableSheet(
          initialSize: 0.45,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wishlist Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  if (cycle.isLastCycle)
                    IconButton.filledTonal(
                      onPressed: () async {
                        final result = await _deleteHandler(context, id);

                        if (result) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.delete_solid,
                        color: Colors.red,
                      ),
                    ),
                  if (cycle.isLastCycle)
                    IconButton.filledTonal(
                      onPressed: () async {
                        final result = await showWishlistDialog(
                            context, 'Edit',
                            wish: this);

                        if (result) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: Icon(
                        CupertinoIcons.pencil,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          contents: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Name:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(name),
                ],
              ),
              if (note.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FleatherEditor(
                      controller: FleatherController(
                        document: ParchmentDocument.fromJson(
                          note.contains('insert')
                              ? jsonDecode(note)
                              : [
                                  {"insert": "$note\n"}
                                ],
                        ),
                      ),
                      showCursor: false,
                      readOnly: true,
                      onLaunchUrl: (url) {
                        launchUrl(Uri.parse(url!));
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _deleteHandler(BuildContext context, String id) async {
    //* Handle delete option
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this wish?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                surfaceTintColor: Colors.red,
                foregroundColor: Colors.redAccent,
              ),
              onPressed: () {
                final MessageService messageService = MessageService();

                EasyLoading.show(
                    status: messageService.getRandomDeleteMessage());

                //* Delete the item from Firestore here
                final wishId = id;

                context.read<WishlistProvider>().deleteWish(context, wishId);

                EasyLoading.showSuccess(
                    messageService.getRandomDoneDeleteMessage());

                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showWishlistDialog(
      BuildContext context, String action,
      {Wishlist? wish}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return WishlistDialog(
          action: action,
          wish: wish,
        );
      },
    );
  }
}
