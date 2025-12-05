// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/image_view_page.dart';
import '../pages/transaction_form_page.dart';
import '../providers/transactions_provider.dart';
import '../services/message_services.dart';
import '../extensions/string_extension.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import '../widgets/tag.dart';
import 'cycle.dart';

class Transaction {
  String id;
  String cycleId;
  DateTime dateTime;
  String type;
  String? subType;
  String categoryId;
  String categoryName;
  String accountId;
  String accountName;
  String accountToId;
  String accountToName;
  String amount;
  String note;
  List files;
  DateTime createdAt;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.cycleId,
    required this.type,
    required this.subType,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    required this.accountToId,
    required this.accountToName,
    required this.amount,
    required this.note,
    required this.files,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'subType': subType,
      'categoryName': categoryName,
      'accountName': accountName,
      'accountToName': accountToName,
      'amount': amount,
      'note': note,
      'date': dateTime.toIso8601String(),
    };
  }

  void showTransactionDetails(BuildContext context, Cycle cycle,
      {bool showButtons = true}) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: CustomDraggableScrollableSheet(
            initialSize: 0.65,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (showButtons)
                  Row(
                    children: [
                      if (cycle.isLastCycle)
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () async {
                                final result = await _deleteHandler(context);

                                if (result) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(
                                CupertinoIcons.delete_solid,
                                color: Colors.red,
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () async {
                                //* Edit action
                                final bool? result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShowCaseWidget(
                                      builder: (showcaseContext) =>
                                          TransactionFormPage(
                                        action: 'Edit',
                                        transaction: this,
                                        isTourMode: false,
                                        showcaseContext: showcaseContext,
                                      ),
                                    ),
                                  ),
                                );

                                if (result == null) {
                                  return;
                                }

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
                  )
              ],
            ),
            contents: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ID:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(id),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Date:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EE, d MMM yyyy h:mm aa').format(dateTime),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Type:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(type.capitalize()),
                  ],
                ),
                if (type == 'spent')
                  Column(
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sub Type:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Tag(title: subType),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 5),
                if (accountName != '')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Account:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(accountName),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                if (type != 'transfer')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(categoryName),
                    ],
                  ),
                if (type == 'transfer' && accountToName != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transfer To:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(accountToName),
                    ],
                  ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('RM$amount'),
                  ],
                ),
                if (files.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        'Attachment${files.length > 1 ? 's' : ''}:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (var index = 0;
                                    index < files.length;
                                    index++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        //* Open a new screen with the larger image
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageViewPage(
                                              files: files,
                                              index: index,
                                            ),
                                          ),
                                        );
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl: files[index],
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (note.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 5),
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
          ),
        );
      },
    );
  }

  Future<bool> _deleteHandler(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child:
                const Text('Are you sure you want to delete this transaction?'),
          ),
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
              onPressed: () async {
                final MessageService messageService = MessageService();

                EasyLoading.show(
                  dismissOnTap: false,
                  status: messageService.getRandomDeleteMessage(),
                );

                //* Delete the item from Firestore here
                final transactionId = id;

                await context
                    .read<TransactionsProvider>()
                    .deleteTransaction(context, transactionId);

                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  static String extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);
    List<String> parts = uri.path.split('o/');

    //* Removing the first empty part and joining the rest
    return parts.sublist(1).join('/');
  }

  static void deleteFile(String filePath) async {
    Reference storageReference = FirebaseStorage.instance.ref().child(filePath);

    try {
      await storageReference.delete();
      print('File deleted successfully.');
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
