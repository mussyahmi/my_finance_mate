// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/cycle.dart';
import '../services/ad_mob_service.dart';
import 'category_list_page.dart';
import 'image_view_page.dart';
import '../models/transaction.dart' as t;

class TransactionFormPage extends StatefulWidget {
  final Cycle cycle;
  final String action;
  final t.Transaction? transaction;

  const TransactionFormPage({
    super.key,
    required this.cycle,
    required this.action,
    this.transaction,
  });

  @override
  TransactionFormPageState createState() => TransactionFormPageState();
}

class TransactionFormPageState extends State<TransactionFormPage> {
  String selectedType = 'spent';
  String? selectedSubType;
  String? selectedCategoryId;
  List<Category> categories = [];
  TextEditingController transactionAmountController = TextEditingController();
  TextEditingController transactionNoteController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  bool _isLoading = false;
  List<dynamic> files = [];
  List<dynamic> filesToDelete = [];

  //* Ad related
  late AdMobService _adMobService;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();

    if (_adMobService.status) {
      _adMobService.initialization.then((value) {
        setState(() {
          _createInterstitialAd();
        });
      });
    }
  }

  Future<void> initAsync() async {
    await _fetchCategories();

    if (widget.transaction != null) {
      selectedType = widget.transaction!.type;
      selectedSubType = widget.transaction!.subType;
      transactionAmountController.text = widget.transaction!.amount;
      transactionNoteController.text =
          widget.transaction!.note.replaceAll('\\n', '\n');
      selectedDateTime = widget.transaction!.dateTime;
      files = widget.transaction!.files;

      await _fetchCategories();

      selectedCategoryId = widget.transaction!.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: Text('${widget.action} Transaction'),
                centerTitle: true,
                scrolledUnderElevation: 9999,
                floating: true,
                snap: true,
              ),
            ],
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SegmentedButton(
                      segments: const [
                        ButtonSegment(
                          value: 'spent',
                          label: Text('Spent'),
                          icon: Icon(Icons.file_upload_outlined),
                        ),
                        ButtonSegment(
                          value: 'received',
                          label: Text('Received'),
                          icon: Icon(Icons.file_download_outlined),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          selectedType = newSelection.first;
                          selectedCategoryId = null;
                        });

                        _fetchCategories();
                      },
                    ),
                    const SizedBox(height: 10),
                    if (selectedType == 'spent')
                      SegmentedButton(
                        segments: const [
                          ButtonSegment(
                            value: 'needs',
                            label: Text('Needs'),
                          ),
                          ButtonSegment(
                            value: 'wants',
                            label: Text('Wants'),
                          ),
                          ButtonSegment(
                            value: 'savings',
                            label: Text('Savings'),
                          ),
                        ],
                        selected: {selectedSubType},
                        onSelectionChanged: (newSelection) {
                          print(newSelection);
                          setState(() {
                            selectedSubType = newSelection.isNotEmpty
                                ? newSelection.first
                                : null;
                          });
                        },
                        emptySelectionAllowed: true,
                      ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: widget.cycle.startDate,
                          lastDate: widget.cycle.endDate,
                        );
                        if (selectedDate != null) {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (selectedTime != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text(
                        'Date Time: ${DateFormat('EE, d MMM yyyy h:mm aa').format(selectedDateTime)}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      onChanged: (newValue) async {
                        setState(() {
                          selectedCategoryId = newValue;
                        });

                        if (newValue == 'add_new') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return CategoryListPage(
                                cycle: widget.cycle,
                                type: selectedType,
                                isFromTransactionForm: true,
                              );
                            }),
                          );

                          setState(() {
                            selectedCategoryId = null;
                          });

                          _fetchCategories();
                        }
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'add_new',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle),
                              SizedBox(width: 8),
                              Text('Add New'),
                            ],
                          ),
                        ),
                        ...categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: transactionAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'RM ',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: transactionNoteController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    const Text('Attachment:'),
                    if (files.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 10),
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
                                              imageSource:
                                                  files[index] is String
                                                      ? files[index]
                                                      : files[index].path,
                                              type: files[index] is String
                                                  ? 'url'
                                                  : 'local',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          if (files[index] is String)
                                            Image.network(
                                              files[index],
                                              height:
                                                  100, //* Adjust the height as needed
                                              fit: BoxFit.contain,
                                            )
                                          else
                                            Image.file(
                                              File(files[index].path!),
                                              height:
                                                  100, //* Adjust the height as needed
                                              fit: BoxFit.contain,
                                            ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (files[index] is String) {
                                                  setState(() {
                                                    filesToDelete = [
                                                      ...filesToDelete,
                                                      files[index]
                                                    ];
                                                  });
                                                }

                                                setState(() {
                                                  files.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                color: Colors.red,
                                                child: const Icon(Icons.close),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text(
                                'Choose Option',
                                textAlign: TextAlign.center,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      final result =
                                          await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                      );
                                      if (result != null) {
                                        PlatformFile file = result.files.first;

                                        await _checkFileSize(file, file.size);
                                      }
                                    },
                                    child: const Text('Pick from Gallery'),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      final file =
                                          await ImagePicker().pickImage(
                                        source: ImageSource.camera,
                                        imageQuality: 50,
                                      );

                                      if (file != null) {
                                        await _checkFileSize(
                                            file, await file.length());
                                      }
                                    },
                                    child: const Text('Take a Photo'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: const Text('Add Attachment'),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        FocusManager.instance.primaryFocus?.unfocus();

                        if (_isLoading) return;

                        setState(() {
                          _isLoading = true;
                        });

                        if (_adMobService.status) _showInterstitialAd();

                        try {
                          await _updateTransactionToFirebase();
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
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
        ),
      ),
    );
  }

  Future<void> _fetchCategories() async {
    final fetchedCategories =
        await Category.fetchCategories(widget.cycle.id, selectedType);

    setState(() {
      categories = fetchedCategories;
    });
  }

  Future<void> _updateTransactionToFirebase() async {
    //* Get the values from the form
    String type = selectedType;
    String? subType = selectedSubType;
    String? categoryId = selectedCategoryId;
    String amount = transactionAmountController.text;
    String note = transactionNoteController.text.replaceAll('\n', '\\n');
    DateTime dateTime = selectedDateTime;

    //* Validate the form data
    final message = _validate(categoryId, amount);

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

    //* Get current timestamp
    final now = DateTime.now();

    //* Get the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated
      return;
    }

    try {
      //* Reference to the Firestore document to add the transaction
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final transactionsRef = userRef.collection('transactions');

      List downloadURLs = await _uploadAndDeleteFilesToFirebase(user);

      if (widget.action == 'Add') {
        //* Create a new transaction document
        await transactionsRef.add({
          'cycle_id': widget.cycle.id,
          'date_time': dateTime,
          'type': type,
          'subType': selectedType == 'spent' ? subType : null,
          'category_id': categoryId,
          'category_name': categories
              .firstWhere((category) => category.id == categoryId)
              .name,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
          'files': downloadURLs,
        });

        //* Update transactions made
        final userDoc = await userRef.get();

        if (_adMobService.status) {
          await userRef
              .update({'transactions_made': userDoc['transactions_made'] + 1});
        }
      } else if (widget.action == 'Edit') {
        await transactionsRef.doc(widget.transaction!.id).update({
          'date_time': dateTime,
          'type': type,
          'subType': selectedType == 'spent' ? subType : null,
          'category_id': categoryId,
          'category_name': categories
              .firstWhere((category) => category.id == categoryId)
              .name,
          'amount': double.parse(amount).toStringAsFixed(2),
          'note': note,
          'updated_at': now,
          'files': downloadURLs,
        });
      }

      final cyclesRef = userRef.collection('cycles').doc(widget.cycle.id);

      await _updateCycleToFirebase(cyclesRef, type, amount, now);

      await _updateCategoryToFirebase(cyclesRef, categoryId!, amount, now);

      Navigator.of(context).pop(true);
    } catch (e) {
      //* Handle any errors that occur during the Firestore operation
      print('Error saving transaction: $e');
      //* You can show an error message to the user if needed
    }
  }

  String _validate(String? categoryId, String amount) {
    if (categoryId == null || categoryId.isEmpty) {
      return 'Please choose category.';
    }

    if (amount.isEmpty) {
      return 'Please enter transaction\'s amount.';
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

    transactionAmountController.text = cleanedValue;

    return '';
  }

  Future<List> _uploadAndDeleteFilesToFirebase(User user) async {
    List downloadURLs = [];

    for (var file in files) {
      if (file is! String) {
        //* Generate a unique file name
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('${user.uid}/transactions/$fileName');

        UploadTask uploadTask = storageReference.putFile(File(file.path!));

        await uploadTask.whenComplete(() async {
          print('File Uploaded');
          String downloadURL = await storageReference.getDownloadURL();
          print('Download URL: $downloadURL');
          downloadURLs = [...downloadURLs, downloadURL];
        });
      } else {
        //* for existing file
        downloadURLs = [...downloadURLs, file];
      }
    }

    if (widget.action == 'Edit') {
      for (var fileToDelete in filesToDelete) {
        t.Transaction.deleteFile(Uri.decodeComponent(
            t.Transaction.extractPathFromUrl(fileToDelete)));
      }
    }

    return downloadURLs;
  }

  Future<void> _updateCycleToFirebase(DocumentReference cyclesRef, String type,
      String amount, DateTime now) async {
    //* Fetch the current cycle document
    final cycleDoc = await cyclesRef.get();

    if (cycleDoc.exists) {
      final cycleData = cycleDoc.data() as Map<String, dynamic>;

      final double cycleOpeningBalance =
          double.parse(cycleData['opening_balance']);
      double cycleAmountReceived = double.parse(cycleData['amount_received']);
      double cycleAmountSpent = double.parse(cycleData['amount_spent']);

      //* Calculate the cycle's amounts before including this transaction
      if (widget.action == 'Edit') {
        if (type == 'spent') {
          cycleAmountSpent -= double.parse(widget.transaction!.amount);
        } else {
          cycleAmountReceived -= double.parse(widget.transaction!.amount);
        }
      }

      final newAmount = double.parse(amount);

      final double updatedAmountBalance = cycleOpeningBalance +
          cycleAmountReceived -
          cycleAmountSpent +
          (type == 'spent' ? -newAmount : newAmount);

      //* Update the cycle document
      await cyclesRef.update({
        'amount_spent': (cycleAmountSpent + (type == 'spent' ? newAmount : 0))
            .toStringAsFixed(2),
        'amount_received':
            (cycleAmountReceived + (type == 'received' ? newAmount : 0))
                .toStringAsFixed(2),
        'amount_balance': updatedAmountBalance.toStringAsFixed(2),
        'updated_at': now,
      });
    }
  }

  Future<void> _updateCategoryToFirebase(DocumentReference cyclesRef,
      String categoryId, String amount, DateTime now) async {
    //* Update previous category's data
    if (widget.action == 'Edit') {
      final prevCategoryRef = cyclesRef
          .collection('categories')
          .doc(widget.transaction!.categoryId);

      //* Fetch the category document
      final prevCategoryDoc = await prevCategoryRef.get();

      if (prevCategoryDoc.exists) {
        final prevCategoryData = prevCategoryDoc.data() as Map<String, dynamic>;

        double totalAmount = double.parse(prevCategoryData['total_amount']) -
            double.parse(widget.transaction!.amount);

        //* Update the category document
        await prevCategoryRef.update({
          'total_amount': totalAmount.toStringAsFixed(2),
          'updated_at': now,
        });
      }
    }

    final newCategoryRef = cyclesRef.collection('categories').doc(categoryId);

    //* Fetch the category document
    final newCategoryDoc = await newCategoryRef.get();

    if (newCategoryDoc.exists) {
      final newCategoryData = newCategoryDoc.data() as Map<String, dynamic>;

      double totalAmount =
          double.parse(newCategoryData['total_amount']) + double.parse(amount);

      //* Update the category document
      await newCategoryRef.update({
        'total_amount': totalAmount.toStringAsFixed(2),
        'updated_at': now,
      });
    }
  }

  Future<void> _checkFileSize(dynamic file, int fileSize) async {
    if (fileSize <= 5 * 1024 * 1024) {
      setState(() {
        files = [...files, file];
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('File Size Limit Exceeded'),
            content: Text(
                'The file ${file.name} exceeds 5MB and cannot be uploaded.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adMobService.interstitialTransactionFormAdUnitId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );

      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }
}
