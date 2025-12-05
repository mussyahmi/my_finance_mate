// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/wishlist.dart';
import '../pages/note_input_page.dart';
import '../providers/wishlist_provider.dart';
import '../services/message_services.dart';

class WishlistDialog extends StatefulWidget {
  final String action;
  final Wishlist? wish;

  const WishlistDialog({
    super.key,
    required this.action,
    required this.wish,
  });

  @override
  WishlistDialogState createState() => WishlistDialogState();
}

class WishlistDialogState extends State<WishlistDialog> {
  final MessageService messageService = MessageService();
  final TextEditingController _wishlistNameController = TextEditingController();
  final TextEditingController _wishlistNoteController = TextEditingController();
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();

    if (widget.wish != null) {
      _wishlistNameController.text = widget.wish!.name;
      _wishlistNoteController.text = widget.wish!.note;
      _isPinned = widget.wish!.isPinned;
    }
  }

  @override
  void dispose() {
    _wishlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('${widget.action} Wishlist'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _wishlistNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    onTap: () async {
                      final String? note = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteInputPage(
                            note: _wishlistNoteController.text,
                          ),
                        ),
                      );

                      if (note == null) {
                        return;
                      }

                      if (note == 'empty') {
                        setState(() {
                          _wishlistNoteController.text = '';
                        });
                      } else if (note.isNotEmpty) {
                        setState(() {
                          _wishlistNoteController.text = note;
                        });
                      }
                    },
                    leading: Icon(Icons.notes),
                    title: Text(
                      _wishlistNoteController.text.isEmpty
                          ? 'Add Note'
                          : _wishlistNoteController.text.contains('insert')
                              ? ParchmentDocument.fromJson(
                                      jsonDecode(_wishlistNoteController.text))
                                  .toPlainText()
                              : _wishlistNoteController.text.split('\\n')[0],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Pin Wish'),
                    Checkbox(
                      value: _isPinned,
                      onChanged: (bool? value) {
                        setState(() {
                          _isPinned = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                status: widget.action == 'Edit'
                    ? messageService.getRandomUpdateMessage()
                    : messageService.getRandomAddMessage(),
              );

              final wishlistName = _wishlistNameController.text;
              final wishlistNote = _wishlistNoteController.text;

              final message = _validate(wishlistName);

              if (message.isNotEmpty) {
                EasyLoading.showInfo(message);
                return;
              }

              await context.read<WishlistProvider>().updateWishlist(
                    context,
                    widget.action,
                    wishlistName,
                    wishlistNote,
                    _isPinned,
                    wish: widget.wish,
                  );

              EasyLoading.showSuccess(widget.action == 'Edit'
                  ? messageService.getRandomDoneUpdateMessage()
                  : messageService.getRandomDoneAddMessage());

              Navigator.of(context).pop(true);
            },
            child: Text(widget.action == 'Edit' ? 'Save' : widget.action),
          ),
        ],
      ),
    );
  }

  String _validate(String name) {
    if (name.isEmpty) {
      return 'Please enter the wishlist\'s name.';
    }

    return '';
  }
}
